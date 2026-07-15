import { Injectable, BadRequestException, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthService } from '../auth/auth.service';
import { SubscriptionService } from '../subscription/subscription.service';
import { SubscriptionStatus } from '@trimly/database';
import { UserRole, UserStatus, AuthProvider, BusinessCategory, OnboardingStep, KycStatus } from '@trimly/database';
import * as bcrypt from 'bcryptjs';
import * as crypto from 'crypto';

@Injectable()
export class OnboardingService {
  constructor(
    private prisma: PrismaService,
    private authService: AuthService,
    private subService: SubscriptionService,
  ) { }

  async getStatus(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { tenant: true },
    });
    if (!user) throw new NotFoundException('User not found');
    return {
      onboardingStep: user.tenant?.onboardingStep || OnboardingStep.WELCOME,
      tenantId: user.tenantId,
      tenant: user.tenant,
    };
  }

  // Step 2: Mobile Verification — We use existing auth OTP endpoints.
  // Step 3: Basic Info — create user with SALON_OWNER role + tenant
  async basicInfo(dto: {
    userId: string;
    ownerName: string;
    salonName: string;
    email: string;
    businessCategory: BusinessCategory;
  }) {
    const emailNormalized = dto.email.toLowerCase();

    let user = await this.prisma.user.findUnique({ where: { id: dto.userId } });
    if (!user) throw new BadRequestException('User not found.');

    if (user.role !== UserRole.SALON_OWNER) {
      await this.prisma.user.update({
        where: { id: user.id },
        data: { role: UserRole.SALON_OWNER },
      });
    }

    const emailExists = await this.prisma.user.findUnique({ where: { email: emailNormalized } });
    if (emailExists && emailExists.id !== user.id) {
      throw new ConflictException('Email already registered');
    }

    // Generate unique slug
    const slugBase = dto.salonName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
    const slug = await this.generateUniqueSlug(slugBase);

    const tenant = await this.prisma.tenant.create({
      data: {
        slug,
        name: dto.salonName,
        businessCategory: dto.businessCategory,
        ownerEmail: emailNormalized,
        ownerPhone: user.phone || user.phoneNormalized || '',
        onboardingStep: OnboardingStep.BASIC_INFO,
      },
    });

    user = await this.prisma.user.update({
      where: { id: user.id },
      data: {
        email: emailNormalized,
        fullName: dto.ownerName,
        tenantId: tenant.id,
        status: UserStatus.ACTIVE,
      },
    });

    // Create salon wallet
    await this.prisma.wallet.create({
      data: { tenantId: tenant.id, type: 'SALON' as any },
    });

    return {
      success: true,
      data: { tenantId: tenant.id, onboardingStep: OnboardingStep.BASIC_INFO },
    };
  }

  // Step 4: Business Location
  async location(tenantId: string, dto: {
    country: string; state: string; city: string;
    area: string; fullAddress: string;
    latitude?: number; longitude?: number;
  }) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException('Tenant not found');

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: {
        country: dto.country,
        state: dto.state,
        primaryCity: dto.city,
        area: dto.area,
        fullAddress: dto.fullAddress,
        latitude: dto.latitude,
        longitude: dto.longitude,
        onboardingStep: OnboardingStep.LOCATION,
      },
    });

    // Auto-create primary branch
    await this.prisma.branch.create({
      data: {
        tenantId,
        name: 'Main Branch',
        address: dto.fullAddress,
        latitude: dto.latitude,
        longitude: dto.longitude,
        isActive: true,
      },
    });

    return { success: true, data: { onboardingStep: OnboardingStep.LOCATION } };
  }

  // Step 5: Business Details
  async details(tenantId: string, dto: {
    gstNumber?: string; panNumber?: string;
    businessRegNumber?: string; description?: string;
  }) {
    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: {
        gstNumber: dto.gstNumber,
        panNumber: dto.panNumber,
        businessRegNumber: dto.businessRegNumber,
        description: dto.description,
        onboardingStep: OnboardingStep.DETAILS,
      },
    });
    return { success: true, data: { onboardingStep: OnboardingStep.DETAILS } };
  }

  // Step 6: Business Timing
  async timing(tenantId: string, schedules: any[], breaks: any[], holidays: any[]) {
    // Upsert schedules
    for (const s of schedules) {
      await this.prisma.workingHours.upsert({
        where: { tenantId_dayOfWeek: { tenantId, dayOfWeek: s.dayOfWeek } },
        update: { openTime: s.openTime, closeTime: s.closeTime, isOpen: s.isOpen },
        create: { tenantId, dayOfWeek: s.dayOfWeek, openTime: s.openTime, closeTime: s.closeTime, isOpen: s.isOpen },
      });
    }

    // Delete old breaks and re-create
    if (breaks && breaks.length > 0) {
      await this.prisma.breakHours.deleteMany({ where: { tenantId } });
      await this.prisma.breakHours.createMany({
        data: breaks.map(b => ({ tenantId, ...b })),
      });
    }

    // Add holidays
    if (holidays && holidays.length > 0) {
      for (const h of holidays) {
        await this.prisma.holiday.upsert({
          where: { tenantId_date: { tenantId, date: new Date(h.date) } },
          update: { description: h.description },
          create: { tenantId, date: new Date(h.date), description: h.description },
        });
      }
    }

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: { onboardingStep: OnboardingStep.TIMING },
    });

    return { success: true, data: { onboardingStep: OnboardingStep.TIMING } };
  }

  // Step 7: Upload Photos
  async savePhotos(tenantId: string, data: {
    logoUrl?: string; coverImageUrl?: string;
    gallery?: { url: string; mediaType: string }[];
  }) {
    const updateData: any = { onboardingStep: OnboardingStep.PHOTOS };
    if (data.logoUrl) updateData.logoUrl = data.logoUrl;
    if (data.coverImageUrl) updateData.coverImageUrl = data.coverImageUrl;

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: updateData,
    });

    if (data.gallery && data.gallery.length > 0) {
      await this.prisma.tenantGallery.createMany({
        data: data.gallery.map((g, i) => ({
          tenantId,
          url: g.url,
          mediaType: g.mediaType || 'IMAGE',
          sortOrder: i,
        })),
      });
    }

    return { success: true, data: { onboardingStep: OnboardingStep.PHOTOS } };
  }

  // Step 8: Services
  async addServices(tenantId: string, services: any[]) {
    const results = [];
    for (const svc of services) {
      let categoryId = svc.categoryId;
      if (!categoryId && svc.categoryName) {
        const cat = await this.prisma.serviceCategory.upsert({
          where: { tenantId_name: { tenantId, name: svc.categoryName } },
          update: {},
          create: { tenantId, name: svc.categoryName },
        });
        categoryId = cat.id;
      }
      if (!categoryId) throw new BadRequestException('categoryId or categoryName is required');

      const service = await this.prisma.service.create({
        data: {
          tenantId,
          categoryId,
          name: svc.name,
          description: svc.description,
          price: svc.price,
          duration: svc.duration,
          gender: svc.gender || 'OTHER',
          isActive: true,
          imageUrl: svc.imageUrl,
        },
      });
      results.push(service);
    }

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: { onboardingStep: OnboardingStep.SERVICES },
    });

    return { success: true, data: { services: results, onboardingStep: OnboardingStep.SERVICES } };
  }

  // Step 9: Staff
  async addStaff(tenantId: string, staffList: any[]) {
    const results = [];
    for (const s of staffList) {
      const phoneNormalized = s.phone.replace(/[^\d+]/g, '');

      let user = await this.prisma.user.findUnique({ where: { phoneNormalized } });
      if (!user) {
        const referralCode = `TRIM-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
        user = await this.prisma.user.create({
          data: {
            phone: s.phone,
            phoneNormalized,
            fullName: s.fullName,
            email: s.email,
            role: UserRole.STAFF,
            status: UserStatus.ACTIVE,
            authProvider: AuthProvider.OTP,
            tenantId,
            referralCode,
          },
        });
      }

      const staff = await this.prisma.staffProfile.create({
        data: {
          userId: user.id,
          tenantId,
          bio: s.designation,
          specialities: s.assignedServiceIds || [],
          isAvailable: true,
        },
      });

      if (s.workingHours && s.workingHours.length > 0) {
        for (const wh of s.workingHours) {
          await this.prisma.staffAvailability.upsert({
            where: { staffId_dayOfWeek: { staffId: staff.id, dayOfWeek: wh.dayOfWeek } },
            update: { startTime: wh.openTime, endTime: wh.closeTime, isOpen: wh.isOpen },
            create: {
              staffId: staff.id,
              dayOfWeek: wh.dayOfWeek,
              startTime: wh.openTime,
              endTime: wh.closeTime,
              isOpen: wh.isOpen,
            },
          });
        }
      }

      results.push({ user, staff });
    }

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: { onboardingStep: OnboardingStep.STAFF },
    });

    return { success: true, data: { staffCount: results.length, onboardingStep: OnboardingStep.STAFF } };
  }

  // Step 10: Bank Details
  async bankDetails(tenantId: string, dto: {
    accountHolder: string; bankName: string;
    accountNumber: string; ifsc: string; upiId?: string;
  }) {
    await this.prisma.bankDetail.upsert({
      where: { tenantId },
      update: dto,
      create: { tenantId, ...dto },
    });

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: { onboardingStep: OnboardingStep.BANK },
    });

    return { success: true, data: { onboardingStep: OnboardingStep.BANK } };
  }

  // Step 11: KYC Upload
  async saveKycDocument(tenantId: string, documentType: string, fileUrl: string) {
    const doc = await this.prisma.kycDocument.create({
      data: {
        tenantId,
        documentType: documentType as any,
        fileUrl,
        status: KycStatus.PENDING,
      },
    });

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: {
        kycStatus: KycStatus.PENDING,
        onboardingStep: OnboardingStep.KYC,
      },
    });

    return { success: true, data: doc };
  }

  // Step 12: Subscription
  async subscribe(tenantId: string, planId: string) {
    const plan = await this.prisma.subscriptionPlan.findUnique({ where: { id: planId } });
    if (!plan) throw new NotFoundException('Subscription plan not found');

    if (Number(plan.price) === 0) {
      // Free plan - activate immediately
      const startDate = new Date();
      const endDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
      await this.prisma.salonSubscription.create({
        data: {
          tenantId,
          planId,
          status: 'ACTIVE' as any,
          startDate,
          endDate,
          autoRenew: true,
        },
      });

      await this.prisma.tenant.update({
        where: { id: tenantId },
        data: { onboardingStep: OnboardingStep.SUBSCRIPTION },
      });

      return { success: true, data: { plan: plan.name, isFree: true, onboardingStep: OnboardingStep.SUBSCRIPTION } };
    }

    // Paid plan - create Razorpay checkout
    const orderId = `rzp_sub_${crypto.randomBytes(8).toString('hex')}`;
    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: { onboardingStep: OnboardingStep.SUBSCRIPTION },
    });

    return {
      success: true,
      data: {
        gateway: 'razorpay',
        orderId,
        amount: Number(plan.price),
        currency: 'INR',
        planId,
        planName: plan.name,
        keyId: process.env.RAZORPAY_KEY_ID || 'rzp_test_dummy',
        tenantId,
      },
    };
  }

  // Step 14: Complete Onboarding
  async complete(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException('Tenant not found');

    const activeSub = await this.prisma.salonSubscription.findFirst({
      where: { tenantId, status: 'ACTIVE' },
    });
    if (!activeSub) {
      throw new BadRequestException('An active subscription is required to complete onboarding.');
    }

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: {
        onboardingStep: OnboardingStep.COMPLETED,
        status: 'PENDING_APPROVAL',
      },
    });

    return {
      success: true,
      data: {
        message: 'Onboarding completed. Your salon is pending admin approval.',
        status: 'PENDING_APPROVAL',
      },
    };
  }

  async getPlans() {
    return this.subService.getPlans();
  }

  async subscriptionWebhook(signature: string, rawBody: Buffer, payload: any) {
    const event = payload.event;
    if (event === 'payment.captured' || event === 'order.paid') {
      const payment = payload.payload.payment?.entity || payload.payload.order?.entity;
      const notes = payment.notes || {};
      const tenantId = notes.tenantId;
      const planId = notes.planId;

      if (tenantId && planId) {
        const plan = await this.prisma.subscriptionPlan.findUnique({ where: { id: planId } });
        if (plan) {
          const startDate = new Date();
          const endDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
          await this.prisma.salonSubscription.create({
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
              subscriptionId: '', // will be updated after creation
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

  private async generateUniqueSlug(base: string): Promise<string> {
    const candidate = base || 'salon';
    const existing = await this.prisma.tenant.findUnique({ where: { slug: candidate } });
    if (!existing) return candidate;
    for (let i = 1; i < 100; i++) {
      const slug = `${candidate}-${i}`;
      const exists = await this.prisma.tenant.findUnique({ where: { slug } });
      if (!exists) return slug;
    }
    return `${candidate}-${crypto.randomBytes(4).toString('hex')}`;
  }

  async completeCustomerOnboarding(userId: string, dto: any) {
    const data: any = {
      onboardingComplete: true,
    };
    if (dto.interests !== undefined) data.interests = dto.interests;
    if (dto.locationAllowed !== undefined) data.locationAllowed = dto.locationAllowed;
    if (dto.notificationsAllowed !== undefined) data.notificationsAllowed = dto.notificationsAllowed;
    if (dto.referralCode !== undefined) data.referralCode = dto.referralCode;
    if (dto.firstName !== undefined) data.firstName = dto.firstName;
    if (dto.lastName !== undefined) data.lastName = dto.lastName;
    if (dto.fullName !== undefined) data.fullName = dto.fullName;
    if (dto.dateOfBirth !== undefined) data.dateOfBirth = new Date(dto.dateOfBirth);
    if (dto.gender !== undefined) data.gender = dto.gender;

    // Check referral code if provided
    if (dto.referralCode) {
      const referrer = await this.prisma.user.findUnique({ where: { referralCode: dto.referralCode } });
      if (referrer) {
        data.referredById = referrer.id;
      }
    }

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data,
    });

    return updatedUser;
  }
}
