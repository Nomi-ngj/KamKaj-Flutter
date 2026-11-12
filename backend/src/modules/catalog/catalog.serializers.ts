import { categories, products, stores } from '../../db/schema';
import { isOpenNow, round1, to12h } from '../../common/util';

type CategoryRow = typeof categories.$inferSelect;
type StoreRow = typeof stores.$inferSelect;
type ProductRow = typeof products.$inferSelect;

/** Matches `CatalogMapper.category` in the app. */
export function categoryJson(c: CategoryRow) {
  return { id: c.id, name: c.name, subtitle: c.subtitle, icon: c.icon, tint: c.tint, featured: c.featured };
}

/** Matches `CatalogMapper.store` in the app, plus location fields the app can use later. */
export function storeJson(s: StoreRow, extra: { categoryIds: string[]; distanceKm?: number | null; sections?: string[] }) {
  const open = isOpenNow(s.opensAt, s.closesAt);
  return {
    id: s.id,
    name: s.name,
    category: s.categoryLabel,
    address: s.address,
    rating: s.rating,
    deliveryTime: s.deliveryTime,
    deliveryFee: s.deliveryFee,
    imageUrl: s.imageUrl,
    openUntil: open ? to12h(s.closesAt) : null,
    isOpen: open,
    opensAt: to12h(s.opensAt),
    menuSections: s.menuSections.length ? s.menuSections : (extra.sections ?? []),
    tagline: s.tagline,
    categoryIds: extra.categoryIds,
    distanceKm: extra.distanceKm == null ? null : round1(extra.distanceKm),
    latitude: s.latitude,
    longitude: s.longitude,
    deliveryRadiusKm: s.deliveryRadiusKm,
  };
}

/** Matches `CatalogMapper.product` in the app. */
export function productJson(p: ProductRow, storeName: string) {
  return {
    id: p.id,
    storeId: p.storeId,
    storeName,
    name: p.name,
    description: p.description,
    shortDescription: p.shortDescription,
    price: p.price,
    section: p.section,
    unit: p.unit,
    imageUrl: p.imageUrl,
    isAvailable: p.isAvailable,
  };
}
