import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PrismaService } from '../../prisma/prisma.service';
import { UserStatus } from '@trimly/types';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private prisma: PrismaService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      // Validated present at boot by env.validation.ts — no insecure fallback.
      secretOrKey: process.env.JWT_ACCESS_SECRET as string,
    });
  }

  async validate(payload: any) {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        email: true,
        phone: true,
        fullName: true,
        role: true,
        status: true,
        tenantId: true,
        profileImageUrl: true,
        referralCode: true,
        onboardingComplete: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException('User not found or deleted');
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException(`User is inactive or ${user.status.toLowerCase()}`);
    }

    return user;
  }
}
