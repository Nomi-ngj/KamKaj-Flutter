import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiQuery, ApiTags } from '@nestjs/swagger';
import { AuthUser, CurrentUser, OptionalAuth } from '../../common/auth';
import { CatalogService } from './catalog.service';
import { LocationService } from './location.service';

interface LocationQuery {
  lat?: string;
  lng?: string;
  addressId?: string;
}

const locationDocs = [
  ApiQuery({ name: 'lat', required: false, description: 'Selected latitude (with lng)' }),
  ApiQuery({ name: 'lng', required: false, description: 'Selected longitude (with lat)' }),
  ApiQuery({ name: 'addressId', required: false, description: 'Use one of the user’s saved addresses' }),
];
const LocationDocs = (): MethodDecorator => (target, key, descriptor) => {
  for (const d of locationDocs) d(target, key, descriptor);
};

/**
 * Catalog endpoints. All lists are limited to stores that deliver to the selected location
 * (see LocationService for how the location is chosen when the app doesn't send one).
 */
@ApiTags('Catalog')
@ApiBearerAuth()
@OptionalAuth()
@Controller()
export class CatalogController {
  constructor(
    private readonly catalog: CatalogService,
    private readonly location: LocationService,
  ) {}

  /** Everything the home dashboard needs in one call. */
  @Get('home')
  @LocationDocs()
  async home(@Query() q: LocationQuery, @CurrentUser() user?: AuthUser) {
    const point = await this.location.resolve(q, user?.id);
    const [categories, nearbyStores, featuredStores, dailyPicks] = await Promise.all([
      this.catalog.categories(),
      this.catalog.nearby(point),
      this.catalog.featured(point),
      this.catalog.dailyPicks(point),
    ]);
    return {
      location: point,
      isServiceable: nearbyStores.length > 0,
      categories,
      nearbyStores,
      featuredStores,
      dailyPicks,
    };
  }

  @Get('categories')
  categories() {
    return this.catalog.categories();
  }

  @Get('products/daily-picks')
  @LocationDocs()
  async dailyPicks(@Query() q: LocationQuery, @CurrentUser() user?: AuthUser) {
    return this.catalog.dailyPicks(await this.location.resolve(q, user?.id));
  }

  @Get('stores/nearby')
  @LocationDocs()
  async nearby(@Query() q: LocationQuery, @CurrentUser() user?: AuthUser) {
    return this.catalog.nearby(await this.location.resolve(q, user?.id));
  }

  @Get('stores/featured')
  @LocationDocs()
  async featured(@Query() q: LocationQuery, @CurrentUser() user?: AuthUser) {
    return this.catalog.featured(await this.location.resolve(q, user?.id));
  }

  @Get('stores')
  @LocationDocs()
  @ApiQuery({ name: 'category', required: false })
  async stores(@Query() q: LocationQuery & { category?: string }, @CurrentUser() user?: AuthUser) {
    const point = await this.location.resolve(q, user?.id);
    return q.category ? this.catalog.byCategory(q.category, point) : this.catalog.storesInRange(point);
  }

  @Get('stores/:id')
  @LocationDocs()
  async store(@Param('id') id: string, @Query() q: LocationQuery, @CurrentUser() user?: AuthUser) {
    return this.catalog.store(id, await this.location.resolve(q, user?.id));
  }

  @Get('stores/:id/products')
  storeProducts(@Param('id') id: string) {
    return this.catalog.storeProducts(id);
  }

  @Get('products/:id')
  product(@Param('id') id: string) {
    return this.catalog.product(id);
  }
}
