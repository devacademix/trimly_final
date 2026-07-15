import { Controller, Get, Post, Put, Patch, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { SalonService } from './salon.service';
import { ApiResponse, UserRole } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { TenantGuard } from '../common/guards/tenant.guard';
import { TenantId } from '../common/decorators/tenant.decorator';
import { UpdateSalonProfileDto, CreateBranchDto, RecruitStaffDto, CreateServiceDto, SetupSchedulesDto } from './dto/salon.dto';

@ApiTags('Salon Business & Management')
@ApiBearerAuth()
@ApiHeader({ name: 'x-tenant-id', required: false, description: 'Salon / Tenant UUID' })
@UseGuards(JwtAuthGuard, TenantGuard, RolesGuard)
@Roles(UserRole.SALON_OWNER, UserRole.MANAGER, UserRole.RECEPTIONIST, UserRole.STAFF)
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
    @Body() data: UpdateSalonProfileDto,
  ): Promise<ApiResponse<any>> {
    const profile = await this.salonService.updateProfile(tenantId, data);
    return {
      success: true,
      data: profile,
    };
  }

  @Put('status')
  @Roles(UserRole.SALON_OWNER, UserRole.MANAGER)
  @ApiOperation({ summary: 'Toggle shop open/closed status' })
  async updateShopStatus(
    @TenantId() tenantId: string,
    @Body() body: { isOpen: boolean },
  ): Promise<ApiResponse<any>> {
    const status = await this.salonService.updateShopStatus(tenantId, body.isOpen);
    return {
      success: true,
      data: { status },
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
  @Roles(UserRole.SALON_OWNER, UserRole.MANAGER)
  @ApiOperation({ summary: 'Create new branch (limited by subscription)' })
  async createBranch(
    @TenantId() tenantId: string,
    @Body() data: CreateBranchDto,
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
  @Roles(UserRole.SALON_OWNER, UserRole.MANAGER)
  @ApiOperation({ summary: 'Invite or recruit new staff profile (limited by subscription)' })
  async recruitStaff(
    @TenantId() tenantId: string,
    @Body() data: RecruitStaffDto,
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
  @Roles(UserRole.SALON_OWNER, UserRole.MANAGER)
  @ApiOperation({ summary: 'Add a service to the catalog' })
  async createService(
    @TenantId() tenantId: string,
    @Body() data: CreateServiceDto,
  ): Promise<ApiResponse<any>> {
    const service = await this.salonService.createService(tenantId, data);
    return {
      success: true,
      data: service,
    };
  }

  @Get('customers')
  @ApiOperation({ summary: 'List distinct customers who have booked with this salon' })
  async getCustomers(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const customers = await this.salonService.getCustomers(tenantId);
    return {
      success: true,
      data: customers,
    };
  }

  @Post('schedules')
  @Roles(UserRole.SALON_OWNER, UserRole.MANAGER)
  @ApiOperation({ summary: 'Setup weekly working schedule' })
  async setupSchedules(
    @TenantId() tenantId: string,
    @Body() data: SetupSchedulesDto,
  ): Promise<ApiResponse<any>> {
    const res = await this.salonService.setupSchedules(tenantId, data.schedules);
    return {
      success: true,
      data: res,
    };
  }

  // ─── Categories ───────────────────────────────────────────────────────────────

  @Get('categories')
  @ApiOperation({ summary: 'List service categories' })
  async getCategories(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const data = await this.salonService.getCategories(tenantId);
    return { success: true, data };
  }

  @Post('categories')
  @Roles(UserRole.SALON_OWNER, UserRole.MANAGER)
  @ApiOperation({ summary: 'Create a service category' })
  async createCategory(
    @TenantId() tenantId: string,
    @Body() body: { name: string; description?: string },
  ): Promise<ApiResponse<any>> {
    const data = await this.salonService.createCategory(tenantId, body.name, body.description);
    return { success: true, data };
  }

  // ─── Services Extended ────────────────────────────────────────────────────────

  @Put('services/:id')
  @Roles(UserRole.SALON_OWNER, UserRole.MANAGER)
  @ApiOperation({ summary: 'Update a service' })
  async updateService(
    @TenantId() tenantId: string,
    @Param('id') id: string,
    @Body() data: any,
  ): Promise<ApiResponse<any>> {
    const service = await this.salonService.updateService(tenantId, id, data);
    return { success: true, data: service };
  }

  @Delete('services/:id')
  @Roles(UserRole.SALON_OWNER, UserRole.MANAGER)
  @ApiOperation({ summary: 'Delete (soft) a service' })
  async deleteService(
    @TenantId() tenantId: string,
    @Param('id') id: string,
  ): Promise<ApiResponse<any>> {
    await this.salonService.deleteService(tenantId, id);
    return { success: true, data: { deleted: true } };
  }

  // ─── Staff Extended ────────────────────────────────────────────────────────────

  @Patch('staff/:staffId/status')
  @Roles(UserRole.SALON_OWNER, UserRole.MANAGER)
  @ApiOperation({ summary: 'Toggle staff active/inactive' })
  async updateStaffStatus(
    @TenantId() tenantId: string,
    @Param('staffId') staffId: string,
    @Body() body: { isActive: boolean },
  ): Promise<ApiResponse<any>> {
    const result = await this.salonService.updateStaffStatus(tenantId, staffId, body.isActive);
    return { success: true, data: result };
  }
}

