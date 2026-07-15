import { Controller, Get, Post, Put, Body, UseGuards, Param, HttpCode, HttpStatus, Headers, Req } from '@nestjs/common';
import type { Request } from 'express';
import type { RawBodyRequest } from '@nestjs/common';
import { OnboardingService } from './onboarding.service';
import { UserRole } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { TenantGuard } from '../common/guards/tenant.guard';
import { TenantId } from '../common/decorators/tenant.decorator';
import {
  BasicInfoDto, LocationDto, BusinessDetailsDto,
  BankDetailsDto, SubscriptionCheckoutDto, CustomerOnboardingDto,
} from './dto/onboarding.dto';

@ApiTags('Salon Onboarding')
@Controller('onboarding')
export class OnboardingController {
  constructor(private onboardingService: OnboardingService) {}

  @Get('status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current onboarding step status' })
  async getStatus(@CurrentUser() user: any): Promise<any> {
    return { success: true, data: await this.onboardingService.getStatus(user.id) };
  }

  @Post('basic-info')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Step 3: Save basic salon & owner info, create tenant' })
  async basicInfo(@CurrentUser() user: any, @Body() dto: BasicInfoDto): Promise<any> {
    return await this.onboardingService.basicInfo({ phone: user.phone, ...dto });
  }

  @Put('location')
  @UseGuards(JwtAuthGuard, TenantGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Step 4: Save business location' })
  async location(@TenantId() tenantId: string, @Body() dto: LocationDto): Promise<any> {
    return await this.onboardingService.location(tenantId, dto);
  }

  @Put('details')
  @UseGuards(JwtAuthGuard, TenantGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Step 5: Save business details (GST, PAN, etc.)' })
  async details(@TenantId() tenantId: string, @Body() dto: BusinessDetailsDto): Promise<any> {
    return await this.onboardingService.details(tenantId, dto);
  }

  @Post('timing')
  @UseGuards(JwtAuthGuard, TenantGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Step 6: Set business hours, breaks & holidays' })
  async timing(
    @TenantId() tenantId: string,
    @Body() body: { schedules: any[]; breaks?: any[]; holidays?: any[] },
  ): Promise<any> {
    return await this.onboardingService.timing(tenantId, body.schedules, body.breaks || [], body.holidays || []);
  }

  @Post('photos')
  @UseGuards(JwtAuthGuard, TenantGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Step 7: Save uploaded photo URLs' })
  async photos(
    @TenantId() tenantId: string,
    @Body() body: { logoUrl?: string; coverImageUrl?: string; gallery?: { url: string; mediaType: string }[] },
  ): Promise<any> {
    return await this.onboardingService.savePhotos(tenantId, body);
  }

  @Post('services')
  @UseGuards(JwtAuthGuard, TenantGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Step 8: Add services (batch)' })
  async addServices(@TenantId() tenantId: string, @Body() body: { services: any[] }): Promise<any> {
    return await this.onboardingService.addServices(tenantId, body.services);
  }

  @Post('staff')
  @UseGuards(JwtAuthGuard, TenantGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Step 9: Add staff (batch)' })
  async addStaff(@TenantId() tenantId: string, @Body() body: { staff: any[] }): Promise<any> {
    return await this.onboardingService.addStaff(tenantId, body.staff);
  }

  @Put('bank')
  @UseGuards(JwtAuthGuard, TenantGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Step 10: Save bank details for settlements' })
  async bankDetails(@TenantId() tenantId: string, @Body() dto: BankDetailsDto): Promise<any> {
    return await this.onboardingService.bankDetails(tenantId, dto);
  }

  @Post('kyc/:documentType')
  @UseGuards(JwtAuthGuard, TenantGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Step 11: Upload KYC document' })
  async kycUpload(
    @TenantId() tenantId: string,
    @Param('documentType') documentType: string,
    @Body() body: { fileUrl: string },
  ): Promise<any> {
    return await this.onboardingService.saveKycDocument(tenantId, documentType, body.fileUrl);
  }

  @Get('plans')
  @ApiOperation({ summary: 'Step 12: List subscription plans' })
  async getPlans(): Promise<any> {
    return await this.onboardingService.getPlans();
  }

  @Post('subscribe')
  @UseGuards(JwtAuthGuard, TenantGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Step 12: Select subscription plan (free or paid)' })
  async subscribe(@TenantId() tenantId: string, @Body() dto: SubscriptionCheckoutDto): Promise<any> {
    return await this.onboardingService.subscribe(tenantId, dto.planId);
  }

  @Post('complete')
  @UseGuards(JwtAuthGuard, TenantGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Step 14: Complete onboarding, submit for admin approval' })
  async complete(@TenantId() tenantId: string): Promise<any> {
    return await this.onboardingService.complete(tenantId);
  }

  @Post('webhook/subscription')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Handle subscription payment webhook from Razorpay' })
  async subscriptionWebhook(@Req() req: RawBodyRequest<Request>, @Headers('x-razorpay-signature') signature: string, @Body() payload: any): Promise<any> {
    return this.onboardingService.subscriptionWebhook(signature, req.rawBody as Buffer, payload);
  }

  @Post('customer/complete')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Customer Onboarding: Save preferences and complete onboarding' })
  async completeCustomerOnboarding(
    @CurrentUser() user: any,
    @Body() dto: CustomerOnboardingDto
  ): Promise<any> {
    const updatedUser = await this.onboardingService.completeCustomerOnboarding(user.id, dto);
    return {
      success: true,
      data: updatedUser,
    };
  }
}
