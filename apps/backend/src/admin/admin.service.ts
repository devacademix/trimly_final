import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UserRole } from '@trimly/types';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  // List all salons (tenants)
  async getSalons() {
    return this.prisma.tenant.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        _count: {
          select: { users: true, branches: true, bookings: true },
        },
      },
    });
  }

  // Update salon status (approve/suspend/etc.)
  async updateSalonStatus(id: string, status: string, isActive: boolean) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id } });
    if (!tenant) {
      throw new NotFoundException('Salon/tenant not found');
    }

    return this.prisma.tenant.update({
      where: { id },
      data: { status, isActive },
    });
  }

  // Set per-salon commission override
  async updateSalonCommission(id: string, commissionPct: number) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id } });
    if (!tenant) {
      throw new NotFoundException('Salon/tenant not found');
    }

    return this.prisma.tenant.update({
      where: { id },
      data: { commissionPct },
    });
  }

  // List all users
  async getUsers(role?: UserRole) {
    return this.prisma.user.findMany({
      where: role ? { role } : {},
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        phone: true,
        fullName: true,
        role: true,
        status: true,
        tenantId: true,
        createdAt: true,
      },
    });
  }

  // List all bookings
  async getBookings() {
    return this.prisma.booking.findMany({
      orderBy: { startTime: 'desc' },
      include: {
        tenant: { select: { name: true } },
        customer: { select: { fullName: true, email: true } },
      },
    });
  }

  // Set global default commission
  async setGlobalCommission(pct: number) {
    return this.prisma.setting.upsert({
      where: { key: 'platform.defaultCommissionPct' },
      update: { value: pct },
      create: { key: 'platform.defaultCommissionPct', value: pct },
    });
  }

  // Get global revenue statistics
  async getRevenueStats() {
    const payments = await this.prisma.payment.findMany({
      where: { paymentStatus: 'CAPTURED' },
    });

    let totalVolume = 0;
    let totalPlatformCommission = 0;
    let totalSalonRevenue = 0;

    for (const p of payments) {
      totalVolume += Number(p.amount);
      totalPlatformCommission += Number(p.commissionFee);
      totalSalonRevenue += Number(p.salonCut);
    }

    const salonCount = await this.prisma.tenant.count({ where: { isActive: true } });
    const bookingCount = await this.prisma.booking.count();

    return {
      totalVolume,
      totalPlatformCommission,
      totalSalonRevenue,
      salonCount,
      bookingCount,
    };
  }
}
