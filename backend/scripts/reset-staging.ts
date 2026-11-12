/** STAGING ONLY: wipes the staging database (all tables and migration history). */
import { Pool } from 'pg';

async function main() {
  if (process.env.APP_ENV !== 'staging') {
    throw new Error(`Refusing to reset: APP_ENV is "${process.env.APP_ENV}". This only runs on staging.`);
  }
  const url = process.env.DATABASE_URL ?? '';
  if (/prod/i.test(new URL(url).pathname)) throw new Error('Refusing to reset a database whose name contains "prod".');
  const pool = new Pool({ connectionString: url });
  await pool.query('DROP SCHEMA IF EXISTS public CASCADE; DROP SCHEMA IF EXISTS drizzle CASCADE; CREATE SCHEMA public;');
  await pool.end();
  console.log('Staging database wiped.');
}

main().catch((e) => {
  console.error(e.message ?? e);
  process.exit(1);
});
