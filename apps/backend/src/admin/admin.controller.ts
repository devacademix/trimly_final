import { Controller, Get, Patch, Post, Delete, Body, Param, ParseUUIDPipe, Query, UseGuards } from '@nestjs/common';
import { AdminService } from './admin.service';
import { UserRole, ApiResponse } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UpdateSalonStatusDto, UpdateSalonCommissionDto, SetGlobalCommissionDto, UpdateUserStatusDto, UpdateUserRoleDto } from './dto/admin.dto';

@ApiTags('Super Admin Control')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SUPER_ADMIN)
@Controller('admin')
export class AdminController {
  constructor(private adminService: AdminService) {}

  @Get('salons')
  @ApiOperation({ summary: 'List all salon businesses/tenants' })
  async getSalons(): Promise<ApiResponse<any>> {
    const salons = await this.adminService.getSalons();
    return {
      success: true,
      data: salons,
    };
  }

  @Patch('salons/:id/status')
  @ApiOperation({ summary: 'Approve, reject, or suspend a salon tenant' })
  async updateSalonStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSalonStatusDto,
  ): Promise<ApiResponse<any>> {
    const salon = await this.adminService.updateSalonStatus(id, dto.status, dto.isActive);
    return {
      success: true,
      data: salon,
    };
  }

  @Patch('salons/:id/commission')
  @ApiOperation({ summary: 'Override commission rate per salon' })
  async updateSalonCommission(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSalonCommissionDto,
  ): Promise<ApiResponse<any>> {
    const salon = await this.adminService.updateSalonCommission(id, dto.commissionPct);
    return {
      success: true,
      data: salon,
    };
  }

  @Get('users')
  @ApiOperation({ summary: 'List all registered platform users' })
  async getUsers(@Query('role') role?: UserRole): Promise<ApiResponse<any>> {
    const users = await this.adminService.getUsers(role);
    return {
      success: true,
      data: users,
    };
  }

  @Get('bookings')
  @ApiOperation({ summary: 'List all bookings across the platform' })
  async getBookings(): Promise<ApiResponse<any>> {
    const bookings = await this.adminService.getBookings();
    return {
      success: true,
      data: bookings,
    };
  }

  @Post('settings/commission')
  @ApiOperation({ summary: 'Configure global default platform commission' })
  async setGlobalCommission(@Body() dto: SetGlobalCommissionDto): Promise<ApiResponse<any>> {
    const setting = await this.adminService.setGlobalCommission(dto.commissionPct);
    return {
      success: true,
      data: setting,
    };
  }

  @Get('revenue')
  @ApiOperation({ summary: 'Retrieve global platform revenue analytics' })
  async getRevenueStats(): Promise<ApiResponse<any>> {
    const stats = await this.adminService.getRevenueStats();
    return {
      success: true,
      data: stats,
    };
  }

  @Delete('salons/:id')
  @ApiOperation({ summary: 'Hard-delete a salon/tenant from the database' })
  async deleteSalon(@Param('id', ParseUUIDPipe) id: string): Promise<ApiResponse<any>> {
    await this.adminService.deleteSalon(id);
    return {
      success: true,
      data: { message: 'Salon successfully purged from database' },
    };
  }

  @Patch('users/:id/status')
  @ApiOperation({ summary: 'Update status/block a user' })
  async updateUserStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserStatusDto,
  ): Promise<ApiResponse<any>> {
    const user = await this.adminService.updateUserStatus(id, dto.status);
    return {
      success: true,
      data: user,
    };
  }

  @Patch('users/:id/role')
  @ApiOperation({ summary: 'Change user role' })
  async updateUserRole(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserRoleDto,
  ): Promise<ApiResponse<any>> {
    const user = await this.adminService.updateUserRole(id, dto.role);
    return {
      success: true,
      data: user,
    };
  }

  @Delete('users/:id')
  @ApiOperation({ summary: 'Hard-delete a user from database' })
  async deleteUser(@Param('id', ParseUUIDPipe) id: string): Promise<ApiResponse<any>> {
    await this.adminService.deleteUser(id);
    return {
      success: true,
      data: { message: 'User successfully purged from database' },
    };
  }
}
