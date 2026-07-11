import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AnalyticsService {
  constructor(private prisma: PrismaService) {}

  // Dashboard Overview Metrics for Salon Owners
  async getDashboardStats(tenantId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);

    const todayBookingsCount = await this.prisma.booking.count({
      where: { tenantId, startTime: { gte: today } },
    });

    const monthlyBookingsCount = await this.prisma.booking.count({
      where: { tenantId, startTime: { gte: startOfMonth } },
    });

    // Calculate monthly revenue from captured payments
    const payments = await this.prisma.payment.findMany({
      where: {
        booking: { tenantId },
        paymentStatus: 'CAPTURED',
        createdAt: { gte: startOfMonth },
      },
      select: { amount: true, salonCut: true },
    });

    let totalVolume = 0;
    let salonRevenue = 0;

    for (const p of payments) {
      totalVolume += Number(p.amount);
      salonRevenue += Number(p.salonCut);
    }

    const averageOrderValue = payments.length > 0 ? totalVolume / payments.length : 0.0;

    return {
      todayBookingsCount,
      monthlyBookingsCount,
      totalVolume,
      salonRevenue,
      averageOrderValue,
    };
  }

  // Peak operational hours calculations
  async getPeakHours(tenantId: string) {
    const bookings = await this.prisma.booking.findMany({
      where: { tenantId },
      select: { startTime: true },
    });

    const hourCounts: Record<number, number> = {};
    for (let i = 8; i < 22; i++) {
      hourCounts[i] = 0;
    }

    for (const b of bookings) {
      const hour = b.startTime.getHours();
      if (hourCounts[hour] !== undefined) {
        hourCounts[hour]++;
      }
    }

    return Object.entries(hourCounts).map(([hour, count]) => ({
      hour: parseInt(hour, 10),
      label: `${hour.padStart(2, '0')}:00`,
      count,
    }));
  }

  // Top Performing Services
  async getTopServices(tenantId: string) {
    const bookingItems = await this.prisma.bookingItem.findMany({
      where: { booking: { tenantId } },
      include: { service: true },
    });

    const serviceMap: Record<string, { name: string; count: number; revenue: number }> = {};

    for (const item of bookingItems) {
      const s = item.service;
      if (!serviceMap[s.id]) {
        serviceMap[s.id] = { name: s.name, count: 0, revenue: 0 };
      }
      const data = serviceMap[s.id];
      if (data) {
        data.count++;
        data.revenue += Number(item.price);
      }
    }

    return Object.values(serviceMap)
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);
  }

  // Platform Subscriptions Growth (Super Admin Only)
  async getAdminSubscriptionStats() {
    const totalSubscriptions = await this.prisma.salonSubscription.count();
    const activeSubscriptions = await this.prisma.salonSubscription.count({
      where: { status: 'ACTIVE' },
    });

    const payments = await this.prisma.subscriptionInvoice.findMany({
      where: { isPaid: true },
      select: { amount: true },
    });

    let totalVolume = 0;
    for (const p of payments) {
      totalVolume += Number(p.amount);
    }

    return {
      totalSubscriptions,
      activeSubscriptions,
      totalVolume,
    };
  }
}
