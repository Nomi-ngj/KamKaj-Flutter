import { BadRequestException, Body, Controller, Get, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsLatitude, IsLongitude, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';
import { and, asc, eq } from 'drizzle-orm';
import { AuthUser, CurrentUser, OptionalAuth } from '../../common/auth';
import { Database, InjectDb } from '../../db/db.module';
import { rides, services, vehicleTypes } from '../../db/schema';

class RequestRideDto {
  @IsString()
  @IsNotEmpty({ message: 'Choose a vehicle type.' })
  vehicleTypeId: string;

  @IsOptional() @IsLatitude() pickupLat?: number;
  @IsOptional() @IsLongitude() pickupLng?: number;
  @IsOptional() @IsLatitude() dropoffLat?: number;
  @IsOptional() @IsLongitude() dropoffLng?: number;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;
}

@ApiTags('Services')
@ApiBearerAuth()
@Controller()
export class ServicesController {
  constructor(@InjectDb() private readonly db: Database) {}

  @OptionalAuth()
  @Get('services')
  async services() {
    const rows = await this.db
      .select()
      .from(services)
      .where(eq(services.isActive, true))
      .orderBy(asc(services.sortOrder), asc(services.name));
    return rows.map((s) => ({ id: s.id, name: s.name, image: s.image }));
  }

  @OptionalAuth()
  @Get('rides/vehicle-types')
  async vehicleTypes() {
    const rows = await this.db
      .select()
      .from(vehicleTypes)
      .where(eq(vehicleTypes.isActive, true))
      .orderBy(asc(vehicleTypes.sortOrder), asc(vehicleTypes.name));
    return rows.map((v) => ({
      id: v.id,
      name: v.name,
      image: v.image,
      capacity: v.capacity,
      baseFare: v.baseFare,
      perKmFare: v.perKmFare,
    }));
  }

  @Post('rides')
  async requestRide(@CurrentUser() user: AuthUser, @Body() dto: RequestRideDto) {
    const [vehicle] = await this.db
      .select()
      .from(vehicleTypes)
      .where(and(eq(vehicleTypes.id, dto.vehicleTypeId), eq(vehicleTypes.isActive, true)))
      .limit(1);
    if (!vehicle) throw new BadRequestException('This vehicle type is not available right now.');
    const [ride] = await this.db
      .insert(rides)
      .values({
        userId: user.id,
        vehicleTypeId: vehicle.id,
        pickupLat: dto.pickupLat,
        pickupLng: dto.pickupLng,
        dropoffLat: dto.dropoffLat,
        dropoffLng: dto.dropoffLng,
        note: dto.note,
      })
      .returning();
    return { id: ride.id, status: ride.status, vehicleTypeId: vehicle.id, createdAt: ride.createdAt.toISOString() };
  }
}
