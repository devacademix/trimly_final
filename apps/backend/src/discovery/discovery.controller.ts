import { Controller, Get, Param, ParseUUIDPipe, Query, UseGuards } from '@nestjs/common';
import { DiscoveryService } from './discovery.service';
import { ApiResponse } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

// Customer-facing salon browsing. Any authenticated role can read these —
// unlike SalonController (owner/staff management), there is deliberately no
// RolesGuard/TenantGuard here: a customer isn't scoped to one tenant, they're
// choosing which one to look at.
@ApiTags('Salon Discovery (Public Browsing)')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('discovery')
export class DiscoveryController {
  constructor(private discoveryService: DiscoveryService) {}

  @Get('salons')
  @ApiOperation({ summary: 'Browse approved, active salons' })
  async listSalons(@Query('search') search?: string): Promise<ApiResponse<any>> {
    const salons = await this.discoveryService.listSalons(search);
    return { success: true, data: salons };
  }

  @Get('salons/:id')
  @ApiOperation({ summary: 'Get salon detail — branches, services, staff' })
  async getSalonDetail(@Param('id', ParseUUIDPipe) id: string): Promise<ApiResponse<any>> {
    const salon = await this.discoveryService.getSalonDetail(id);
    return { success: true, data: salon };
  }
}
