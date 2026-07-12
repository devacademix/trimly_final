import { IsEmail, IsEnum, IsNotEmpty, IsOptional, IsString, Matches, MinLength } from 'class-validator';
import { UserRole } from '@trimly/types';

const PHONE_RE = /^\+?[0-9]{7,15}$/;
const OTP_RE = /^[0-9]{4,8}$/;

export class RegisterDto {
  @IsEmail()
  email!: string;

  @IsOptional()
  @IsString()
  @MinLength(8)
  password?: string;

  @IsString()
  @IsNotEmpty()
  fullName!: string;

  @IsEnum(UserRole)
  role!: UserRole;
}

export class LoginDto {
  @IsEmail()
  email!: string;

  @IsOptional()
  @IsString()
  password?: string;
}

export class SendOtpDto {
  @IsString()
  @Matches(PHONE_RE, { message: 'phone must be a valid phone number' })
  phone!: string;
}

export class VerifyOtpDto {
  @IsString()
  @Matches(PHONE_RE, { message: 'phone must be a valid phone number' })
  phone!: string;

  @IsString()
  @Matches(OTP_RE, { message: 'otp must be a 4-8 digit code' })
  otp!: string;
}

export class RefreshTokenDto {
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;
}
