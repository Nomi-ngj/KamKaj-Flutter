import { Body, Controller, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiQuery, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { and, desc, eq } from 'drizzle-orm';
import { AuthUser, CurrentUser } from '../../common/auth';
import { Database, InjectDb } from '../../db/db.module';
import { paymentMethods } from '../../db/schema';
import { OrdersService } from './orders.service';

class OrderItemDto {
  @IsString()
  @IsNotEmpty()
  productId: string;

  @IsInt({ message: 'Choose a quantity between 1 and 50.' })
  @Min(1, { message: 'Choose a quantity between 1 and 50.' })
  @Max(50, { message: 'Choose a quantity between 1 and 50.' })
  quantity: number;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  note?: string;
}

export class PlaceOrderDto {
  @IsString()
  @IsNotEmpty()
  storeId: string;

  @IsString()
  @IsNotEmpty({ message: 'Choose a delivery address.' })
  addressId: string;

  @IsString()
  @IsNotEmpty({ message: 'Choose a payment method.' })
  paymentMethodId: string;

  @IsArray()
  @ArrayMinSize(1, { message: 'Your cart is empty.' })
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];
}

class CancelDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  reason?: string;
}

@ApiTags('Orders')
@ApiBearerAuth()
@Controller('orders')
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Get()
  @ApiQuery({ name: 'scope', enum: ['current', 'past'], required: false })
  list(@CurrentUser() user: AuthUser, @Query('scope') scope?: string) {
    return this.orders.list(user.id, scope === 'past' ? 'past' : 'current');
  }

  @Get(':id')
  detail(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.orders.detail(user.id, id);
  }

  @Post()
  place(@CurrentUser() user: AuthUser, @Body() dto: PlaceOrderDto) {
    return this.orders.place(user.id, dto);
  }

  @Post(':id/pay')
  @HttpCode(200)
  pay(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.orders.pay(user.id, id);
  }

  @Post(':id/reorder')
  @HttpCode(200)
  reorder(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.orders.reorder(user.id, id);
  }

  @Post(':id/cancel')
  @HttpCode(200)
  cancel(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: CancelDto) {
    return this.orders.cancel(user.id, id, dto?.reason);
  }
}

@ApiTags('Payments')
@ApiBearerAuth()
@Controller('payment-methods')
export class PaymentMethodsController {
  constructor(@InjectDb() private readonly db: Database) {}

  /** Matches `PaymentMethod` in the app. Adding cards waits for a payment provider. */
  @Get()
  async list(@CurrentUser() user: AuthUser) {
    const rows = await this.db
      .select()
      .from(paymentMethods)
      .where(and(eq(paymentMethods.userId, user.id), eq(paymentMethods.isDeleted, false)))
      .orderBy(desc(paymentMethods.isDefault), paymentMethods.createdAt);
    return rows.map((p) => ({
      id: p.id,
      type: p.type,
      brand: p.brand,
      last4: p.last4,
      expiry: p.expiry,
      isDefault: p.isDefault,
    }));
  }
}
