import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationService } from '../notifications/notification.service';
import crypto from 'crypto';
import { PaymentStatus, PaymentMethod, BookingStatus } from '@trimly/database';
import { UserRole } from '@trimly/types';

@Injectable()
export class PaymentService {
  constructor(
    private prisma: PrismaService,
    private notificationService: NotificationService,
  ) {}

  // Resolve active commission percentage for a tenant
  async getCommissionPct(tenantId: string): Promise<number> {
    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantId },
      select: { commissionPct: true },
    });

    if (tenant && tenant.commissionPct !== null) {
      return Number(tenant.commissionPct);
    }

    // Fall back to platform setting
    const globalSetting = await this.prisma.setting.findUnique({
      where: { key: 'platform.defaultCommissionPct' },
    });

    return globalSetting ? Number(globalSetting.value) : 15; // default 15%
  }

  // Calculate split details
  async calculateSplit(tenantId: string, totalAmount: number) {
    const pct = await this.getCommissionPct(tenantId);
    const commissionFee = (totalAmount * pct) / 100;
    const taxFee = 0.0; // Extendable for GST
    const salonCut = totalAmount - commissionFee - taxFee;

    return {
      commissionPct: pct,
      commissionFee,
      taxFee,
      salonCut,
    };
  }

  // Create checkout session for booking
  async createBookingCheckout(
    tenantId: string,
    bookingId: string,
    user: { id: string; role: UserRole },
  ) {
    const booking = await this.prisma.booking.findFirst({
      where: { id: bookingId, tenantId },
    });
    if (!booking) {
      throw new NotFoundException('Booking not found');
    }
    if (user.role === UserRole.CUSTOMER && booking.customerId !== user.id) {
      throw new ForbiddenException('You do not have access to this booking');
    }

    const amount = Number(booking.totalPrice);
    const splits = await this.calculateSplit(tenantId, amount);

    const orderId = `order_${crypto.randomBytes(8).toString('hex')}`;
    return {
      gateway: 'razorpay',
      orderId,
      amount,
      currency: 'INR',
      keyId: process.env.RAZORPAY_KEY_ID || 'dummy_key_id',
      splits,
    };
  }

  // Process payment captured webhook
  async handleWebhook(signature: string, rawBody: Buffer, payload: any) {
    const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
    if (!secret) {
      throw new BadRequestException('Webhook secret not configured');
    }
    if (!signature || !rawBody) {
      throw new BadRequestException('Missing webhook signature');
    }

    const digest = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
    const digestBuf = Buffer.from(digest, 'hex');
    const signatureBuf = Buffer.from(signature, 'hex');
    if (
      digestBuf.length !== signatureBuf.length ||
      !crypto.timingSafeEqual(digestBuf, signatureBuf)
    ) {
      throw new BadRequestException('Invalid webhook signature');
    }

    const event = payload.event;
    if (event === 'payment.captured') {
      const entity = payload.payload.payment.entity;
      const totalAmount = entity.amount / 100; // to INR
      const referenceId = entity.id;
      const notes = entity.notes || {};
      const bookingId = notes.bookingId;
      const tenantId = notes.tenantId;

      if (bookingId && tenantId) {
        const splits = await this.calculateSplit(tenantId, totalAmount);

        const payment = await this.prisma.$transaction(async (tx) => {
          // Check if payment already exists
          const existing = await tx.payment.findUnique({
            where: { referenceId },
          });
          if (existing) return null;

          const created = await tx.payment.create({
            data: {
              bookingId,
              paymentMethod: PaymentMethod.RAZORPAY,
              paymentStatus: PaymentStatus.CAPTURED,
              amount: totalAmount,
              commissionFee: splits.commissionFee,
              taxFee: splits.taxFee,
              salonCut: splits.salonCut,
              referenceId,
            },
          });

          await tx.booking.update({
            where: { id: bookingId },
            data: { status: BookingStatus.CONFIRMED },
          });

          await tx.bookingHistory.create({
            data: {
              bookingId,
              status: BookingStatus.CONFIRMED,
              notes: `Payment captured. Salon Cut: INR ${splits.salonCut}, Commission: INR ${splits.commissionFee}`,
            },
          });

          return created;
        });

        if (payment) {
          this.notificationService.notifyPaymentSuccess(payment.id).catch(() => undefined);
        }
      }
    }

    return { success: true };
  }

  // Process Refund
  async refundPayment(paymentId: string, user: { role: UserRole; tenantId?: string | null }) {
    const payment = await this.prisma.payment.findUnique({
      where: { id: paymentId },
      include: { booking: true },
    });
    if (!payment) {
      throw new NotFoundException('Payment record not found');
    }

    if (user.role !== UserRole.SUPER_ADMIN && payment.booking.tenantId !== user.tenantId) {
      throw new ForbiddenException('You do not have access to this payment');
    }

    if (payment.paymentStatus !== PaymentStatus.CAPTURED) {
      throw new BadRequestException('Only captured payments can be refunded');
    }

    return this.prisma.$transaction(async (tx) => {
      const refundRef = `ref_${crypto.randomBytes(8).toString('hex')}`;
      
      const refund = await tx.refund.create({
        data: {
          paymentId,
          amount: payment.amount,
          status: 'PROCESSED',
          referenceId: refundRef,
        },
      });

      await tx.payment.update({
        where: { id: paymentId },
        data: { paymentStatus: PaymentStatus.REFUNDED },
      });

      await tx.booking.update({
        where: { id: payment.bookingId },
        data: { status: BookingStatus.CANCELLED },
      });

      await tx.bookingHistory.create({
        data: {
          bookingId: payment.bookingId,
          status: BookingStatus.CANCELLED,
          notes: `Proportional refund processed for amount: INR ${payment.amount}`,
        },
      });

      return refund;
    });
  }
}
