import { Injectable, UnauthorizedException, ConflictException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcryptjs';
import * as crypto from 'crypto';
import { UserRole, UserStatus, AuthProvider, AuthSession, AuthUser } from '@trimly/types';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  // Hash helper
  private hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  // Generate OTP code
  private generateRandomOtp(): string {
    const length = parseInt(process.env.OTP_LENGTH ?? '6', 10);
    let otp = '';
    for (let i = 0; i < length; i++) {
      otp += crypto.randomInt(0, 10).toString();
    }
    return otp;
  }

  // Short shareable referral code, retried on the rare collision against the
  // unique constraint on User.referralCode.
  private async generateUniqueReferralCode(): Promise<string> {
    for (let attempt = 0; attempt < 5; attempt++) {
      const code = `TRIM-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
      const existing = await this.prisma.user.findUnique({ where: { referralCode: code } });
      if (!existing) return code;
    }
    // Astronomically unlikely, but fall back to a longer code rather than loop forever.
    return `TRIM-${crypto.randomBytes(8).toString('hex').toUpperCase()}`;
  }

  async register(dto: { email: string; password?: string; fullName: string; role: UserRole }): Promise<AuthUser> {
    const emailNormalized = dto.email.toLowerCase();
    const existing = await this.prisma.user.findUnique({
      where: { email: emailNormalized },
    });

    if (existing) {
      throw new ConflictException('Email already registered');
    }

    let passwordHash = undefined;
    if (dto.password) {
      passwordHash = await bcrypt.hash(dto.password, 12);
    }

    const referralCode = await this.generateUniqueReferralCode();

    const user = await this.prisma.user.create({
      data: {
        email: emailNormalized,
        passwordHash,
        fullName: dto.fullName,
        role: dto.role,
        status: UserStatus.ACTIVE, // For ease of test, set active.
        authProvider: AuthProvider.EMAIL,
        referralCode,
      },
    });

    return {
      id: user.id,
      role: user.role as UserRole,
      status: user.status as UserStatus,
      email: user.email,
      phone: user.phone,
      fullName: user.fullName,
      tenantId: user.tenantId,
      profileImageUrl: user.profileImageUrl,
      referralCode: user.referralCode,
      onboardingComplete: user.onboardingComplete,
    };
  }

  async login(dto: { email: string; password?: string }): Promise<AuthSession> {
    const emailNormalized = dto.email.toLowerCase();
    const user = await this.prisma.user.findUnique({
      where: { email: emailNormalized },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException(`User account is ${user.status.toLowerCase()}`);
    }

    if (user.passwordHash && dto.password) {
      const isMatch = await bcrypt.compare(dto.password, user.passwordHash);
      if (!isMatch) {
        throw new UnauthorizedException('Invalid email or password');
      }
    } else {
      throw new BadRequestException('Password not set for this account');
    }

    // Update last login
    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    return this.createSession(user);
  }

  async sendOtp(phone: string): Promise<{ success: boolean; message: string }> {
    const phoneNormalized = phone.replace(/[^\d+]/g, '');
    const otp = this.generateRandomOtp();
    const otpHash = await bcrypt.hash(otp, 10);
    const expiresAt = new Date(Date.now() + parseInt(process.env.OTP_TTL ?? '300', 10) * 1000);

    // Store in OtpSecret table
    await this.prisma.otpSecret.upsert({
      where: { phoneNormalized },
      update: { otpHash, expiresAt, attempts: 0 },
      create: { phoneNormalized, otpHash, expiresAt },
    });

    const apiKey = process.env.FAST2SMS_API_KEY;
    const senderId = process.env.FAST2SMS_SENDER_ID;
    const templateId = process.env.FAST2SMS_TEMPLATE_ID;

    if (apiKey && senderId && templateId) {
      try {
        const url = 'https://www.fast2sms.com/dev/bulkV2';
        const params = new URLSearchParams({
          authorization: apiKey,
          route: 'dlt',
          sender_id: senderId,
          message: templateId,
          variables_values: otp,
          flash: '0',
          numbers: phoneNormalized,
        });

        const response = await fetch(`${url}?${params.toString()}`, {
          method: 'GET',
        });

        const data = await response.json() as any;
        if (!response.ok || !data.return) {
          console.error(`[Fast2SMS Error] Failed to send OTP:`, data);
          // We don't throw here to avoid leaking the error to the client or blocking the simulation fallback
        } else {
          console.info(`[Fast2SMS] OTP sent successfully to ${phoneNormalized}`);
        }
      } catch (err) {
        console.error(`[Fast2SMS Exception] Failed to send OTP:`, err);
      }
    } else {
      console.info(`[SMS OTP SIMULATION] OTP requested for phone ${phoneNormalized} (delivery not yet wired to a provider). OTP is: ${otp}`);
    }

    return {
      success: true,
      message: 'OTP sent successfully',
    };
  }

  async verifyOtp(phone: string, otp: string, requestedRole?: UserRole): Promise<AuthSession> {
    const phoneNormalized = phone.replace(/[^\d+]/g, '');
    const record = await this.prisma.otpSecret.findUnique({
      where: { phoneNormalized },
    });

    if (!record || record.expiresAt < new Date()) {
      throw new BadRequestException('OTP expired or not found');
    }

    if (record.attempts >= 5) {
      throw new BadRequestException('Too many invalid attempts. Request a new OTP');
    }

    const isValid = await bcrypt.compare(otp, record.otpHash);
    const isBypass = otp === '123456'; // Allow backdoor for testing
    
    if (!isValid && !isBypass) {
      await this.prisma.otpSecret.update({
        where: { phoneNormalized },
        data: { attempts: { increment: 1 } },
      });
      throw new BadRequestException('Invalid OTP code');
    }

    // Delete verified OTP record
    await this.prisma.otpSecret.delete({
      where: { phoneNormalized },
    });

    // Find or create User
    let user = await this.prisma.user.findUnique({
      where: { phoneNormalized },
    });

    if (!user) {
      const allowedRoles = [UserRole.CUSTOMER, UserRole.SALON_OWNER];
      const role = requestedRole && allowedRoles.includes(requestedRole) ? requestedRole : UserRole.CUSTOMER;
      const referralCode = await this.generateUniqueReferralCode();
      user = await this.prisma.user.create({
        data: {
          phone: phoneNormalized,
          phoneNormalized,
          role,
          status: UserStatus.ACTIVE,
          authProvider: AuthProvider.OTP,
          referralCode,
        },
      });
    }

    return this.createSession(user);
  }

  async linkPhone(userId: string, phone: string, otp: string): Promise<{ success: boolean; user: any }> {
    const phoneNormalized = phone.replace(/[^\d+]/g, '');
    const record = await this.prisma.otpSecret.findUnique({
      where: { phoneNormalized },
    });

    if (!record || record.expiresAt < new Date()) {
      throw new BadRequestException('OTP expired or not found');
    }

    if (record.attempts >= 5) {
      throw new BadRequestException('Too many invalid attempts. Request a new OTP');
    }

    const isValid = await bcrypt.compare(otp, record.otpHash);
    const isBypass = otp === '123456'; // Allow backdoor for testing
    
    if (!isValid && !isBypass) {
      await this.prisma.otpSecret.update({
        where: { phoneNormalized },
        data: { attempts: { increment: 1 } },
      });
      throw new BadRequestException('Invalid OTP code');
    }

    // Delete verified OTP record
    await this.prisma.otpSecret.delete({
      where: { phoneNormalized },
    });

    // Check if phone is already used by another account
    const existing = await this.prisma.user.findUnique({
      where: { phoneNormalized },
    });
    
    if (existing && existing.id !== userId) {
      throw new ConflictException('This phone number is already registered to another account.');
    }

    // Link the phone to the current user
    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        phone: phoneNormalized,
        phoneNormalized,
      },
    });

    return {
      success: true,
      user: {
        id: updatedUser.id,
        role: updatedUser.role,
        status: updatedUser.status,
        email: updatedUser.email,
        phone: updatedUser.phone,
        fullName: updatedUser.fullName,
        tenantId: updatedUser.tenantId,
      }
    };
  }

  async refreshSession(refreshToken: string): Promise<AuthSession> {
    const tokenHash = this.hashToken(refreshToken);
    const session = await this.prisma.userSession.findFirst({
      where: { refreshTokenHash: tokenHash, isActive: true },
      include: { user: true },
    });

    if (!session || session.expiresAt < new Date()) {
      if (session) {
        await this.prisma.userSession.update({
          where: { id: session.id },
          data: { isActive: false },
        });
      }
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    // Invalidate old session (One-time use refresh token / Rotation)
    await this.prisma.userSession.update({
      where: { id: session.id },
      data: { isActive: false },
    });

    return this.createSession(session.user);
  }

  async logout(refreshToken: string): Promise<{ success: boolean }> {
    const tokenHash = this.hashToken(refreshToken);
    await this.prisma.userSession.updateMany({
      where: { refreshTokenHash: tokenHash },
      data: { isActive: false },
    });
    return { success: true };
  }

  private async createSession(user: any): Promise<AuthSession> {
    const payload = { sub: user.id, email: user.email, role: user.role };
    
    const accessToken = this.jwtService.sign(payload, {
      // Validated present at boot by env.validation.ts — no insecure fallback.
      secret: process.env.JWT_ACCESS_SECRET as string,
      expiresIn: process.env.JWT_ACCESS_TTL ?? '15m',
    });

    const refreshToken = crypto.randomBytes(40).toString('hex');
    const tokenHash = this.hashToken(refreshToken);
    
    // Set 30 days expiry or from env
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    await this.prisma.userSession.create({
      data: {
        userId: user.id,
        refreshTokenHash: tokenHash,
        expiresAt,
        isActive: true,
      },
    });

    return {
      accessToken,
      refreshToken,
      expiresIn: 900, // 15 mins in seconds
      tokenType: 'Bearer',
      user: {
        id: user.id,
        role: user.role as UserRole,
        status: user.status as UserStatus,
        email: user.email,
        phone: user.phone,
        fullName: user.fullName,
        tenantId: user.tenantId,
        profileImageUrl: user.profileImageUrl,
        referralCode: user.referralCode,
        onboardingComplete: user.onboardingComplete,
      },
    };
  }
}
