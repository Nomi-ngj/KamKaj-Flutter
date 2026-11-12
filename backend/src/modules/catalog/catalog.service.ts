import { Injectable } from '@nestjs/common';
import { and, asc, eq, inArray, sql, SQL } from 'drizzle-orm';
import { orNotFound } from '../../common/util';
import { Database, InjectDb } from '../../db/db.module';
import { distanceKm, LatLng, storeBoundingBoxSql, storeDistanceSql } from '../../db/geo';
import { categories, products, storeCategories, stores } from '../../db/schema';
import { SettingsService } from '../settings/settings.service';
import { categoryJson, productJson, storeJson } from './catalog.serializers';

type StoreRow = typeof stores.$inferSelect;

@Injectable()
export class CatalogService {
  constructor(
    @InjectDb() private readonly db: Database,
    private readonly settings: SettingsService,
  ) {}

  async categories() {
    const rows = await this.db
      .select()
      .from(categories)
      .where(eq(categories.isActive, true))
      .orderBy(asc(categories.sortOrder), asc(categories.name));
    return rows.map(categoryJson);
  }

  /**
   * Active stores that deliver to `point`: within the store's own delivery radius
   * AND within the global search radius from settings. Sorted by distance.
   */
  async storesInRange(point: LatLng, opts: { featuredOnly?: boolean; categoryId?: string; limit?: number } = {}) {
    const { searchRadiusKm } = await this.settings.get();
    const distance = storeDistanceSql(point);
    const conditions: SQL[] = [
      eq(stores.isActive, true),
      storeBoundingBoxSql(point, searchRadiusKm),
      sql`${distance} <= least(${stores.deliveryRadiusKm}, ${searchRadiusKm})`,
    ];
    if (opts.featuredOnly) conditions.push(eq(stores.isFeatured, true));
    if (opts.categoryId) {
      conditions.push(
        inArray(
          stores.id,
          this.db
            .select({ id: storeCategories.storeId })
            .from(storeCategories)
            .where(eq(storeCategories.categoryId, opts.categoryId)),
        ),
      );
    }

    let query = this.db
      .select({ store: stores, distanceKm: distance })
      .from(stores)
      .where(and(...conditions))
      .orderBy(asc(distance))
      .$dynamic();
    if (opts.limit) query = query.limit(opts.limit);
    const rows = await query;
    return this.withCategories(rows.map((r) => ({ store: r.store, distanceKm: Number(r.distanceKm) })));
  }

  async nearby(point: LatLng) {
    const { nearbyLimit } = await this.settings.get();
    return this.storesInRange(point, { limit: nearbyLimit });
  }

  featured(point: LatLng) {
    return this.storesInRange(point, { featuredOnly: true });
  }

  byCategory(categoryId: string, point: LatLng) {
    return this.storesInRange(point, { categoryId });
  }

  async dailyPicks(point: LatLng) {
    const inRange = await this.storesInRange(point);
    if (!inRange.length) return [];
    const names = new Map(inRange.map((s) => [s.id, s.name]));
    const rows = await this.db
      .select()
      .from(products)
      .where(
        and(
          eq(products.isDailyPick, true),
          eq(products.isAvailable, true),
          inArray(products.storeId, [...names.keys()]),
        ),
      )
      .orderBy(asc(products.sortOrder), asc(products.name))
      .limit(20);
    return rows.map((p) => productJson(p, names.get(p.storeId) ?? ''));
  }

  async store(id: string, point?: LatLng) {
    const [row] = await this.db
      .select()
      .from(stores)
      .where(and(eq(stores.id, id), eq(stores.isActive, true)))
      .limit(1);
    const store = orNotFound(row, 'store');
    const [json] = await this.withCategories([
      { store, distanceKm: point ? distanceKm(point, { lat: store.latitude, lng: store.longitude }) : null },
    ]);
    return json;
  }

  async storeProducts(storeId: string) {
    const store = await this.store(storeId);
    const rows = await this.db
      .select()
      .from(products)
      .where(eq(products.storeId, storeId))
      .orderBy(asc(products.section), asc(products.sortOrder), asc(products.name));
    return rows.map((p) => productJson(p, store.name));
  }

  async product(id: string) {
    const [row] = await this.db
      .select({ product: products, storeName: stores.name })
      .from(products)
      .innerJoin(stores, eq(stores.id, products.storeId))
      .where(and(eq(products.id, id), eq(stores.isActive, true)))
      .limit(1);
    const found = orNotFound(row, 'product');
    return productJson(found.product, found.storeName);
  }

  private async withCategories(rows: { store: StoreRow; distanceKm: number | null }[]) {
    if (!rows.length) return [];
    const ids = rows.map((r) => r.store.id);
    const [links, sectionRows] = await Promise.all([
      this.db.select().from(storeCategories).where(inArray(storeCategories.storeId, ids)),
      this.db
        .selectDistinct({ storeId: products.storeId, section: products.section })
        .from(products)
        .where(inArray(products.storeId, ids)),
    ]);
    const cats = new Map<string, string[]>();
    for (const l of links) cats.set(l.storeId, [...(cats.get(l.storeId) ?? []), l.categoryId]);
    const sections = new Map<string, string[]>();
    for (const s of sectionRows) {
      if (s.section) sections.set(s.storeId, [...(sections.get(s.storeId) ?? []), s.section]);
    }
    return rows.map((r) =>
      storeJson(r.store, {
        categoryIds: cats.get(r.store.id) ?? [],
        distanceKm: r.distanceKm,
        sections: sections.get(r.store.id),
      }),
    );
  }
}
