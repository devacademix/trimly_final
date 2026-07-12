import * as crypto from 'crypto';
import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PaymentService } from './payment.service';
import { PaymentStatus } from '@trimly/database';
import { UserRole } from '@trimly/types';

describe('PaymentService', () => {
  let service: PaymentService;
  let prisma: any;
  let notificationService: any;

  beforeEach(() => {
    prisma = {
      tenant: { findUnique: jest.fn() },
      setting: { findUnique: jest.fn() },
      booking: { findUnique: jest.fn(), findFirst: jest.fn(), update: jest.fn() },
      payment: { findUnique: jest.fn(), create: jest.fn(), update: jest.fn() },
      refund: { create: jest.fn() },
      bookingHistory: { create: jest.fn() },
      $transaction: jest.fn((impl: (tx: any) => Promise<any>) => impl(prisma)),
    };
    notificationService = {
      notifyPaymentSuccess: jest.fn().mockResolvedValue(undefined),
    };
    service = new PaymentService(prisma, notificationService);
  });

  describe('handleWebhook — signature verification (Phase 0 fix)', () => {
    it('rejects when no webhook secret is configured (fail closed)', async () => {
      delete process.env.RAZORPAY_WEBHOOK_SECRET;
      await expect(
        service.handleWebhook('any-signature', Buffer.from('{}'), { event: 'payment.captured' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects an invalid signature', async () => {
      process.env.RAZORPAY_WEBHOOK_SECRET = 'test-webhook-secret';
      const rawBody = Buffer.from(JSON.stringify({ event: 'payment.captured' }));

      await expect(service.handleWebhook('deadbeef', rawBody, { event: 'payment.captured' })).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('accepts a correctly signed payload computed over the raw body', async () => {
      process.env.RAZORPAY_WEBHOOK_SECRET = 'test-webhook-secret';
      const payload = { event: 'unhandled.event' };
      const rawBody = Buffer.from(JSON.stringify(payload));
      const signature = crypto.createHmac('sha256', 'test-webhook-secret').update(rawBody).digest('hex');

      await expect(service.handleWebhook(signature, rawBody, payload)).resolves.toEqual({ success: true });
    });
  });

  describe('createBookingCheckout — ownership enforcement (Phase 0 fix)', () => {
    it('throws NotFoundException when the booking is not in this tenant', async () => {
      prisma.booking.findFirst.mockResolvedValue(null);
      await expect(
        service.createBookingCheckout('tenant-1', 'booking-1', { id: 'customer-1', role: UserRole.CUSTOMER }),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('rejects a customer checking out someone else’s booking', async () => {
      prisma.booking.findFirst.mockResolvedValue({
        id: 'booking-1',
        tenantId: 'tenant-1',
        customerId: 'other-customer',
        totalPrice: 500,
      });

      await expect(
        service.createBookingCheckout('tenant-1', 'booking-1', { id: 'customer-1', role: UserRole.CUSTOMER }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('allows the owning customer to checkout their own booking', async () => {
      prisma.booking.findFirst.mockResolvedValue({
        id: 'booking-1',
        tenantId: 'tenant-1',
        customerId: 'customer-1',
        totalPrice: 500,
      });
      prisma.tenant.findUnique.mockResolvedValue({ commissionPct: 10 });

      await expect(
        service.createBookingCheckout('tenant-1', 'booking-1', { id: 'customer-1', role: UserRole.CUSTOMER }),
      ).resolves.toMatchObject({ gateway: 'razorpay' });
    });
  });

  describe('refundPayment — cross-tenant enforcement (Phase 0 fix)', () => {
    const payment = {
      id: 'pay-1',
      bookingId: 'booking-1',
      amount: 500,
      paymentStatus: PaymentStatus.CAPTURED,
      booking: { id: 'booking-1', tenantId: 'tenant-1' },
    };

    it('rejects a salon owner refunding a payment from another tenant', async () => {
      prisma.payment.findUnique.mockResolvedValue(payment);
      await expect(
        service.refundPayment('pay-1', { role: UserRole.SALON_OWNER, tenantId: 'tenant-2' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('allows the owning tenant’s salon owner to refund', async () => {
      prisma.payment.findUnique.mockResolvedValue(payment);
      prisma.refund.create.mockResolvedValue({ id: 'refund-1' });
      prisma.payment.update.mockResolvedValue({});
      prisma.booking.update.mockResolvedValue({});
      prisma.bookingHistory.create.mockResolvedValue({});

      await expect(
        service.refundPayment('pay-1', { role: UserRole.SALON_OWNER, tenantId: 'tenant-1' }),
      ).resolves.toBeDefined();
    });

    it('allows SUPER_ADMIN regardless of tenant', async () => {
      prisma.payment.findUnique.mockResolvedValue(payment);
      prisma.refund.create.mockResolvedValue({ id: 'refund-1' });
      prisma.payment.update.mockResolvedValue({});
      prisma.booking.update.mockResolvedValue({});
      prisma.bookingHistory.create.mockResolvedValue({});

      await expect(
        service.refundPayment('pay-1', { role: UserRole.SUPER_ADMIN }),
      ).resolves.toBeDefined();
    });
  });
});
