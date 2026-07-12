import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { BookingService } from './booking.service';
import { BookingStatus } from '@trimly/database';
import { UserRole } from '@trimly/types';

describe('BookingService', () => {
  let service: BookingService;
  let prisma: any;
  let subService: any;
  let notificationService: any;

  const fakeTransaction = (impl: (tx: any) => Promise<any>) => impl(prisma);

  beforeEach(() => {
    prisma = {
      booking: { findUnique: jest.fn(), update: jest.fn(), create: jest.fn() },
      bookingItem: { create: jest.fn() },
      bookingHistory: { create: jest.fn() },
      service: { findFirst: jest.fn() },
      $transaction: jest.fn(fakeTransaction),
    };
    subService = { checkLimit: jest.fn().mockResolvedValue(true) };
    notificationService = {
      notifyBookingCreated: jest.fn().mockResolvedValue(undefined),
      notifyBookingStatusChange: jest.fn().mockResolvedValue(undefined),
    };
    service = new BookingService(prisma, subService, notificationService);
  });

  describe('cancelBooking — ownership enforcement (IDOR fix)', () => {
    const booking = { id: 'b1', customerId: 'customer-1', tenantId: 'tenant-1', status: BookingStatus.PENDING };

    beforeEach(() => {
      prisma.booking.findUnique.mockResolvedValue(booking);
      prisma.booking.update.mockResolvedValue({ ...booking, status: BookingStatus.CANCELLED });
    });

    it('throws NotFoundException when the booking does not exist', async () => {
      prisma.booking.findUnique.mockResolvedValue(null);
      await expect(
        service.cancelBooking('missing', { id: 'customer-1', role: UserRole.CUSTOMER }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('allows the owning customer to cancel their own booking', async () => {
      await expect(
        service.cancelBooking('b1', { id: 'customer-1', role: UserRole.CUSTOMER }),
      ).resolves.toBeDefined();
    });

    it('rejects a different customer cancelling someone else’s booking', async () => {
      await expect(
        service.cancelBooking('b1', { id: 'customer-2', role: UserRole.CUSTOMER }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('rejects a salon owner from a different tenant', async () => {
      await expect(
        service.cancelBooking('b1', { id: 'owner-x', role: UserRole.SALON_OWNER, tenantId: 'tenant-2' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('allows the owning tenant’s salon owner to cancel', async () => {
      await expect(
        service.cancelBooking('b1', { id: 'owner-1', role: UserRole.SALON_OWNER, tenantId: 'tenant-1' }),
      ).resolves.toBeDefined();
    });

    it('allows SUPER_ADMIN regardless of tenant', async () => {
      await expect(
        service.cancelBooking('b1', { id: 'admin-1', role: UserRole.SUPER_ADMIN }),
      ).resolves.toBeDefined();
    });
  });

  describe('rescheduleBooking — ownership enforcement (IDOR fix)', () => {
    const booking = {
      id: 'b1',
      customerId: 'customer-1',
      tenantId: 'tenant-1',
      status: BookingStatus.PENDING,
      items: [{ service: { duration: 30 } }],
    };

    beforeEach(() => {
      prisma.booking.findUnique.mockResolvedValue(booking);
      prisma.booking.update.mockResolvedValue({ ...booking });
    });

    it('rejects a customer rescheduling a booking that is not theirs', async () => {
      await expect(
        service.rescheduleBooking('b1', { id: 'customer-2', role: UserRole.CUSTOMER }, '2026-01-01T10:00:00Z'),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('allows the owning customer to reschedule', async () => {
      await expect(
        service.rescheduleBooking('b1', { id: 'customer-1', role: UserRole.CUSTOMER }, '2026-01-01T10:00:00Z'),
      ).resolves.toBeDefined();
    });
  });

  describe('createBooking — tenant-scoped service lookup', () => {
    it('looks up the service scoped to the requesting tenant, not globally by id', async () => {
      prisma.service.findFirst.mockResolvedValue({ id: 'svc-1', price: 500, duration: 30 });
      prisma.booking.create.mockResolvedValue({ id: 'new-booking' });
      prisma.bookingItem.create.mockResolvedValue({});
      prisma.bookingHistory.create.mockResolvedValue({});

      await service.createBooking('tenant-1', 'customer-1', {
        branchId: 'branch-1',
        serviceId: 'svc-1',
        startTime: '2026-01-01T10:00:00Z',
      });

      expect(prisma.service.findFirst).toHaveBeenCalledWith({
        where: { id: 'svc-1', tenantId: 'tenant-1' },
      });
    });

    it('throws NotFoundException when the service does not belong to this tenant', async () => {
      prisma.service.findFirst.mockResolvedValue(null);

      await expect(
        service.createBooking('tenant-1', 'customer-1', {
          branchId: 'branch-1',
          serviceId: 'svc-from-other-tenant',
          startTime: '2026-01-01T10:00:00Z',
        }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });
});
