import { sql, SQL } from 'drizzle-orm';
import { stores } from './schema';

export interface LatLng {
  lat: number;
  lng: number;
}

const EARTH_RADIUS_KM = 6371;

/** Great-circle distance in km between two points (haversine). */
export function distanceKm(a: LatLng, b: LatLng): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.min(1, Math.sqrt(h)));
}

/** SQL expression: distance in km from `point` to each store row. */
export function storeDistanceSql(point: LatLng): SQL<number> {
  return sql<number>`(${EARTH_RADIUS_KM} * 2 * asin(least(1, sqrt(
    power(sin(radians(${stores.latitude} - ${point.lat}) / 2), 2) +
    cos(radians(${point.lat})) * cos(radians(${stores.latitude})) *
    power(sin(radians(${stores.longitude} - ${point.lng}) / 2), 2)
  ))))`;
}

/**
 * Cheap bounding-box pre-filter (uses the lat/lng index) so the haversine
 * expression only runs on nearby rows.
 */
export function storeBoundingBoxSql(point: LatLng, radiusKm: number): SQL {
  const latDelta = radiusKm / 111.32;
  const lngDelta = radiusKm / (111.32 * Math.max(0.01, Math.cos((point.lat * Math.PI) / 180)));
  return sql`${stores.latitude} between ${point.lat - latDelta} and ${point.lat + latDelta}
    and ${stores.longitude} between ${point.lng - lngDelta} and ${point.lng + lngDelta}`;
}

export function isValidLatLng(lat: unknown, lng: unknown): boolean {
  return (
    typeof lat === 'number' &&
    typeof lng === 'number' &&
    Number.isFinite(lat) &&
    Number.isFinite(lng) &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180
  );
}
