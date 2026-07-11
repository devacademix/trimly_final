import { Module } from '@nestjs/common';
import { SalonService } from './salon.service';
import { SalonController } from './salon.controller';
import { AuthModule } from '../auth/auth.module';
import { SubscriptionModule } from '../subscription/subscription.module';

@Module({
  imports: [AuthModule, SubscriptionModule],
  controllers: [SalonController],
  providers: [SalonService],
  exports: [SalonService],
})
export class SalonModule {}
