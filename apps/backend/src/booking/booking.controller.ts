import { Controller, Get, Post, Patch, Body, Param, ParseUUIDPipe, ParseEnumPipe, Query, UseGuards } from '@nestjs/common';
import { BookingService } from './booking.service';
import { ApiResponse } from '@trimly/types';
import { BookingStatus } from '@trimly/database';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TenantGuard } from '../common/guards/tenant.guard';
import { TenantId } from '../common/decorators/tenant.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { CreateBookingDto, CancelBookingDto, RescheduleBookingDto, JoinWaitingListDto, UpdateBookingStatusDto } from './dto/booking.dto';

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

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List bookings scoped to the current user (own bookings, or tenant bookings for salon staff)' })
  async list(
    @CurrentUser() user: any,
    @Query('status', new ParseEnumPipe(BookingStatus, { optional: true })) status?: BookingStatus,
  ): Promise<ApiResponse<any>> {
    const bookings = await this.bookingService.listBookings(user, status);
    return {
      success: true,
      data: bookings,
    };
  }

  @Post('create')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Book an appointment slot (limited by subscription)' })
  async create(
    @TenantId() tenantId: string,
    @CurrentUser() user: any,
    @Body() dto: CreateBookingDto,
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
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: any,
    @Body() dto: CancelBookingDto,
  ): Promise<ApiResponse<any>> {
    const booking = await this.bookingService.cancelBooking(id, user, dto.notes);
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
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: any,
    @Body() dto: RescheduleBookingDto,
  ): Promise<ApiResponse<any>> {
    const booking = await this.bookingService.rescheduleBooking(id, user, dto.startTime);
    return {
      success: true,
      data: booking,
    };
  }

  @Patch(':id/status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Salon owner/staff transitions a booking status (confirm, complete, no-show)' })
  async updateStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: any,
    @Body() dto: UpdateBookingStatusDto,
  ): Promise<ApiResponse<any>> {
    const booking = await this.bookingService.updateBookingStatus(id, user, dto.status);
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
    @Body() dto: JoinWaitingListDto,
  ): Promise<ApiResponse<any>> {
    const res = await this.bookingService.joinWaitingList(tenantId, user.id, dto.startTime);
    return {
      success: true,
      data: res,
    };
  }
}
