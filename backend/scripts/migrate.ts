/** Applies pending SQL migrations from ./drizzle to DATABASE_URL. Safe to run repeatedly. */
import { drizzle } from 'drizzle-orm/node-postgres';
import { migrate } from 'drizzle-orm/node-postgres/migrator';
import { Pool } from 'pg';

async function main() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error('DATABASE_URL is not set.');
  const pool = new Pool({ connectionString: url });
  console.log(`Migrating ${process.env.APP_ENV ?? 'unknown'} database…`);
  await migrate(drizzle(pool), { migrationsFolder: 'drizzle' });
  await pool.end();
  console.log('Migrations up to date.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
