import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import crypto from 'crypto';
import { SubscriptionStatus } from '@trimly/database';

@Injectable()
export class SubscriptionService {
  constructor(private prisma: PrismaService) {}

  // Ensure plans are seeded in DB
  private async seedPlansIfEmpty() {
    const count = await this.prisma.subscriptionPlan.count();
    if (count === 0) {
      await this.prisma.subscriptionPlan.createMany({
        data: [
          { name: 'Free', price: 0, branchLimit: 1, staffLimit: 2, bookingLimit: 50, storageLimitMb: 100 },
          { name: 'Starter', price: 999, branchLimit: 1, staffLimit: 5, bookingLimit: 200, storageLimitMb: 500 },
          { name: 'Professional', price: 2499, branchLimit: 3, staffLimit: 15, bookingLimit: 1000, storageLimitMb: 2048 },
          { name: 'Enterprise', price: 5999, branchLimit: 99, staffLimit: 999, bookingLimit: 99999, storageLimitMb: 10240 },
        ],
      });
    }
  }

  async getPlans() {
    await this.seedPlansIfEmpty();
    return this.prisma.subscriptionPlan.findMany({ where: { isActive: true } });
  }

  // Create checkout session (simulating Razorpay checkout details generation)
  async createCheckout(tenantId: string, planId: string) {
    const plan = await this.prisma.subscriptionPlan.findUnique({ where: { id: planId } });
    if (!plan) {
      throw new NotFoundException('Subscription plan not found');
    }

    // Generate simulated orderId or payment link from Razorpay
    const orderId = `rzp_sub_${crypto.randomBytes(8).toString('hex')}`;
    return {
      gateway: 'razorpay',
      orderId,
      amount: Number(plan.price),
      currency: 'INR',
      keyId: process.env.RAZORPAY_KEY_ID || 'dummy_key_id',
    };
  }

  // Handle incoming Razorpay Webhook
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
    if (event === 'payment.captured' || event === 'order.paid') {
      const payment = payload.payload.payment.entity;
      const amount = payment.amount / 100; // in INR
      const referenceId = payment.id;
      const notes = payment.notes || {};
      const tenantId = notes.tenantId;
      const planId = notes.planId;

      if (tenantId && planId) {
        const plan = await this.prisma.subscriptionPlan.findUnique({ where: { id: planId } });
        if (plan) {
          const startDate = new Date();
          const endDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days active

          const subscription = await this.prisma.salonSubscription.create({
            data: {
              tenantId,
              planId,
              status: SubscriptionStatus.ACTIVE,
              startDate,
              endDate,
              autoRenew: true,
            },
          });

          await this.prisma.subscriptionInvoice.create({
            data: {
              subscriptionId: subscription.id,
              invoiceNumber: `INV-${Date.now()}`,
              amount: plan.price,
              isPaid: true,
              paidAt: new Date(),
            },
          });
        }
      }
    }

    return { success: true };
  }

  // Get active subscription and check limits
  async getStatus(tenantId: string) {
    await this.seedPlansIfEmpty();
    const activeSub = await this.prisma.salonSubscription.findFirst({
      where: { tenantId, status: SubscriptionStatus.ACTIVE, endDate: { gte: new Date() } },
      include: { plan: true },
      orderBy: { createdAt: 'desc' },
    });

    if (!activeSub) {
      // Fallback to Free plan settings as default if no active paid subscription exists
      const freePlan = await this.prisma.subscriptionPlan.findFirst({ where: { name: 'Free' } });
      return {
        hasActiveSubscription: false,
        planName: 'None (Free Default)',
        limits: freePlan ? {
          branchLimit: freePlan.branchLimit,
          staffLimit: freePlan.staffLimit,
          bookingLimit: freePlan.bookingLimit,
        } : { branchLimit: 1, staffLimit: 2, bookingLimit: 50 },
      };
    }

    return {
      hasActiveSubscription: true,
      planName: activeSub.plan.name,
      endDate: activeSub.endDate,
      limits: {
        branchLimit: activeSub.plan.branchLimit,
        staffLimit: activeSub.plan.staffLimit,
        bookingLimit: activeSub.plan.bookingLimit,
      },
    };
  }

  // Limit check helper
  async checkLimit(tenantId: string, limitType: 'branch' | 'staff' | 'booking'): Promise<boolean> {
    const status = await this.getStatus(tenantId);
    if (limitType === 'branch') {
      const currentCount = await this.prisma.branch.count({ where: { tenantId, deletedAt: null } });
      return currentCount < status.limits.branchLimit;
    } else if (limitType === 'staff') {
      const currentCount = await this.prisma.staffProfile.count({ where: { tenantId } });
      return currentCount < status.limits.staffLimit;
    } else if (limitType === 'booking') {
      const currentCount = await this.prisma.booking.count({ where: { tenantId } });
      return currentCount < status.limits.bookingLimit;
    }
    return true;
  }
}
