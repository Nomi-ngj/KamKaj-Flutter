import { Body, Controller, Delete, Get, HttpCode, Injectable, Param, Post, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsIn, IsLatitude, IsLongitude, IsNotEmpty, IsOptional, IsString, MaxLength, ValidateIf } from 'class-validator';
import { and, asc, desc, eq } from 'drizzle-orm';
import { AuthUser, CurrentUser } from '../../common/auth';
import { orNotFound } from '../../common/util';
import { Database, InjectDb } from '../../db/db.module';
import { addresses } from '../../db/schema';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);
const ADDRESS_TYPES = ['home', 'work', 'other'] as const;
type AddressRow = typeof addresses.$inferSelect;

export class AddressDto {
  @IsIn(ADDRESS_TYPES, { message: 'Choose Home, Work or Other.' })
  type: (typeof ADDRESS_TYPES)[number];

  @Transform(trim)
  @IsString()
  @IsNotEmpty({ message: 'Street address is required.' })
  @MaxLength(200)
  street: string;

  @Transform(trim)
  @IsString()
  @IsNotEmpty({ message: 'City is required.' })
  @MaxLength(100)
  city: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(100)
  apartment?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(300)
  driverNotes?: string;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(60)
  label?: string;

  /** Optional pin. Send both or neither. */
  @ValidateIf((o: AddressDto) => o.longitude !== undefined)
  @IsLatitude({ message: 'The pinned location is not valid.' })
  latitude?: number;

  @ValidateIf((o: AddressDto) => o.latitude !== undefined)
  @IsLongitude({ message: 'The pinned location is not valid.' })
  longitude?: number;
}

/** Matches `AddressMapper.fromJson` in the app. */
export function addressJson(a: AddressRow) {
  return {
    id: a.id,
    type: a.type,
    label: a.label,
    street: a.street,
    city: a.city,
    apartment: a.apartment,
    driverNotes: a.driverNotes,
    isDefault: a.isDefault,
    latitude: a.latitude,
    longitude: a.longitude,
  };
}

function defaultLabel(type: AddressDto['type']) {
  return type === 'home' ? 'My Home' : type === 'work' ? 'My Work' : 'Other';
}

@Injectable()
export class AddressesService {
  constructor(@InjectDb() private readonly db: Database) {}

  async list(userId: string) {
    const rows = await this.db
      .select()
      .from(addresses)
      .where(and(eq(addresses.userId, userId), eq(addresses.isDeleted, false)))
      .orderBy(desc(addresses.isDefault), asc(addresses.createdAt));
    return rows.map(addressJson);
  }

  async create(userId: string, dto: AddressDto) {
    const existing = await this.list(userId);
    const [row] = await this.db
      .insert(addresses)
      .values({ ...this.values(dto), userId, isDefault: existing.length === 0 })
      .returning();
    return addressJson(row);
  }

  async update(userId: string, id: string, dto: AddressDto) {
    await this.own(userId, id);
    const [row] = await this.db.update(addresses).set(this.values(dto)).where(eq(addresses.id, id)).returning();
    return addressJson(row);
  }

  async setDefault(userId: string, id: string) {
    await this.own(userId, id);
    await this.db.transaction(async (tx) => {
      await tx.update(addresses).set({ isDefault: false }).where(eq(addresses.userId, userId));
      await tx.update(addresses).set({ isDefault: true }).where(eq(addresses.id, id));
    });
  }

  /** Soft delete so past orders keep their link. The next address becomes default. */
  async remove(userId: string, id: string) {
    const address = await this.own(userId, id);
    await this.db.update(addresses).set({ isDeleted: true, isDefault: false }).where(eq(addresses.id, id));
    if (address.isDefault) {
      const [next] = await this.list(userId);
      if (next) await this.db.update(addresses).set({ isDefault: true }).where(eq(addresses.id, next.id));
    }
  }

  async own(userId: string, id: string) {
    const [row] = await this.db
      .select()
      .from(addresses)
      .where(and(eq(addresses.id, id), eq(addresses.userId, userId), eq(addresses.isDeleted, false)))
      .limit(1);
    return orNotFound(row, 'address');
  }

  private values(dto: AddressDto) {
    return {
      type: dto.type,
      label: dto.label || defaultLabel(dto.type),
      street: dto.street,
      city: dto.city,
      apartment: dto.apartment || null,
      driverNotes: dto.driverNotes || null,
      latitude: dto.latitude ?? null,
      longitude: dto.longitude ?? null,
    };
  }
}

@ApiTags('Addresses')
@ApiBearerAuth()
@Controller('addresses')
export class AddressesController {
  constructor(private readonly service: AddressesService) {}

  @Get()
  list(@CurrentUser() user: AuthUser) {
    return this.service.list(user.id);
  }

  @Post()
  create(@CurrentUser() user: AuthUser, @Body() dto: AddressDto) {
    return this.service.create(user.id, dto);
  }

  @Put(':id')
  update(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: AddressDto) {
    return this.service.update(user.id, id, dto);
  }

  @Post(':id/default')
  @HttpCode(204)
  async setDefault(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    await this.service.setDefault(user.id, id);
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    await this.service.remove(user.id, id);
  }
}
