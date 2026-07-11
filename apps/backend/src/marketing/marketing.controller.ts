import { Controller, Get, Post, Body, Query, Param, UseGuards } from '@nestjs/common';
import { MarketingService } from './marketing.service';
import { ApiResponse, UserRole } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { TenantGuard } from '../common/guards/tenant.guard';
import { TenantId } from '../common/decorators/tenant.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Marketing, Coupons & Reviews')
@Controller('marketing')
export class MarketingController {
  constructor(private marketingService: MarketingService) {}

  @Post('coupons')
  @UseGuards(JwtAuthGuard, TenantGuard, RolesGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiBearerAuth()
  @ApiHeader({ name: 'x-tenant-id' })
  @ApiOperation({ summary: 'Create a discount coupon (Flat/Percentage)' })
  async createCoupon(
    @TenantId() tenantId: string,
    @Body() data: any,
  ): Promise<ApiResponse<any>> {
    const coupon = await this.marketingService.createCoupon(tenantId, data);
    return {
      success: true,
      data: coupon,
    };
  }

  @Get('coupons/validate')
  @UseGuards(TenantGuard)
  @ApiHeader({ name: 'x-tenant-id' })
  @ApiOperation({ summary: 'Validate a coupon code and calculate discount' })
  async validateCoupon(
    @TenantId() tenantId: string,
    @Query('code') code: string,
    @Query('amount') amount: number,
  ): Promise<ApiResponse<any>> {
    const res = await this.marketingService.validateCoupon(tenantId, code, Number(amount));
    return {
      success: true,
      data: res,
    };
  }

  @Get('coupons/salon')
  @UseGuards(TenantGuard)
  @ApiHeader({ name: 'x-tenant-id' })
  @ApiOperation({ summary: 'List all active coupons for a salon' })
  async getCoupons(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const coupons = await this.marketingService.getCoupons(tenantId);
    return {
      success: true,
      data: coupons,
    };
  }

  @Post('reviews')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Submit a review for a salon branch' })
  async createReview(
    @CurrentUser() user: any,
    @Body() data: any,
  ): Promise<ApiResponse<any>> {
    const review = await this.marketingService.createReview(user.id, data);
    return {
      success: true,
      data: review,
    };
  }

  @Post('reviews/:id/reply')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SALON_OWNER, UserRole.STAFF)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Reply to customer review' })
  async reply(
    @Param('id') id: string,
    @CurrentUser() user: any,
    @Body() dto: { replyText: string },
  ): Promise<ApiResponse<any>> {
    const res = await this.marketingService.createReply(id, user.id, dto.replyText);
    return {
      success: true,
      data: res,
    };
  }

  @Get('reviews/salon/:salonId')
  @ApiOperation({ summary: 'List reviews submitted for a salon branch' })
  async getReviews(@Param('salonId') salonId: string): Promise<ApiResponse<any>> {
    const reviews = await this.marketingService.getReviews(salonId);
    return {
      success: true,
      data: reviews,
    };
  }
}
