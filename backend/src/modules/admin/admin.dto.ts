import { PartialType } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { categoryTint, orderStatus, rideStatus, userRole, userStatus } from '../../db/schema';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);
const emptyToNull = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? (value.trim() === '' ? null : value.trim()) : value;
const HHMM = /^([01]\d|2[0-3]):[0-5]\d$/;

export class CategoryDto {
  @Transform(trim) @IsString() @IsNotEmpty() @MaxLength(60) name: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(60) subtitle?: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(40) icon?: string;
  @IsOptional() @IsIn(categoryTint.enumValues) tint?: (typeof categoryTint.enumValues)[number];
  @IsOptional() @IsBoolean() featured?: boolean;
  @IsOptional() @IsInt() sortOrder?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
  /** Optional readable id such as "grocery" (create only). */
  @IsOptional() @Matches(/^[a-z0-9_]{2,40}$/, { message: 'Id may only use a-z, 0-9 and _.' }) id?: string;
}
export class UpdateCategoryDto extends PartialType(CategoryDto) {}

export class StoreDto {
  @Transform(trim) @IsString() @IsNotEmpty({ message: 'Store name is required.' }) @MaxLength(100) name: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(60) categoryLabel?: string;
  @IsOptional() @Transform(emptyToNull) @IsString() @MaxLength(60) tagline?: string | null;
  @Transform(trim) @IsString() @IsNotEmpty({ message: 'Address is required.' }) @MaxLength(200) address: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(60) city?: string;
  @Type(() => Number) @IsLatitude({ message: 'Latitude must be between -90 and 90.' }) latitude: number;
  @Type(() => Number) @IsLongitude({ message: 'Longitude must be between -180 and 180.' }) longitude: number;
  @IsOptional() @Type(() => Number) @IsNumber() @Min(0.5) @Max(50) deliveryRadiusKm?: number;
  @IsOptional() @Type(() => Number) @IsNumber() @Min(0) @Max(5) rating?: number;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(30) deliveryTime?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) deliveryFee?: number;
  @IsOptional() @Transform(emptyToNull) @IsString() imageUrl?: string | null;
  @IsOptional() @Transform(emptyToNull) @Matches(HHMM, { message: 'Use 24-hour time like 09:00.' }) opensAt?: string | null;
  @IsOptional() @Transform(emptyToNull) @Matches(HHMM, { message: 'Use 24-hour time like 21:00.' }) closesAt?: string | null;
  @IsOptional() @IsArray() @ArrayMaxSize(30) @IsString({ each: true }) menuSections?: string[];
  @IsOptional() @IsBoolean() isFeatured?: boolean;
  @IsOptional() @IsBoolean() isActive?: boolean;
  @IsOptional() @IsArray() @IsString({ each: true }) categoryIds?: string[];
}
export class UpdateStoreDto extends PartialType(StoreDto) {}

export class ProductDto {
  @IsString() @IsNotEmpty({ message: 'Choose a store.' }) storeId: string;
  @Transform(trim) @IsString() @IsNotEmpty({ message: 'Product name is required.' }) @MaxLength(100) name: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(1000) description?: string;
  @IsOptional() @Transform(emptyToNull) @IsString() @MaxLength(80) shortDescription?: string | null;
  @Type(() => Number) @IsInt({ message: 'Price must be a whole number of paisa.' }) @Min(0) price: number;
  @IsOptional() @Transform(emptyToNull) @IsString() @MaxLength(40) section?: string | null;
  @IsOptional() @Transform(emptyToNull) @IsString() @MaxLength(20) unit?: string | null;
  @IsOptional() @Transform(emptyToNull) @IsString() imageUrl?: string | null;
  @IsOptional() @IsBoolean() isDailyPick?: boolean;
  @IsOptional() @IsBoolean() isAvailable?: boolean;
  @IsOptional() @IsInt() sortOrder?: number;
}
export class UpdateProductDto extends PartialType(ProductDto) {}

export class UpdateUserDto {
  @IsOptional() @Transform(trim) @IsString() @IsNotEmpty() @MaxLength(60) firstName?: string;
  @IsOptional() @Transform(trim) @IsString() @IsNotEmpty() @MaxLength(60) lastName?: string;
  @IsOptional() @IsIn(userStatus.enumValues) status?: (typeof userStatus.enumValues)[number];
  @IsOptional() @IsIn(userRole.enumValues) role?: (typeof userRole.enumValues)[number];
  @IsOptional() @IsBoolean() emailVerified?: boolean;
  @IsOptional() @Transform(emptyToNull) @IsString() @MaxLength(30) phone?: string | null;
}

export class AddPaymentMethodDto {
  @IsIn(['card', 'cash']) type: 'card' | 'cash';
  @Transform(trim) @IsString() @IsNotEmpty() @MaxLength(30) brand: string;
  @IsOptional() @Matches(/^\d{4}$/, { message: 'Last 4 must be 4 digits.' }) last4?: string;
  @IsOptional() @Matches(/^(0[1-9]|1[0-2])\/\d{2}$/, { message: 'Expiry must look like 12/29.' }) expiry?: string;
  @IsOptional() @IsBoolean() isDefault?: boolean;
}

export class UpdateOrderStatusDto {
  @IsIn(orderStatus.enumValues) status: (typeof orderStatus.enumValues)[number];
  @IsOptional() @Transform(emptyToNull) @IsString() @MaxLength(200) note?: string | null;
  @IsOptional() @Transform(emptyToNull) @IsString() @MaxLength(200) cancelReason?: string | null;
  @IsOptional() @Transform(emptyToNull) @IsString() @MaxLength(80) courierName?: string | null;
  @IsOptional() @Transform(emptyToNull) @IsString() @MaxLength(120) courierInfo?: string | null;
}

export class ServiceDto {
  @Transform(trim) @IsString() @IsNotEmpty() @MaxLength(60) name: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(200) image?: string;
  @IsOptional() @IsInt() sortOrder?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
  @IsOptional() @Matches(/^[a-z0-9_]{2,40}$/, { message: 'Id may only use a-z, 0-9 and _.' }) id?: string;
}
export class UpdateServiceDto extends PartialType(ServiceDto) {}

export class VehicleTypeDto {
  @Transform(trim) @IsString() @IsNotEmpty() @MaxLength(60) name: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(200) image?: string;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(60) capacity?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) baseFare?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) perKmFare?: number;
  @IsOptional() @IsInt() sortOrder?: number;
  @IsOptional() @IsBoolean() isActive?: boolean;
  @IsOptional() @Matches(/^[a-z0-9_]{2,40}$/, { message: 'Id may only use a-z, 0-9 and _.' }) id?: string;
}
export class UpdateVehicleTypeDto extends PartialType(VehicleTypeDto) {}

export class UpdateRideDto {
  @IsIn(rideStatus.enumValues) status: (typeof rideStatus.enumValues)[number];
}

export class SettingsDto {
  @IsOptional() @Type(() => Number) @IsNumber() @Min(0.5) @Max(100) searchRadiusKm?: number;
  @IsOptional() @Type(() => Number) @IsLatitude() defaultLatitude?: number;
  @IsOptional() @Type(() => Number) @IsLongitude() defaultLongitude?: number;
  @IsOptional() @Transform(trim) @IsString() @MaxLength(60) defaultCityName?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) freeDeliveryThreshold?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) serviceFee?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(50) nearbyLimit?: number;
  @IsOptional() @Transform(emptyToNull) @IsString() @MaxLength(30) supportPhone?: string | null;
}
