/** Shapes returned by the admin API. */

export interface StoreRow {
  id: string;
  name: string;
  categoryLabel: string;
  tagline: string | null;
  address: string;
  city: string;
  latitude: number;
  longitude: number;
  deliveryRadiusKm: number;
  rating: number;
  deliveryTime: string;
  deliveryFee: number;
  imageUrl: string | null;
  opensAt: string | null;
  closesAt: string | null;
  menuSections: string[];
  isFeatured: boolean;
  isActive: boolean;
  categoryIds: string[];
  productCount: number;
  orderCount: number;
}

export interface ProductRow {
  id: string;
  storeId: string;
  storeName?: string;
  name: string;
  description: string;
  shortDescription: string | null;
  price: number;
  section: string | null;
  unit: string | null;
  imageUrl: string | null;
  isDailyPick: boolean;
  isAvailable: boolean;
  sortOrder: number;
}

export interface CategoryRow {
  id: string;
  name: string;
  subtitle: string;
  icon: string;
  tint: 'red' | 'green' | 'yellow' | 'blue' | 'purple';
  featured: boolean;
  sortOrder: number;
  isActive: boolean;
  storeCount: number;
}
