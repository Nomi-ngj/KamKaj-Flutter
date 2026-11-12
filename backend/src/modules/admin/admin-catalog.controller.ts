import { BadRequestException, Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { and, asc, count, eq, ilike, inArray, or, SQL } from 'drizzle-orm';
import { Roles } from '../../common/auth';
import { orNotFound, pageParams } from '../../common/util';
import { Database, InjectDb } from '../../db/db.module';
import { categories, orders, products, storeCategories, stores } from '../../db/schema';
import { CategoryDto, ProductDto, StoreDto, UpdateCategoryDto, UpdateProductDto, UpdateStoreDto } from './admin.dto';

const isUniqueViolation = (e: unknown) => {
  const err = e as { code?: string; cause?: { code?: string } };
  return err?.code === '23505' || err?.cause?.code === '23505';
};

@ApiTags('Admin · Catalog')
@ApiBearerAuth()
@Roles('admin', 'staff')
@Controller('admin')
export class AdminCatalogController {
  constructor(@InjectDb() private readonly db: Database) {}

  // ───────── Categories ─────────

  @Get('categories')
  async categories() {
    const rows = await this.db
      .select({ category: categories, storeCount: count(storeCategories.storeId) })
      .from(categories)
      .leftJoin(storeCategories, eq(storeCategories.categoryId, categories.id))
      .groupBy(categories.id)
      .orderBy(asc(categories.sortOrder), asc(categories.name));
    return rows.map((r) => ({ ...r.category, storeCount: Number(r.storeCount) }));
  }

  @Post('categories')
  async createCategory(@Body() dto: CategoryDto) {
    try {
      const [row] = await this.db.insert(categories).values(dto).returning();
      return row;
    } catch (e) {
      if (isUniqueViolation(e)) throw new BadRequestException('A category with this id already exists.');
      throw e;
    }
  }

  @Patch('categories/:id')
  async updateCategory(@Param('id') id: string, @Body() dto: UpdateCategoryDto) {
    const { id: _ignored, ...patch } = dto;
    const [row] = await this.db.update(categories).set(patch).where(eq(categories.id, id)).returning();
    return orNotFound(row, 'category');
  }

  @Delete('categories/:id')
  @HttpCode(204)
  async deleteCategory(@Param('id') id: string) {
    const [row] = await this.db.delete(categories).where(eq(categories.id, id)).returning();
    orNotFound(row, 'category');
  }

  // ───────── Stores ─────────

  @Get('stores')
  async stores(@Query() q: { search?: string; active?: string; categoryId?: string; page?: string; pageSize?: string }) {
    const { page, pageSize, offset } = pageParams(q.page, q.pageSize);
    const where: SQL[] = [];
    if (q.search) where.push(or(ilike(stores.name, `%${q.search}%`), ilike(stores.address, `%${q.search}%`))!);
    if (q.active === 'true' || q.active === 'false') where.push(eq(stores.isActive, q.active === 'true'));
    if (q.categoryId) {
      where.push(
        inArray(
          stores.id,
          this.db.select({ id: storeCategories.storeId }).from(storeCategories).where(eq(storeCategories.categoryId, q.categoryId)),
        ),
      );
    }
    const condition = where.length ? and(...where) : undefined;
    const [rows, [{ total }]] = await Promise.all([
      this.db.select().from(stores).where(condition).orderBy(asc(stores.name)).limit(pageSize).offset(offset),
      this.db.select({ total: count() }).from(stores).where(condition),
    ]);
    return { data: await this.withStoreExtras(rows), total: Number(total), page, pageSize };
  }

  @Get('stores/:id')
  async store(@Param('id') id: string) {
    const [row] = await this.db.select().from(stores).where(eq(stores.id, id)).limit(1);
    const [json] = await this.withStoreExtras([orNotFound(row, 'store')]);
    return json;
  }

  @Post('stores')
  async createStore(@Body() dto: StoreDto) {
    const { categoryIds, ...values } = dto;
    const id = await this.db.transaction(async (tx) => {
      const [row] = await tx.insert(stores).values(values).returning();
      if (categoryIds?.length) {
        await tx.insert(storeCategories).values(categoryIds.map((categoryId) => ({ storeId: row.id, categoryId })));
      }
      return row.id;
    });
    return this.store(id);
  }

  @Patch('stores/:id')
  async updateStore(@Param('id') id: string, @Body() dto: UpdateStoreDto) {
    const { categoryIds, ...patch } = dto;
    await this.db.transaction(async (tx) => {
      if (Object.keys(patch).length) {
        const [row] = await tx.update(stores).set(patch).where(eq(stores.id, id)).returning();
        orNotFound(row, 'store');
      }
      if (categoryIds) {
        await tx.delete(storeCategories).where(eq(storeCategories.storeId, id));
        if (categoryIds.length) {
          await tx.insert(storeCategories).values(categoryIds.map((categoryId) => ({ storeId: id, categoryId })));
        }
      }
    });
    return this.store(id);
  }

  /** Stores with orders can't be deleted (history would break) — deactivate them instead. */
  @Delete('stores/:id')
  @HttpCode(204)
  async deleteStore(@Param('id') id: string) {
    const [{ n }] = await this.db.select({ n: count() }).from(orders).where(eq(orders.storeId, id));
    if (Number(n) > 0) {
      throw new BadRequestException('This store has orders, so it can’t be deleted. Turn off “Active” instead.');
    }
    const [row] = await this.db.delete(stores).where(eq(stores.id, id)).returning();
    orNotFound(row, 'store');
  }

  // ───────── Products ─────────

  @Get('products')
  async products(@Query() q: { storeId?: string; search?: string; page?: string; pageSize?: string }) {
    const { page, pageSize, offset } = pageParams(q.page, q.pageSize);
    const where: SQL[] = [];
    if (q.storeId) where.push(eq(products.storeId, q.storeId));
    if (q.search) where.push(ilike(products.name, `%${q.search}%`));
    const condition = where.length ? and(...where) : undefined;
    const [rows, [{ total }]] = await Promise.all([
      this.db
        .select({ product: products, storeName: stores.name })
        .from(products)
        .innerJoin(stores, eq(stores.id, products.storeId))
        .where(condition)
        .orderBy(asc(stores.name), asc(products.section), asc(products.sortOrder), asc(products.name))
        .limit(pageSize)
        .offset(offset),
      this.db.select({ total: count() }).from(products).where(condition),
    ]);
    return {
      data: rows.map((r) => ({ ...r.product, storeName: r.storeName })),
      total: Number(total),
      page,
      pageSize,
    };
  }

  @Get('products/:id')
  async product(@Param('id') id: string) {
    const [row] = await this.db.select().from(products).where(eq(products.id, id)).limit(1);
    return orNotFound(row, 'product');
  }

  @Post('products')
  async createProduct(@Body() dto: ProductDto) {
    await this.assertStore(dto.storeId);
    const [row] = await this.db.insert(products).values(dto).returning();
    return row;
  }

  @Patch('products/:id')
  async updateProduct(@Param('id') id: string, @Body() dto: UpdateProductDto) {
    if (dto.storeId) await this.assertStore(dto.storeId);
    const [row] = await this.db.update(products).set(dto).where(eq(products.id, id)).returning();
    return orNotFound(row, 'product');
  }

  @Delete('products/:id')
  @HttpCode(204)
  async deleteProduct(@Param('id') id: string) {
    const [row] = await this.db.delete(products).where(eq(products.id, id)).returning();
    orNotFound(row, 'product');
  }

  // ───────── Helpers ─────────

  private async assertStore(storeId: string) {
    const [s] = await this.db.select({ id: stores.id }).from(stores).where(eq(stores.id, storeId)).limit(1);
    if (!s) throw new BadRequestException('That store does not exist.');
  }

  private async withStoreExtras(rows: (typeof stores.$inferSelect)[]) {
    if (!rows.length) return [];
    const ids = rows.map((r) => r.id);
    const [links, productCounts, orderCounts] = await Promise.all([
      this.db.select().from(storeCategories).where(inArray(storeCategories.storeId, ids)),
      this.db
        .select({ storeId: products.storeId, n: count() })
        .from(products)
        .where(inArray(products.storeId, ids))
        .groupBy(products.storeId),
      this.db
        .select({ storeId: orders.storeId, n: count() })
        .from(orders)
        .where(inArray(orders.storeId, ids))
        .groupBy(orders.storeId),
    ]);
    const cats = new Map<string, string[]>();
    for (const l of links) cats.set(l.storeId, [...(cats.get(l.storeId) ?? []), l.categoryId]);
    const pc = new Map(productCounts.map((p) => [p.storeId, Number(p.n)]));
    const oc = new Map(orderCounts.map((o) => [o.storeId, Number(o.n)]));
    return rows.map((r) => ({
      ...r,
      categoryIds: cats.get(r.id) ?? [],
      productCount: pc.get(r.id) ?? 0,
      orderCount: oc.get(r.id) ?? 0,
    }));
  }
}

