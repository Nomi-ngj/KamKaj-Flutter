import { Global, Inject, Module, OnApplicationShutdown } from '@nestjs/common';
import { drizzle, NodePgDatabase } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { env } from '../config/env';
import * as schema from './schema';

export const DB = Symbol('DB');
export const PG_POOL = Symbol('PG_POOL');

export type Database = NodePgDatabase<typeof schema>;

/** Inject the Drizzle database: `constructor(@InjectDb() private readonly db: Database)`. */
export const InjectDb = () => Inject(DB);

export function createPool(url = env().databaseUrl): Pool {
  return new Pool({ connectionString: url, max: 10 });
}

@Global()
@Module({
  providers: [
    { provide: PG_POOL, useFactory: () => createPool() },
    {
      provide: DB,
      inject: [PG_POOL],
      useFactory: (pool: Pool): Database => drizzle(pool, { schema }),
    },
  ],
  exports: [DB],
})
export class DbModule implements OnApplicationShutdown {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async onApplicationShutdown() {
    await this.pool.end();
  }
}
