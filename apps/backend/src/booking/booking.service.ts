import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SubscriptionService } from '../subscription/subscription.service';
import { BookingStatus } from '@trimly/database';

@Injectable()
export class BookingService {
  constructor(
    private prisma: PrismaService,
    private subService: SubscriptionService,
  ) {}

  // Calculate live slot availability for a salon branch & date
  async getAvailability(tenantId: string, branchId: string, dateStr: string, staffId?: string) {
    const targetDate = new Date(dateStr);
    const dayOfWeek = targetDate.getDay(); // 0 = Sunday, 6 = Saturday

    // 1. Check if the date is a holiday
    const holiday = await this.prisma.holiday.findFirst({
      where: { tenantId, date: targetDate },
    });
    if (holiday) {
      return { isOpen: false, reason: 'Holiday', slots: [] };
    }

    // 2. Fetch Working Hours
    const workingHour = await this.prisma.workingHours.findUnique({
      where: { tenantId_dayOfWeek: { tenantId, dayOfWeek } },
    });
    if (!workingHour || !workingHour.isOpen) {
      return { isOpen: false, reason: 'Closed', slots: [] };
    }

    // 3. Fetch Break Hours
    const breaks = await this.prisma.breakHours.findMany({
      where: { tenantId, dayOfWeek },
    });

    // 4. Fetch Active Bookings on target day
    const startOfDay = new Date(targetDate.setHours(0, 0, 0, 0));
    const endOfDay = new Date(targetDate.setHours(23, 59, 59, 999));

    const bookings = await this.prisma.booking.findMany({
      where: {
        tenantId,
        branchId,
        startTime: { gte: startOfDay, lte: endOfDay },
        status: { in: [BookingStatus.PENDING, BookingStatus.CONFIRMED] },
        ...(staffId ? { staffId } : {}),
      },
      select: { startTime: true, endTime: true },
    });

    // 5. Generate slots (e.g., 30-minute intervals between openTime and closeTime)
    const openTimeStr = workingHour.openTime; // HH:MM
    const closeTimeStr = workingHour.closeTime;

    const [openH, openM] = openTimeStr.split(':').map(Number);
    const [closeH, closeM] = closeTimeStr.split(':').map(Number);

    if (openH === undefined || openM === undefined || closeH === undefined || closeM === undefined) {
      return { isOpen: false, reason: 'Invalid working hours configuration', slots: [] };
    }

    const slots: string[] = [];
    let currentMin = openH * 60 + openM;
    const endMin = closeH * 60 + closeM;

    while (currentMin + 30 <= endMin) {
      const startH = Math.floor(currentMin / 60);
      const startM = currentMin % 60;
      const endH = Math.floor((currentMin + 30) / 60);
      const endM = (currentMin + 30) % 60;

      const slotStartStr = `${startH.toString().padStart(2, '0')}:${startM.toString().padStart(2, '0')}`;
      const slotEndStr = `${endH.toString().padStart(2, '0')}:${endM.toString().padStart(2, '0')}`;

      // Check if slot falls in break hours
      let isBreak = false;
      for (const b of breaks) {
        const [bStartH, bStartM] = b.startTime.split(':').map(Number);
        const [bEndH, bEndM] = b.endTime.split(':').map(Number);
        if (bStartH !== undefined && bStartM !== undefined && bEndH !== undefined && bEndM !== undefined) {
          const bStartMin = bStartH * 60 + bStartM;
          const bEndMin = bEndH * 60 + bEndM;
          if (currentMin >= bStartMin && currentMin < bEndMin) {
            isBreak = true;
            break;
          }
        }
      }

      // Check if slot overlaps with active bookings
      let isBooked = false;
      for (const b of bookings) {
        const bStartMin = b.startTime.getHours() * 60 + b.startTime.getMinutes();
        const bEndMin = b.endTime.getHours() * 60 + b.endTime.getMinutes();
        if (currentMin >= bStartMin && currentMin < bEndMin) {
          isBooked = true;
          break;
        }
      }

      if (!isBreak && !isBooked) {
        slots.push(`${slotStartStr} - ${slotEndStr}`);
      }

      currentMin += 30; // 30 mins step
    }

    return {
      isOpen: true,
      slots,
    };
  }

  // Create booking (limited by subscription plan)
  async createBooking(tenantId: string, customerId: string, data: any) {
    const isAllowed = await this.subService.checkLimit(tenantId, 'booking');
    if (!isAllowed) {
      throw new BadRequestException('Booking limit reached for current subscription plan. Upgrade to receive more appointments.');
    }

    const service = await this.prisma.service.findUnique({
      where: { id: data.serviceId },
    });
    if (!service) {
      throw new NotFoundException('Requested service not found');
    }

    const startTime = new Date(data.startTime);
    const endTime = new Date(startTime.getTime() + service.duration * 60 * 1000);

    return this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.create({
        data: {
          tenantId,
          branchId: data.branchId,
          customerId,
          staffId: data.staffId || null,
          startTime,
          endTime,
          status: BookingStatus.PENDING,
          totalPrice: service.price,
        },
      });

      await tx.bookingItem.create({
        data: {
          bookingId: booking.id,
          serviceId: service.id,
          price: service.price,
        },
      });

      await tx.bookingHistory.create({
        data: {
          bookingId: booking.id,
          status: BookingStatus.PENDING,
          notes: 'Booking created via API',
        },
      });

      return booking;
    });
  }

  // Cancel Booking
  async cancelBooking(bookingId: string, notes?: string) {
    const booking = await this.prisma.booking.findUnique({ where: { id: bookingId } });
    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: { status: BookingStatus.CANCELLED },
      });

      await tx.bookingHistory.create({
        data: {
          bookingId,
          status: BookingStatus.CANCELLED,
          notes: notes || 'Booking cancelled',
        },
      });

      return updated;
    });
  }

  // Reschedule Booking
  async rescheduleBooking(bookingId: string, startTimeStr: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { items: { include: { service: true } } },
    });
    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    const item = booking.items[0];
    if (!item) {
      throw new BadRequestException('Booking has no services linked');
    }

    const startTime = new Date(startTimeStr);
    const endTime = new Date(startTime.getTime() + item.service.duration * 60 * 1000);

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.booking.update({
        where: { id: bookingId },
        data: { startTime, endTime },
      });

      await tx.bookingHistory.create({
        data: {
          bookingId,
          status: booking.status,
          notes: `Rescheduled to ${startTimeStr}`,
        },
      });

      return updated;
    });
  }

  // Add to waiting list
  async joinWaitingList(tenantId: string, userId: string, startTimeStr: string) {
    return this.prisma.waitingList.create({
      data: {
        tenantId,
        userId,
        startTime: new Date(startTimeStr),
      },
    });
  }
}
