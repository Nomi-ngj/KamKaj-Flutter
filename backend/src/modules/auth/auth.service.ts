import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { createHash, randomBytes, randomInt } from 'node:crypto';
import { and, desc, eq, gt, isNull } from 'drizzle-orm';
import type { AccessTokenPayload } from '../../common/auth';
import { env } from '../../config/env';
import { Database, InjectDb } from '../../db/db.module';
import { refreshTokens, users, verificationCodes } from '../../db/schema';
import { Purpose } from './auth.dto';
import { MailService } from './mail.service';

type UserRow = typeof users.$inferSelect;

const CODE_TTL_MS = 10 * 60 * 1000;
const MAX_CODE_ATTEMPTS = 5;
const RESET_TOKEN_TTL = '15m';
const BCRYPT_ROUNDS = 10;

const sha256 = (value: string) => createHash('sha256').update(value).digest('hex');

/** Public user shape expected by the app (`UserModel.fromJson`). */
export function toUserJson(u: Pick<UserRow, 'id' | 'firstName' | 'lastName' | 'email' | 'emailVerified'>) {
  return { id: u.id, firstName: u.firstName, lastName: u.lastName, email: u.email, emailVerified: u.emailVerified };
}

export const hashPassword = (password: string) => bcrypt.hash(password, BCRYPT_ROUNDS);

@Injectable()
export class AuthService {
  constructor(
    @InjectDb() private readonly db: Database,
    private readonly jwt: JwtService,
    private readonly mail: MailService,
  ) {}

  // ───────── Sign in / sign up ─────────

  async signIn(email: string, password: string, userAgent?: string, allowedRoles?: UserRow['role'][]) {
    const user = await this.findByEmail(email);
    // Same message for unknown email and wrong password, so accounts can't be discovered.
    const ok = user ? await bcrypt.compare(password, user.passwordHash) : await bcrypt.compare(password, DUMMY_HASH);
    if (!user || !ok) throw new BadRequestException('Incorrect email or password.');
    if (user.status === 'blocked') throw new ForbiddenException('This account has been suspended. Please contact support.');
    if (allowedRoles && !allowedRoles.includes(user.role)) {
      throw new ForbiddenException('This account does not have admin access.');
    }
    if (!user.emailVerified) {
      await this.issueCode(user, 'signUp');
      throw new ForbiddenException('Please verify your email first. We have sent you a new code.');
    }
    await this.db.update(users).set({ lastLoginAt: new Date() }).where(eq(users.id, user.id));
    return this.session(user, userAgent);
  }

  async signUp(input: { firstName: string; lastName: string; email: string; password: string }) {
    const existing = await this.findByEmail(input.email);
    if (existing?.emailVerified) throw new ConflictException('An account with this email already exists.');

    const passwordHash = await hashPassword(input.password);
    let user: UserRow;
    if (existing) {
      // Unfinished sign-up: refresh the details and send a new code.
      [user] = await this.db
        .update(users)
        .set({ firstName: input.firstName, lastName: input.lastName, passwordHash })
        .where(eq(users.id, existing.id))
        .returning();
    } else {
      [user] = await this.db
        .insert(users)
        .values({ firstName: input.firstName, lastName: input.lastName, email: input.email, passwordHash })
        .returning();
    }
    await this.issueCode(user, 'signUp');
  }

  // ───────── Verification codes ─────────

  async verifyCode(email: string, code: string, purpose: Purpose, userAgent?: string) {
    const user = await this.findByEmail(email);
    if (!user) throw new BadRequestException('That code is incorrect or has expired.');

    const [record] = await this.db
      .select()
      .from(verificationCodes)
      .where(
        and(
          eq(verificationCodes.userId, user.id),
          eq(verificationCodes.purpose, purpose),
          isNull(verificationCodes.usedAt),
          gt(verificationCodes.expiresAt, new Date()),
        ),
      )
      .orderBy(desc(verificationCodes.createdAt))
      .limit(1);

    if (!record || record.attempts >= MAX_CODE_ATTEMPTS) {
      throw new BadRequestException('That code is incorrect or has expired.');
    }
    if (record.codeHash !== sha256(`${user.id}:${code}`)) {
      await this.db
        .update(verificationCodes)
        .set({ attempts: record.attempts + 1 })
        .where(eq(verificationCodes.id, record.id));
      throw new BadRequestException('That code is incorrect or has expired.');
    }
    await this.db.update(verificationCodes).set({ usedAt: new Date() }).where(eq(verificationCodes.id, record.id));

    if (purpose === 'signUp') {
      const [verified] = await this.db
        .update(users)
        .set({ emailVerified: true, lastLoginAt: new Date() })
        .where(eq(users.id, user.id))
        .returning();
      return this.session(verified, userAgent);
    }

    const resetToken = await this.jwt.signAsync(
      { sub: user.id, typ: 'reset', pwd: sha256(user.passwordHash).slice(0, 16) },
      { secret: env().jwt.refreshSecret, expiresIn: RESET_TOKEN_TTL },
    );
    return { resetToken };
  }

  async resendCode(email: string, purpose: Purpose) {
    const user = await this.findByEmail(email);
    // Always succeed so the API never reveals which emails are registered.
    if (!user) return;
    if (purpose === 'signUp' && user.emailVerified) return;
    await this.issueCode(user, purpose);
  }

