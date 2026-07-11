import { Controller, Get, UseGuards } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { ApiResponse, UserRole } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { TenantGuard } from '../common/guards/tenant.guard';
import { TenantId } from '../common/decorators/tenant.decorator';

@ApiTags('Reports & Analytics')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('analytics')
export class AnalyticsController {
  constructor(private analyticsService: AnalyticsService) {}

  @Get('dashboard')
  @UseGuards(TenantGuard, RolesGuard)
  @Roles(UserRole.SALON_OWNER, UserRole.STAFF)
  @ApiHeader({ name: 'x-tenant-id' })
  @ApiOperation({ summary: 'Get dashboard summary stats for salon owner/staff' })
  async getDashboardStats(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const stats = await this.analyticsService.getDashboardStats(tenantId);
    return {
      success: true,
      data: stats,
    };
  }

  @Get('peak-hours')
  @UseGuards(TenantGuard, RolesGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiHeader({ name: 'x-tenant-id' })
  @ApiOperation({ summary: 'Get operational peak-hours appointment charts data' })
  async getPeakHours(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const data = await this.analyticsService.getPeakHours(tenantId);
    return {
      success: true,
      data,
    };
  }

  @Get('services')
  @UseGuards(TenantGuard, RolesGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiHeader({ name: 'x-tenant-id' })
  @ApiOperation({ summary: 'Get top performing services ranked by sales volume' })
  async getTopServices(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const data = await this.analyticsService.getTopServices(tenantId);
    return {
      success: true,
      data,
    };
  }

  @Get('admin/subscriptions')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Get subscription analytics for super-admin dashboard' })
  async getAdminSubscriptions(): Promise<ApiResponse<any>> {
    const stats = await this.analyticsService.getAdminSubscriptionStats();
    return {
      success: true,
      data: stats,
    };
  }
}
