import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SubscriptionService } from '../subscription/subscription.service';
import { UserRole, UserStatus, AuthProvider, Gender } from '@trimly/database';

@Injectable()
export class SalonService {
  constructor(
    private prisma: PrismaService,
    private subService: SubscriptionService,
  ) {}

  // Get Salon business profile details
  async getProfile(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantId },
      include: { workingHours: true },
    });
    if (!tenant) {
      throw new NotFoundException('Salon business profile not found');
    }
    return tenant;
  }

  // Update business profile details
  async updateProfile(tenantId: string, data: any) {
    return this.prisma.tenant.update({
      where: { id: tenantId },
      data: {
        name: data.name,
        legalName: data.legalName,
        description: data.description,
        gstNumber: data.gstNumber,
        panNumber: data.panNumber,
        ownerEmail: data.ownerEmail,
        ownerPhone: data.ownerPhone,
        logoUrl: data.logoUrl,
        coverImageUrl: data.coverImageUrl,
        websiteUrl: data.websiteUrl,
        fullAddress: data.fullAddress,
        area: data.area,
        state: data.state,
        primaryCity: data.primaryCity,
        primaryCountry: data.primaryCountry,
        timezone: data.timezone,
      },
    });
  }

  // Get Salon branches
  async getBranches(tenantId: string) {
    return this.prisma.branch.findMany({
      where: { tenantId, deletedAt: null },
    });
  }

  // Create branch with limits check
  async createBranch(tenantId: string, data: any) {
    const isAllowed = await this.subService.checkLimit(tenantId, 'branch');
    if (!isAllowed) {
      throw new BadRequestException('Branch limit reached for current subscription plan. Upgrade to add more branches.');
    }

    return this.prisma.branch.create({
      data: {
        tenantId,
        name: data.name,
        address: data.address,
        latitude: data.latitude,
        longitude: data.longitude,
        phone: data.phone,
        email: data.email,
        isActive: true,
      },
    });
  }

  // List Salon staff profiles
  async getStaff(tenantId: string) {
    return this.prisma.staffProfile.findMany({
      where: { tenantId },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            phone: true,
            fullName: true,
            status: true,
          },
        },
      },
    });
  }

  // Invite / Recruit Staff (checks limits)
  async recruitStaff(tenantId: string, data: any) {
    const isAllowed = await this.subService.checkLimit(tenantId, 'staff');
    if (!isAllowed) {
      throw new BadRequestException('Staff limit reached for current subscription plan. Upgrade to add more staff.');
    }

    const emailNormalized = data.email.toLowerCase();
    const existing = await this.prisma.user.findUnique({ where: { email: emailNormalized } });

    if (existing) {
      throw new BadRequestException('Email already registered');
    }

    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          email: emailNormalized,
          fullName: data.fullName,
          role: UserRole.STAFF,
          status: UserStatus.ACTIVE,
          authProvider: AuthProvider.EMAIL,
          tenantId,
        },
      });

      const staff = await tx.staffProfile.create({
        data: {
          userId: user.id,
          tenantId,
          bio: data.bio,
          specialities: data.specialities || [],
        },
      });

      return { user, staff };
    });
  }

  // Manage categories
  async getCategories(tenantId: string) {
    return this.prisma.serviceCategory.findMany({
      where: { tenantId, deletedAt: null },
    });
  }

  async createCategory(tenantId: string, name: string, description?: string) {
    return this.prisma.serviceCategory.create({
      data: { tenantId, name, description },
    });
  }

  // Manage services
  async getServices(tenantId: string) {
    return this.prisma.service.findMany({
      where: { tenantId, deletedAt: null },
      include: { category: true },
    });
  }

  async createService(tenantId: string, data: any) {
    return this.prisma.service.create({
      data: {
        tenantId,
        categoryId: data.categoryId,
        name: data.name,
        description: data.description,
        price: data.price,
        duration: data.duration,
        gender: data.gender || Gender.OTHER,
        isActive: true,
        imageUrl: data.imageUrl,
      },
    });
  }

  // Distinct customers who have booked with this tenant, with visit counts.
  async getCustomers(tenantId: string) {
    const bookings = await this.prisma.booking.findMany({
      where: { tenantId },
      select: {
        customerId: true,
        startTime: true,
        customer: {
          select: { id: true, fullName: true, email: true, phone: true, profileImageUrl: true },
        },
      },
      orderBy: { startTime: 'desc' },
    });

    const byCustomer = new Map<string, { customer: (typeof bookings)[number]['customer']; visits: number; lastVisit: Date }>();
    for (const b of bookings) {
      const existing = byCustomer.get(b.customerId);
      if (!existing) {
        byCustomer.set(b.customerId, { customer: b.customer, visits: 1, lastVisit: b.startTime });
      } else {
        existing.visits += 1;
        if (b.startTime > existing.lastVisit) existing.lastVisit = b.startTime;
      }
    }

    return Array.from(byCustomer.values())
      .sort((a, b) => b.lastVisit.getTime() - a.lastVisit.getTime())
      .map((entry) => ({ ...entry.customer, visits: entry.visits, lastVisit: entry.lastVisit }));
  }

  // Setup operational working hours
  async setupSchedules(tenantId: string, schedules: any[]) {
    return this.prisma.$transaction(
      schedules.map((s) =>
        this.prisma.workingHours.upsert({
          where: { tenantId_dayOfWeek: { tenantId, dayOfWeek: s.dayOfWeek } },
          update: { openTime: s.openTime, closeTime: s.closeTime, isOpen: s.isOpen },
          create: { tenantId, dayOfWeek: s.dayOfWeek, openTime: s.openTime, closeTime: s.closeTime, isOpen: s.isOpen },
        }),
      ),
    );
  }

  // Toggle shop open/closed status
  async updateShopStatus(tenantId: string, isOpen: boolean) {
    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: { status: isOpen ? 'ACTIVE' : 'TEMPORARILY_CLOSED' },
    });
    return isOpen ? 'ACTIVE' : 'TEMPORARILY_CLOSED';
  }

  // Update a service
  async updateService(tenantId: string, serviceId: string, data: any) {
    return this.prisma.service.update({
      where: { id: serviceId, tenantId },
      data: {
        name: data.name,
        description: data.description,
        price: data.price,
        duration: data.duration,
        categoryId: data.categoryId,
        imageUrl: data.imageUrl,
        isActive: data.isActive,
      },
      include: { category: true },
    });
  }

  // Soft delete a service
  async deleteService(tenantId: string, serviceId: string) {
    return this.prisma.service.update({
      where: { id: serviceId, tenantId },
      data: { deletedAt: new Date() },
    });
  }

  // Toggle staff active status
  async updateStaffStatus(tenantId: string, staffId: string, isActive: boolean) {
    return this.prisma.staffProfile.update({
      where: { id: staffId, tenantId },
      data: { isAvailable: isActive },
    });
  }
}
