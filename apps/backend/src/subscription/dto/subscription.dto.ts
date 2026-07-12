import { IsUUID } from 'class-validator';

export class SubscriptionCheckoutDto {
  @IsUUID()
  planId!: string;
}
