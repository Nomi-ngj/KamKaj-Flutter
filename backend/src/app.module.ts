import { Controller, Get, Module } from '@nestjs/common';
import { APP_FILTER, APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { sql } from 'drizzle-orm';
import { AuthGuard, Public } from './common/auth';
import { HttpExceptionFilter } from './common/http-exception.filter';
import { env } from './config/env';
import { Database, DbModule, InjectDb } from './db/db.module';
import { AddressesController, AddressesService } from './modules/addresses/addresses';
import { AdminCatalogController } from './modules/admin/admin-catalog.controller';
import { AdminOpsController } from './modules/admin/admin-ops.controller';
import { AuthController, UsersController } from './modules/auth/auth.controller';
import { AuthService } from './modules/auth/auth.service';
import { MailService } from './modules/auth/mail.service';
import { CatalogController } from './modules/catalog/catalog.controller';
import { CatalogService } from './modules/catalog/catalog.service';
import { LocationService } from './modules/catalog/location.service';
import { OrdersController, PaymentMethodsController } from './modules/orders/orders.controller';
import { OrdersService } from './modules/orders/orders.service';
import { ServicesController } from './modules/services/services.controller';
import { SettingsService } from './modules/settings/settings.service';

@Controller()
class HealthController {
  constructor(@InjectDb() private readonly db: Database) {}

  @Public()
  @Get('health')
  async health() {
    await this.db.execute(sql`select 1`);
    return { status: 'ok', env: env().appEnv, time: new Date().toISOString() };
  }
}

@Module({
  imports: [
    DbModule,
    JwtModule.register({}),
    ThrottlerModule.forRoot([{ name: 'default', ttl: 60_000, limit: 300 }]),
  ],
  controllers: [
    HealthController,
    AuthController,
    UsersController,
    CatalogController,
    AddressesController,
    OrdersController,
    PaymentMethodsController,
    ServicesController,
    AdminCatalogController,
    AdminOpsController,
  ],
  providers: [
    SettingsService,
    MailService,
    AuthService,
    LocationService,
    CatalogService,
    AddressesService,
    OrdersService,
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_FILTER, useClass: HttpExceptionFilter },
  ],
})
export class AppModule {}
