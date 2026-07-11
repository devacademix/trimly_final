import { Controller, Get, Post, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { BookingService } from './booking.service';
import { ApiResponse } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TenantGuard } from '../common/guards/tenant.guard';
import { TenantId } from '../common/decorators/tenant.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Booking Engine')
@ApiHeader({ name: 'x-tenant-id', required: false, description: 'Salon / Tenant UUID' })
@UseGuards(TenantGuard)
@Controller('booking')
export class BookingController {
  constructor(private bookingService: BookingService) {}

  @Get('availability')
  @ApiOperation({ summary: 'Calculate live available time slots for a salon branch' })
  async getAvailability(
    @TenantId() tenantId: string,
    @Query('branchId') branchId: string,
    @Query('date') date: string,
    @Query('staffId') staffId?: string,
  ): Promise<ApiResponse<any>> {
    const res = await this.bookingService.getAvailability(tenantId, branchId, date, staffId);
    return {
      success: true,
      data: res,
    };
  }

  @Post('create')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Book an appointment slot (limited by subscription)' })
  async create(
    @TenantId() tenantId: string,
    @CurrentUser() user: any,
    @Body() dto: { branchId: string; serviceId: string; staffId?: string; startTime: string },
  ): Promise<ApiResponse<any>> {
    const booking = await this.bookingService.createBooking(tenantId, user.id, dto);
    return {
      success: true,
      data: booking,
    };
  }

  @Patch(':id/cancel')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Cancel an active appointment' })
  async cancel(
    @Param('id') id: string,
    @Body() dto: { notes?: string },
  ): Promise<ApiResponse<any>> {
    const booking = await this.bookingService.cancelBooking(id, dto.notes);
    return {
      success: true,
      data: booking,
    };
  }

  @Patch(':id/reschedule')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Reschedule an active appointment' })
  async reschedule(
    @Param('id') id: string,
    @Body() dto: { startTime: string },
  ): Promise<ApiResponse<any>> {
    const booking = await this.bookingService.rescheduleBooking(id, dto.startTime);
    return {
      success: true,
      data: booking,
    };
  }

  @Post('waiting-list')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Join waiting list for a specific slot' })
  async joinWaitingList(
    @TenantId() tenantId: string,
    @CurrentUser() user: any,
    @Body() dto: { startTime: string },
  ): Promise<ApiResponse<any>> {
    const res = await this.bookingService.joinWaitingList(tenantId, user.id, dto.startTime);
    return {
      success: true,
      data: res,
    };
  }
}
