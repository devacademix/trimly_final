import { Injectable, BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SubscriptionService } from '../subscription/subscription.service';
import { NotificationService } from '../notifications/notification.service';
import { BookingStatus } from '@trimly/database';
import { UserRole } from '@trimly/types';

interface RequestingUser {
  id: string;
  role: UserRole;
  tenantId?: string | null;
}

@Injectable()
export class BookingService {
  constructor(
    private prisma: PrismaService,
    private subService: SubscriptionService,
    private notificationService: NotificationService,
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

    const service = await this.prisma.service.findFirst({
      where: { id: data.serviceId, tenantId },
    });
    if (!service) {
      throw new NotFoundException('Requested service not found');
    }

    const startTime = new Date(data.startTime);
    const endTime = new Date(startTime.getTime() + service.duration * 60 * 1000);

    let finalPrice = Number(service.price);
    let appliedCouponId: string | null = null;

    if (data.couponCode) {
      const coupon = await this.prisma.coupon.findFirst({
        where: { tenantId, code: data.couponCode.toUpperCase(), isActive: true },
      });
      if (coupon && coupon.startDate <= new Date() && coupon.endDate >= new Date()) {
        if (coupon.usageLimit === null || coupon.usedCount < coupon.usageLimit) {
          if (coupon.type === 'FLAT') {
            finalPrice = Math.max(0, finalPrice - Number(coupon.value));
          } else if (coupon.type === 'PERCENTAGE') {
            const discount = (finalPrice * Number(coupon.value)) / 100;
            finalPrice = Math.max(0, finalPrice - discount);
          }
          appliedCouponId = coupon.id;
        }
      }
    }

    const booking = await this.prisma.$transaction(async (tx) => {
      const created = await tx.booking.create({
        data: {
          tenantId,
          branchId: data.branchId,
          customerId,
          staffId: data.staffId || null,
          startTime,
          endTime,
          status: BookingStatus.PENDING,
          totalPrice: finalPrice,
        },
      });

      await tx.bookingItem.create({
        data: {
          bookingId: created.id,
          serviceId: service.id,
          price: service.price,
        },
      });

      if (appliedCouponId) {
        await tx.couponUsage.create({
          data: {
            couponId: appliedCouponId,
            userId: customerId,
            orderId: created.id,
          },
        });
        await tx.coupon.update({
          where: { id: appliedCouponId },
          data: { usedCount: { increment: 1 } },
        });
      }

      await tx.bookingHistory.create({
        data: {
          bookingId: created.id,
          status: BookingStatus.PENDING,
          notes: 'Booking created via API',
        },
      });

      return created;
    });

    // Notification failures must never fail the booking itself.
    this.notificationService.notifyBookingCreated(booking.id).catch(() => undefined);

    return booking;
  }

  // Ensure the requesting user is allowed to act on this booking
  // (the booking's own customer, or salon staff/owner/super-admin of its tenant).
  private assertBookingAccess(booking: { customerId: string; tenantId: string }, user: RequestingUser) {
    if (user.role === UserRole.SUPER_ADMIN) return;
    if (user.role === UserRole.CUSTOMER) {
      if (booking.customerId !== user.id) {
        throw new ForbiddenException('You do not have access to this booking');
      }
      return;
    }
    if (user.role === UserRole.SALON_OWNER || user.role === UserRole.MANAGER || user.role === UserRole.RECEPTIONIST || user.role === UserRole.STAFF) {
      if (booking.tenantId !== user.tenantId) {
        throw new ForbiddenException('You do not have access to this booking');
      }
      return;
    }
    throw new ForbiddenException('You do not have access to this booking');
  }

  // Cancel Booking
  async cancelBooking(bookingId: string, user: RequestingUser, notes?: string) {
    const booking = await this.prisma.booking.findUnique({ where: { id: bookingId } });
    if (!booking) {
      throw new NotFoundException('Booking not found');
    }
    this.assertBookingAccess(booking, user);

    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.booking.update({
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

      return result;
    });

    this.notificationService.notifyBookingStatusChange(bookingId, BookingStatus.CANCELLED).catch(() => undefined);

    return updated;

  }

  // Reschedule Booking
  async rescheduleBooking(bookingId: string, user: RequestingUser, startTimeStr: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { items: { include: { service: true } } },
    });
    if (!booking) {
      throw new NotFoundException('Booking not found');
    }
    this.assertBookingAccess(booking, user);

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

  // List bookings scoped to the requesting user: customers see their own
  // bookings, salon owner/staff see their tenant's bookings.
  async listBookings(user: RequestingUser, status?: BookingStatus) {
    const where: Record<string, unknown> = status ? { status } : {};

    if (user.role === UserRole.CUSTOMER) {
      where.customerId = user.id;
    } else if (user.role === UserRole.SALON_OWNER || user.role === UserRole.MANAGER || user.role === UserRole.RECEPTIONIST || user.role === UserRole.STAFF) {
      if (!user.tenantId) return [];
      where.tenantId = user.tenantId;
    } else {
      throw new ForbiddenException('You do not have access to bookings');
    }

    return this.prisma.booking.findMany({
      where,
      include: {
        items: { include: { service: { select: { name: true, duration: true } } } },
        branch: { select: { name: true, address: true } },
        customer: { select: { fullName: true, email: true, phone: true } },
        staff: { select: { user: { select: { fullName: true } } } },
      },
      orderBy: { startTime: 'desc' },
    });
  }

  // Salon owner/staff transitions a booking's status (confirm, complete, no-show, cancel).
  async updateBookingStatus(bookingId: string, user: RequestingUser, status: BookingStatus) {
    if (user.role !== UserRole.SALON_OWNER && user.role !== UserRole.MANAGER && user.role !== UserRole.RECEPTIONIST && user.role !== UserRole.STAFF && user.role !== UserRole.SUPER_ADMIN) {
      throw new ForbiddenException('You do not have permission to update booking status');
    }

    const booking = await this.prisma.booking.findUnique({ where: { id: bookingId } });
    if (!booking) {
      throw new NotFoundException('Booking not found');
    }
    this.assertBookingAccess(booking, user);

    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.booking.update({
        where: { id: bookingId },
        data: { status },
      });

      await tx.bookingHistory.create({
        data: {
          bookingId,
          status,
          notes: `Status updated to ${status}`,
        },
      });

      return result;
    });

    this.notificationService.notifyBookingStatusChange(bookingId, status).catch(() => undefined);

    return updated;
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
