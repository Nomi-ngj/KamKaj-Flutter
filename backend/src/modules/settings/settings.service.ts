import { Injectable } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import { Database, InjectDb } from '../../db/db.module';
import { appSettings } from '../../db/schema';

export type AppSettings = typeof appSettings.$inferSelect;
export type AppSettingsUpdate = Partial<Omit<AppSettings, 'id' | 'updatedAt'>>;

/** Global settings (search radius, fees…). Cached for a few seconds; admin edits clear the cache. */
@Injectable()
export class SettingsService {
  private cache: { value: AppSettings; at: number } | null = null;
  private static readonly TTL_MS = 15_000;

  constructor(@InjectDb() private readonly db: Database) {}

  async get(): Promise<AppSettings> {
    if (this.cache && Date.now() - this.cache.at < SettingsService.TTL_MS) return this.cache.value;
    let [row] = await this.db.select().from(appSettings).where(eq(appSettings.id, 'global')).limit(1);
    if (!row) {
      [row] = await this.db.insert(appSettings).values({ id: 'global' }).onConflictDoNothing().returning();
      row ??= (await this.db.select().from(appSettings).where(eq(appSettings.id, 'global')).limit(1))[0];
    }
    this.cache = { value: row, at: Date.now() };
    return row;
  }

  async update(patch: AppSettingsUpdate): Promise<AppSettings> {
    await this.get();
    const [row] = await this.db.update(appSettings).set(patch).where(eq(appSettings.id, 'global')).returning();
    this.cache = { value: row, at: Date.now() };
    return row;
  }
}
