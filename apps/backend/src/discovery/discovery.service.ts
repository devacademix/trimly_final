import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DiscoveryService {
  constructor(private prisma: PrismaService) {}

  // Public salon browsing — only approved, active tenants are discoverable.
  async listSalons(search?: string) {
    const tenants = await this.prisma.tenant.findMany({
      where: {
        status: 'APPROVED',
        isActive: true,
        deletedAt: null,
        ...(search ? { name: { contains: search, mode: 'insensitive' } } : {}),
      },
      select: {
        id: true,
        name: true,
        slug: true,
        description: true,
        logoUrl: true,
        coverImageUrl: true,
        primaryCity: true,
        _count: { select: { branches: true } },
      },
      orderBy: { name: 'asc' },
    });

    // Lightweight rating rollup per salon (kept as a second query rather
    // than a join since Review.salonId isn't a declared Prisma relation).
    const ratings = await this.prisma.review.groupBy({
      by: ['salonId'],
      where: { salonId: { in: tenants.map((t) => t.id) } },
      _avg: { rating: true },
      _count: { rating: true },
    });
    const ratingMap = new Map(ratings.map((r) => [r.salonId, r]));

    return tenants.map((t) => ({
      ...t,
      rating: ratingMap.get(t.id)?._avg.rating ?? null,
      reviewCount: ratingMap.get(t.id)?._count.rating ?? 0,
    }));
  }

  async getSalonDetail(id: string) {
    const tenant = await this.prisma.tenant.findFirst({
      where: { id, status: 'APPROVED', isActive: true, deletedAt: null },
      include: {
        branches: { where: { isActive: true, deletedAt: null } },
        serviceCategories: {
          where: { deletedAt: null },
          include: { services: { where: { isActive: true, deletedAt: null } } },
        },
      },
    });
    if (!tenant) {
      throw new NotFoundException('Salon not found');
    }

    const staff = await this.prisma.staffProfile.findMany({
      where: { tenantId: id, isAvailable: true },
      include: { user: { select: { fullName: true, profileImageUrl: true } } },
    });

    // Lets a customer start a chat with the salon (POST /chat/rooms needs a
    // recipientId — the owner is the default inbox for a salon).
    const owner = await this.prisma.user.findFirst({
      where: { tenantId: id, role: 'SALON_OWNER' },
      select: { id: true },
    });

    const ratingAgg = await this.prisma.review.aggregate({
      where: { salonId: id },
      _avg: { rating: true },
      _count: { rating: true },
    });

    return {
      ...tenant,
      staff,
      ownerId: owner?.id ?? null,
      rating: ratingAgg._avg.rating ?? null,
      reviewCount: ratingAgg._count.rating,
    };
  }
}
