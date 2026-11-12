/**
 * Creates (or promotes) an admin account. Use this on production instead of the seed.
 *   npm run admin:create:production -- --email you@company.com --password 'long-password' --name "First Last"
 */
import * as bcrypt from 'bcryptjs';
import { eq } from 'drizzle-orm';
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { users } from '../src/db/schema';

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(`--${name}`);
  return i > -1 ? process.argv[i + 1] : undefined;
}

async function main() {
  const email = arg('email')?.trim().toLowerCase();
  const password = arg('password');
  const [firstName = 'Admin', lastName = 'User'] = (arg('name') ?? 'Admin User').split(' ');
  const role = (arg('role') ?? 'admin') as 'admin' | 'staff';
  if (!email || !password) throw new Error('Usage: --email you@company.com --password "..." [--name "First Last"] [--role admin|staff]');
  if (password.length < 10) throw new Error('Use at least 10 characters for an admin password.');

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const db = drizzle(pool);
  const passwordHash = await bcrypt.hash(password, 10);
  const [existing] = await db.select().from(users).where(eq(users.email, email));
  if (existing) {
    await db.update(users).set({ role, passwordHash, emailVerified: true, status: 'active' }).where(eq(users.id, existing.id));
    console.log(`Updated ${email} → ${role}.`);
  } else {
    await db.insert(users).values({ email, passwordHash, firstName, lastName, role, emailVerified: true });
    console.log(`Created ${role} ${email}.`);
  }
  await pool.end();
}

main().catch((e) => {
  console.error(e.message ?? e);
  process.exit(1);
});
