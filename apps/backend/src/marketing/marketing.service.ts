import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CouponType } from '@trimly/database';

@Injectable()
export class MarketingService {
  constructor(private prisma: PrismaService) {}

  // Create Coupon
  async createCoupon(tenantId: string, data: any) {
    return this.prisma.coupon.create({
      data: {
        tenantId,
        code: data.code.toUpperCase(),
        type: data.type as CouponType,
        value: data.value,
        maxDiscount: data.maxDiscount || null,
        minOrderVal: data.minOrderVal || null,
        usageLimit: data.usageLimit || null,
        startDate: new Date(data.startDate),
        endDate: new Date(data.endDate),
        isActive: true,
      },
    });
  }

  // Validate Coupon code
  async validateCoupon(tenantId: string, code: string, orderAmount: number) {
    const coupon = await this.prisma.coupon.findFirst({
      where: { tenantId, code: code.toUpperCase(), isActive: true },
    });

    if (!coupon) {
      throw new NotFoundException('Coupon code is invalid or expired');
    }

    if (coupon.endDate < new Date() || coupon.startDate > new Date()) {
      throw new BadRequestException('Coupon code has expired or is not active yet');
    }

    if (coupon.usageLimit !== null && coupon.usedCount >= coupon.usageLimit) {
      throw new BadRequestException('Coupon usage limit reached');
    }

    if (coupon.minOrderVal !== null && orderAmount < Number(coupon.minOrderVal)) {
      throw new BadRequestException(`Minimum order value of INR ${coupon.minOrderVal} required`);
    }

    let discount = 0;
    if (coupon.type === CouponType.FLAT) {
      discount = Number(coupon.value);
    } else if (coupon.type === CouponType.PERCENTAGE) {
      discount = (orderAmount * Number(coupon.value)) / 100;
      if (coupon.maxDiscount !== null && discount > Number(coupon.maxDiscount)) {
        discount = Number(coupon.maxDiscount);
      }
    }

    return {
      couponId: coupon.id,
      code: coupon.code,
      discount,
      finalAmount: Math.max(0, orderAmount - discount),
    };
  }

  // List Salon Coupons
  async getCoupons(tenantId: string) {
    return this.prisma.coupon.findMany({
      where: { tenantId },
      orderBy: { endDate: 'asc' },
    });
  }

  // Create Review
  async createReview(userId: string, data: any) {
    return this.prisma.review.create({
      data: {
        userId,
        salonId: data.salonId,
        rating: data.rating,
        comment: data.comment || null,
        imageUrls: data.imageUrls || [],
      },
    });
  }

  // Reply to Review
  async createReply(reviewId: string, authorId: string, replyText: string) {
    const review = await this.prisma.review.findUnique({ where: { id: reviewId } });
    if (!review) {
      throw new NotFoundException('Review not found');
    }

    return this.prisma.reviewReply.create({
      data: {
        reviewId,
        authorId,
        replyText,
      },
    });
  }

  // Get Reviews for a Salon
  async getReviews(salonId: string) {
    return this.prisma.review.findMany({
      where: { salonId },
      include: {
        user: { select: { fullName: true, profileImageUrl: true } },
        replies: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
