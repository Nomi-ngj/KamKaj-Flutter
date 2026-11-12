import { BadRequestException, Injectable } from '@nestjs/common';
import { and, desc, eq, isNotNull } from 'drizzle-orm';
import { Database, InjectDb } from '../../db/db.module';
import { isValidLatLng, LatLng } from '../../db/geo';
import { addresses } from '../../db/schema';
import { SettingsService } from '../settings/settings.service';

export type LocationSource = 'query' | 'defaultAddress' | 'address' | 'cityDefault';

export interface ResolvedLocation extends LatLng {
  source: LocationSource;
  /** Address id when the location came from a saved address. */
  addressId?: string;
}

/**
 * Decides which point the home feed is built around, in this order:
 * 1. `lat` / `lng` sent by the app (selected location or GPS)
 * 2. `addressId` sent by the app
 * 3. the signed-in user's default address (if it has coordinates)
 * 4. any other saved address with coordinates
 * 5. the city default from admin settings (Karachi)
 */
@Injectable()
export class LocationService {
  constructor(
    @InjectDb() private readonly db: Database,
    private readonly settings: SettingsService,
  ) {}

  async resolve(query: { lat?: string; lng?: string; addressId?: string }, userId?: string): Promise<ResolvedLocation> {
    if (query.lat !== undefined || query.lng !== undefined) {
      const lat = Number(query.lat);
      const lng = Number(query.lng);
      if (!isValidLatLng(lat, lng)) throw new BadRequestException('The selected location is not valid.');
      return { lat, lng, source: 'query' };
    }

    if (userId) {
      const where = query.addressId
        ? and(eq(addresses.userId, userId), eq(addresses.id, query.addressId), eq(addresses.isDeleted, false))
        : and(eq(addresses.userId, userId), eq(addresses.isDeleted, false), isNotNull(addresses.latitude));
      const [address] = await this.db
        .select()
        .from(addresses)
        .where(where)
        .orderBy(desc(addresses.isDefault), desc(addresses.updatedAt))
        .limit(1);
      if (address?.latitude != null && address.longitude != null) {
        return {
          lat: address.latitude,
          lng: address.longitude,
          source: address.isDefault ? 'defaultAddress' : 'address',
          addressId: address.id,
        };
      }
    }

    const s = await this.settings.get();
    return { lat: s.defaultLatitude, lng: s.defaultLongitude, source: 'cityDefault' };
  }
}
