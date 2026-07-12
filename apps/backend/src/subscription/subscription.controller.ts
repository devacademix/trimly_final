import { Controller, Get, Post, Body, Query, Req, Headers, UseGuards, HttpCode, HttpStatus, RawBodyRequest } from '@nestjs/common';
import type { Request } from 'express';
import { SubscriptionService } from './subscription.service';
import { ApiResponse, UserRole } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { SubscriptionCheckoutDto } from './dto/subscription.dto';

@ApiTags('Subscriptions & Billing')
@Controller('subscription')
export class SubscriptionController {
  constructor(private subService: SubscriptionService) {}

  @Get('plans')
  @ApiOperation({ summary: 'List all subscription billing plans' })
  async getPlans(): Promise<ApiResponse<any>> {
    const plans = await this.subService.getPlans();
    return {
      success: true,
      data: plans,
    };
  }

  @Post('checkout')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create checkout session for purchasing a subscription plan' })
  async checkout(
    @CurrentUser() user: any,
    @Body() dto: SubscriptionCheckoutDto,
  ): Promise<ApiResponse<any>> {
    const session = await this.subService.createCheckout(user.tenantId, dto.planId);
    return {
      success: true,
      data: session,
    };
  }

  @Post('webhook')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Razorpay subscription webhook endpoint' })
  async webhook(
    @Headers('x-razorpay-signature') signature: string,
    @Req() req: RawBodyRequest<Request>,
    @Body() payload: any,
  ): Promise<any> {
    return this.subService.handleWebhook(signature, req.rawBody as Buffer, payload);
  }

  @Get('status')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SALON_OWNER, UserRole.STAFF)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get active subscription limits and usage status' })
  async getStatus(@CurrentUser() user: any): Promise<ApiResponse<any>> {
    const status = await this.subService.getStatus(user.tenantId);
    return {
      success: true,
      data: status,
    };
  }
}
