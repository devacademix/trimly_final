import { Controller, Get, Post, Put, Body, UseGuards } from '@nestjs/common';
import { SalonService } from './salon.service';
import { ApiResponse, UserRole } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { TenantGuard } from '../common/guards/tenant.guard';
import { TenantId } from '../common/decorators/tenant.decorator';

@ApiTags('Salon Business & Management')
@ApiBearerAuth()
@ApiHeader({ name: 'x-tenant-id', required: false, description: 'Salon / Tenant UUID' })
@UseGuards(JwtAuthGuard, TenantGuard, RolesGuard)
@Roles(UserRole.SALON_OWNER, UserRole.STAFF)
@Controller('salon')
export class SalonController {
  constructor(private salonService: SalonService) {}

  @Get('profile')
  @ApiOperation({ summary: 'Get current Salon business profile details' })
  async getProfile(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const profile = await this.salonService.getProfile(tenantId);
    return {
      success: true,
      data: profile,
    };
  }

  @Put('profile')
  @ApiOperation({ summary: 'Update Salon business profile details' })
  async updateProfile(
    @TenantId() tenantId: string,
    @Body() data: any,
  ): Promise<ApiResponse<any>> {
    const profile = await this.salonService.updateProfile(tenantId, data);
    return {
      success: true,
      data: profile,
    };
  }

  @Get('branches')
  @ApiOperation({ summary: 'List all branches' })
  async getBranches(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const branches = await this.salonService.getBranches(tenantId);
    return {
      success: true,
      data: branches,
    };
  }

  @Post('branches')
  @Roles(UserRole.SALON_OWNER)
  @ApiOperation({ summary: 'Create new branch (limited by subscription)' })
  async createBranch(
    @TenantId() tenantId: string,
    @Body() data: any,
  ): Promise<ApiResponse<any>> {
    const branch = await this.salonService.createBranch(tenantId, data);
    return {
      success: true,
      data: branch,
    };
  }

  @Get('staff')
  @ApiOperation({ summary: 'List all staff profiles' })
  async getStaff(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const staff = await this.salonService.getStaff(tenantId);
    return {
      success: true,
      data: staff,
    };
  }

  @Post('staff')
  @Roles(UserRole.SALON_OWNER)
  @ApiOperation({ summary: 'Invite or recruit new staff profile (limited by subscription)' })
  async recruitStaff(
    @TenantId() tenantId: string,
    @Body() data: any,
  ): Promise<ApiResponse<any>> {
    const staff = await this.salonService.recruitStaff(tenantId, data);
    return {
      success: true,
      data: staff,
    };
  }

  @Get('services')
  @ApiOperation({ summary: 'List services in the catalog' })
  async getServices(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const services = await this.salonService.getServices(tenantId);
    return {
      success: true,
      data: services,
    };
  }

  @Post('services')
  @Roles(UserRole.SALON_OWNER)
  @ApiOperation({ summary: 'Add a service to the catalog' })
  async createService(
    @TenantId() tenantId: string,
    @Body() data: any,
  ): Promise<ApiResponse<any>> {
    const service = await this.salonService.createService(tenantId, data);
    return {
      success: true,
      data: service,
    };
  }

  @Post('schedules')
  @Roles(UserRole.SALON_OWNER)
  @ApiOperation({ summary: 'Setup weekly working schedule' })
  async setupSchedules(
    @TenantId() tenantId: string,
    @Body() data: { schedules: any[] },
  ): Promise<ApiResponse<any>> {
    const res = await this.salonService.setupSchedules(tenantId, data.schedules);
    return {
      success: true,
      data: res,
    };
  }
}
