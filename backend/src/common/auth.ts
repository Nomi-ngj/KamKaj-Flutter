import {
  CanActivate,
  createParamDecorator,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  SetMetadata,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { eq } from 'drizzle-orm';
import type { Request } from 'express';
import { env } from '../config/env';
import { Database, InjectDb } from '../db/db.module';
import { users, UserRole } from '../db/schema';

export interface AuthUser {
  id: string;
  email: string;
  role: UserRole;
  firstName: string;
  lastName: string;
}

export interface AccessTokenPayload {
  sub: string;
  role: UserRole;
  typ: 'access';
}

type AuthedRequest = Request & { user?: AuthUser };

const IS_PUBLIC = 'isPublic';
const OPTIONAL_AUTH = 'optionalAuth';
const ROLES = 'roles';

/** No token needed. */
export const Public = () => SetMetadata(IS_PUBLIC, true);
/** Token is read when present (to personalise results) but not required. */
export const OptionalAuth = () => SetMetadata(OPTIONAL_AUTH, true);
/** Only these roles may call the route. */
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES, roles);

export const CurrentUser = createParamDecorator((_: unknown, ctx: ExecutionContext): AuthUser | undefined => {
  return ctx.switchToHttp().getRequest<AuthedRequest>().user;
});

/**
 * Global guard: every route needs a valid access token unless marked @Public() or @OptionalAuth().
 * The user row is re-read on each request so blocking an account takes effect immediately.
 */
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly jwt: JwtService,
    @InjectDb() private readonly db: Database,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const targets = [ctx.getHandler(), ctx.getClass()];
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC, targets);
    const isOptional = this.reflector.getAllAndOverride<boolean>(OPTIONAL_AUTH, targets);
    const roles = this.reflector.getAllAndOverride<UserRole[]>(ROLES, targets);

    const req = ctx.switchToHttp().getRequest<AuthedRequest>();
    const header = req.headers.authorization ?? '';
    const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';

    if (isPublic) return true;
    if (!token) {
      if (isOptional) return true;
      throw new UnauthorizedException('Please sign in to continue.');
    }

    let payload: AccessTokenPayload;
    try {
      payload = await this.jwt.verifyAsync<AccessTokenPayload>(token, { secret: env().jwt.accessSecret });
      if (payload.typ !== 'access') throw new Error('wrong token type');
    } catch {
      // An expired token must return 401 so the app refreshes it, even on optional routes.
      throw new UnauthorizedException('Your session has expired. Please sign in again.');
    }

    const [user] = await this.db
      .select({
        id: users.id,
        email: users.email,
        role: users.role,
        status: users.status,
        firstName: users.firstName,
        lastName: users.lastName,
      })
      .from(users)
      .where(eq(users.id, payload.sub))
      .limit(1);

    if (!user) throw new UnauthorizedException('Your session has expired. Please sign in again.');
    if (user.status === 'blocked') {
      throw new ForbiddenException('This account has been suspended. Please contact support.');
    }
    if (roles?.length && !roles.includes(user.role)) {
      throw new ForbiddenException('You do not have access to this area.');
    }

    req.user = { id: user.id, email: user.email, role: user.role, firstName: user.firstName, lastName: user.lastName };
    return true;
  }
}