  async forgotPassword(email: string) {
    const user = await this.findByEmail(email);
    if (user && user.status === 'active') await this.issueCode(user, 'resetPassword');
  }

  async resetPassword(resetToken: string, password: string) {
    let payload: { sub: string; typ: string; pwd: string };
    try {
      payload = await this.jwt.verifyAsync(resetToken, { secret: env().jwt.refreshSecret });
    } catch {
      throw new BadRequestException('This reset link has expired. Please request a new code.');
    }
    const [user] = payload.typ === 'reset' ? await this.db.select().from(users).where(eq(users.id, payload.sub)).limit(1) : [];
    // `pwd` ties the token to the old password, so it can only be used once.
    if (!user || sha256(user.passwordHash).slice(0, 16) !== payload.pwd) {
      throw new BadRequestException('This reset link has expired. Please request a new code.');
    }
    await this.db.update(users).set({ passwordHash: await hashPassword(password) }).where(eq(users.id, user.id));
    await this.revokeAll(user.id);
  }

  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    const [user] = await this.db.select().from(users).where(eq(users.id, userId)).limit(1);
    if (!user || !(await bcrypt.compare(currentPassword, user.passwordHash))) {
      throw new BadRequestException('Your current password is incorrect.');
    }
    if (currentPassword === newPassword) {
      throw new BadRequestException('Choose a password you have not used before.');
    }
    await this.db.update(users).set({ passwordHash: await hashPassword(newPassword) }).where(eq(users.id, userId));
  }

  // ───────── Tokens ─────────

  async refresh(refreshToken: string, userAgent?: string) {
    const [record] = await this.db
      .select()
      .from(refreshTokens)
      .where(eq(refreshTokens.tokenHash, sha256(refreshToken)))
      .limit(1);

    if (!record || record.expiresAt < new Date()) {
      throw new UnauthorizedException('Your session has expired. Please sign in again.');
    }
    if (record.revokedAt) {
      // A revoked token being reused means it may have been stolen: end every session.
      await this.revokeAll(record.userId);
      throw new UnauthorizedException('Your session has expired. Please sign in again.');
    }
    const [user] = await this.db.select().from(users).where(eq(users.id, record.userId)).limit(1);
    if (!user || user.status === 'blocked') {
      throw new UnauthorizedException('Your session has expired. Please sign in again.');
    }
    await this.db.update(refreshTokens).set({ revokedAt: new Date() }).where(eq(refreshTokens.id, record.id));
    const { accessToken, refreshToken: next } = await this.session(user, userAgent);
    return { accessToken, refreshToken: next };
  }

  async signOut(userId: string, refreshToken?: string) {
    if (refreshToken) {
      await this.db
        .update(refreshTokens)
        .set({ revokedAt: new Date() })
        .where(and(eq(refreshTokens.userId, userId), eq(refreshTokens.tokenHash, sha256(refreshToken))));
      return;
    }
    await this.revokeAll(userId);
  }

  async me(userId: string) {
    const [user] = await this.db.select().from(users).where(eq(users.id, userId)).limit(1);
    if (!user) throw new UnauthorizedException('Your session has expired. Please sign in again.');
    return toUserJson(user);
  }

  // ───────── Helpers ─────────

  private findByEmail(email: string): Promise<UserRow | undefined> {
    return this.db
      .select()
      .from(users)
      .where(eq(users.email, email.trim().toLowerCase()))
      .limit(1)
      .then((rows) => rows[0]);
  }

  private async issueCode(user: UserRow, purpose: Purpose) {
    const code = env().fixedOtp ?? String(randomInt(0, 1_000_000)).padStart(6, '0');
    // Invalidate earlier unused codes for the same purpose.
    await this.db
      .update(verificationCodes)
      .set({ usedAt: new Date() })
      .where(
        and(eq(verificationCodes.userId, user.id), eq(verificationCodes.purpose, purpose), isNull(verificationCodes.usedAt)),
      );
    await this.db.insert(verificationCodes).values({
      userId: user.id,
      purpose,
      codeHash: sha256(`${user.id}:${code}`),
      expiresAt: new Date(Date.now() + CODE_TTL_MS),
    });
    await this.mail.sendVerificationCode(user.email, code, purpose);
  }

  private async session(user: UserRow, userAgent?: string) {
    const payload: AccessTokenPayload = { sub: user.id, role: user.role, typ: 'access' };
    const accessToken = await this.jwt.signAsync(payload, {
      secret: env().jwt.accessSecret,
      expiresIn: env().jwt.accessTtl as unknown as number,
    });
    const refreshToken = randomBytes(48).toString('base64url');
    await this.db.insert(refreshTokens).values({
      userId: user.id,
      tokenHash: sha256(refreshToken),
      expiresAt: new Date(Date.now() + env().jwt.refreshTtlDays * 24 * 60 * 60 * 1000),
      userAgent: userAgent?.slice(0, 200),
    });
    return { accessToken, refreshToken, user: toUserJson(user) };
  }

  private async revokeAll(userId: string) {
    await this.db
      .update(refreshTokens)
      .set({ revokedAt: new Date() })
      .where(and(eq(refreshTokens.userId, userId), isNull(refreshTokens.revokedAt)));
  }
}

/** Compared against when the email is unknown so response time doesn't reveal it. */
const DUMMY_HASH = bcrypt.hashSync('not-a-real-password', BCRYPT_ROUNDS);
