import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { validateEnv } from './config/env.validation';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { TenantModule } from './common/tenant/tenant.module';
import { AdminModule } from './admin/admin.module';
import { SubscriptionModule } from './subscription/subscription.module';
import { SalonModule } from './salon/salon.module';
import { BookingModule } from './booking/booking.module';
import { PaymentModule } from './payments/payment.module';
import { WalletModule } from './wallet/wallet.module';
import { NotificationModule } from './notifications/notification.module';
import { MarketingModule } from './marketing/marketing.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { InventoryModule } from './inventory/inventory.module';
import { ChatModule } from './chat/chat.module';
import { MetricsModule } from './metrics/metrics.module';
import { DiscoveryModule } from './discovery/discovery.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '../../.env',
      validate: validateEnv,
    }),
    ThrottlerModule.forRoot([
      {
        ttl: parseInt(process.env.RATE_LIMIT_TTL ?? '60', 10) * 1000,
        limit: parseInt(process.env.RATE_LIMIT_LIMIT ?? '300', 10),
      },
    ]),
    PrismaModule,
    AuthModule,
    TenantModule,
    AdminModule,
    SubscriptionModule,
    SalonModule,
    BookingModule,
    PaymentModule,
    WalletModule,
    NotificationModule,
    MarketingModule,
    AnalyticsModule,
    InventoryModule,
    ChatModule,
    MetricsModule,
    DiscoveryModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
