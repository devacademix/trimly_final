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
        bankDetails: true,
        kycDocuments: true,
        services: {
          include: { category: true }
        },
        workingHours: true,
        holidays: true,
        branches: true,
        users: {
          include: {
            staffProfile: true
          }
        }
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

  // Hard-delete a salon/tenant from database
  async deleteSalon(id: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id } });
    if (!tenant) {
      throw new NotFoundException('Salon/tenant not found');
    }

    return this.prisma.$transaction(async (tx) => {
      // 1. Audit logs
      await tx.auditLog.deleteMany({ where: { tenantId: id } });

      // 2. Chat messages, participants, rooms (handled by cascade when Users are deleted)
      // 3. Expenses
      await tx.expense.deleteMany({ where: { tenantId: id } });

      // 4. Subscriptions & invoices
      const subs = await tx.salonSubscription.findMany({ where: { tenantId: id }, select: { id: true } });
      const subIds = subs.map(s => s.id);
      if (subIds.length > 0) {
        await tx.subscriptionInvoice.deleteMany({ where: { subscriptionId: { in: subIds } } });
        await tx.salonSubscription.deleteMany({ where: { id: { in: subIds } } });
      }

      // 5. Bank detail & KYC
      await tx.bankDetail.deleteMany({ where: { tenantId: id } });
      await tx.kycDocument.deleteMany({ where: { tenantId: id } });
      await tx.tenantGallery.deleteMany({ where: { tenantId: id } });

      // 6. Memberships
      const memberships = await tx.membership.findMany({ where: { tenantId: id }, select: { id: true } });
      const membershipIds = memberships.map(m => m.id);
      if (membershipIds.length > 0) {
        await tx.userMembership.deleteMany({ where: { membershipId: { in: membershipIds } } });
        await tx.membership.deleteMany({ where: { id: { in: membershipIds } } });
      }

      // 7. Coupons
      const coupons = await tx.coupon.findMany({ where: { tenantId: id }, select: { id: true } });
      const couponIds = coupons.map(c => c.id);
      if (couponIds.length > 0) {
        await tx.couponUsage.deleteMany({ where: { couponId: { in: couponIds } } });
        await tx.coupon.deleteMany({ where: { id: { in: couponIds } } });
      }

      // 8. Inventory & Products
      const products = await tx.product.findMany({ where: { tenantId: id }, select: { id: true } });
      const productIds = products.map(p => p.id);
      if (productIds.length > 0) {
        await tx.inventoryMovement.deleteMany({ where: { productId: { in: productIds } } });
        await tx.product.deleteMany({ where: { id: { in: productIds } } });
      }
      await tx.productCategory.deleteMany({ where: { tenantId: id } });

      // 9. Staff details, Payroll, Availabilities, leaves
      const staffProfiles = await tx.staffProfile.findMany({ where: { tenantId: id }, select: { id: true } });
      const staffIds = staffProfiles.map(s => s.id);
      if (staffIds.length > 0) {
        await tx.payrollRecord.deleteMany({ where: { staffId: { in: staffIds } } });
        await tx.staffAvailability.deleteMany({ where: { staffId: { in: staffIds } } });
        await tx.staffLeave.deleteMany({ where: { staffId: { in: staffIds } } });
        await tx.staffProfile.deleteMany({ where: { id: { in: staffIds } } });
      }

      // 10. Services & Categories & Packages
      const services = await tx.service.findMany({ where: { tenantId: id }, select: { id: true } });
      const serviceIds = services.map(s => s.id);
      
      const packages = await tx.servicePackage.findMany({ where: { tenantId: id }, select: { id: true } });
      const packageIds = packages.map(p => p.id);
      if (packageIds.length > 0) {
        await tx.servicePackageItem.deleteMany({ where: { packageId: { in: packageIds } } });
        await tx.servicePackage.deleteMany({ where: { id: { in: packageIds } } });
      }

      if (serviceIds.length > 0) {
        await tx.service.deleteMany({ where: { id: { in: serviceIds } } });
      }
      await tx.serviceCategory.deleteMany({ where: { tenantId: id } });

      // 11. Bookings & items & histories & payments & refunds
      const bookings = await tx.booking.findMany({ where: { tenantId: id }, select: { id: true } });
      const bookingIds = bookings.map(b => b.id);
      if (bookingIds.length > 0) {
        await tx.bookingHistory.deleteMany({ where: { bookingId: { in: bookingIds } } });
        await tx.bookingItem.deleteMany({ where: { bookingId: { in: bookingIds } } });
        
        const payments = await tx.payment.findMany({ where: { bookingId: { in: bookingIds } }, select: { id: true } });
        const paymentIds = payments.map(p => p.id);
        if (paymentIds.length > 0) {
          await tx.refund.deleteMany({ where: { paymentId: { in: paymentIds } } });
          await tx.payment.deleteMany({ where: { id: { in: paymentIds } } });
        }
        await tx.booking.deleteMany({ where: { id: { in: bookingIds } } });
      }
      await tx.waitingList.deleteMany({ where: { tenantId: id } });

      // 12. Working hours, holidays
      await tx.breakHours.deleteMany({ where: { tenantId: id } });
      await tx.workingHours.deleteMany({ where: { tenantId: id } });
      await tx.holiday.deleteMany({ where: { tenantId: id } });
      // SalonGallery is cascade deleted when branches are deleted

      // 13. Settlements & Wallets
      const wallets = await tx.wallet.findMany({ where: { tenantId: id }, select: { id: true } });
      const walletIds = wallets.map(w => w.id);
      if (walletIds.length > 0) {
        await tx.walletTransaction.deleteMany({ where: { walletId: { in: walletIds } } });
        await tx.wallet.deleteMany({ where: { id: { in: walletIds } } });
      }
      await tx.settlement.deleteMany({ where: { tenantId: id } });

      // 14. Branches
      await tx.branch.deleteMany({ where: { tenantId: id } });

      // 15. Otp secrets, sessions, favorites and Users of this tenant
      const users = await tx.user.findMany({ where: { tenantId: id }, select: { id: true, phoneNormalized: true } });
      const userIds = users.map(u => u.id);
      const userPhones = users.map(u => u.phoneNormalized).filter(Boolean) as string[];
      
      if (userPhones.length > 0) {
        await tx.otpSecret.deleteMany({ where: { phoneNormalized: { in: userPhones } } });
      }

      if (userIds.length > 0) {
        await tx.userSession.deleteMany({ where: { userId: { in: userIds } } });
        await tx.customerFavorite.deleteMany({ where: { userId: { in: userIds } } });
        await tx.reviewReply.deleteMany({ where: { authorId: { in: userIds } } });
        await tx.review.deleteMany({ where: { userId: { in: userIds } } });
        await tx.user.deleteMany({ where: { id: { in: userIds } } });
      }

      // 16. Finally, delete the Tenant itself
      return tx.tenant.delete({ where: { id } });
    });
  }

  // Update user status
  async updateUserStatus(id: string, status: any) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return this.prisma.user.update({
      where: { id },
      data: { status },
    });
  }

  // Update user role
  async updateUserRole(id: string, role: any) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return this.prisma.user.update({
      where: { id },
      data: { role },
    });
  }

  // Hard-delete a user from database
  async deleteUser(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    return this.prisma.$transaction(async (tx) => {
      // 1. Delete OTP, Sessions, Favorites
      if (user.phoneNormalized) {
        await tx.otpSecret.deleteMany({ where: { phoneNormalized: user.phoneNormalized } });
      }
      await tx.userSession.deleteMany({ where: { userId: id } });
      await tx.customerFavorite.deleteMany({ where: { userId: id } });

      // 2. Delete Reviews & replies
      await tx.reviewReply.deleteMany({ where: { authorId: id } });
      await tx.review.deleteMany({ where: { userId: id } });

      // 3. Delete Staff Profile relations
      const staff = await tx.staffProfile.findUnique({ where: { userId: id }, select: { id: true } });
      if (staff) {
        await tx.payrollRecord.deleteMany({ where: { staffId: staff.id } });
        await tx.staffAvailability.deleteMany({ where: { staffId: staff.id } });
        await tx.staffLeave.deleteMany({ where: { staffId: staff.id } });
        await tx.staffProfile.delete({ where: { id: staff.id } });
      }

      // 4. Finally delete the user
      return tx.user.delete({ where: { id } });
    });
  }
}
