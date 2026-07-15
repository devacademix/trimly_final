import { Type } from 'class-transformer';
import {
  IsArray, IsBoolean, IsEmail, IsEnum, IsInt, IsLatitude, IsLongitude,
  IsNotEmpty, IsNumber, IsOptional, IsPositive, IsString,
  Matches, Max, Min, ValidateNested, ArrayMinSize, IsUUID, MinLength,
} from 'class-validator';
import { BusinessCategory, Gender, DocumentType } from '@trimly/database';

const TIME_RE = /^([01]\d|2[0-3]):[0-5]\d$/;

export class BasicInfoDto {
  @IsString()
  @IsNotEmpty()
  ownerName!: string;

  @IsString()
  @IsNotEmpty()
  salonName!: string;

  @IsEmail()
  email!: string;

  @IsEnum(BusinessCategory)
  businessCategory!: BusinessCategory;
}

export class LocationDto {
  @IsString()
  @IsNotEmpty()
  country!: string;

  @IsString()
  @IsNotEmpty()
  state!: string;

  @IsString()
  @IsNotEmpty()
  city!: string;

  @IsString()
  @IsNotEmpty()
  area!: string;

  @IsString()
  @IsNotEmpty()
  fullAddress!: string;

  @IsOptional()
  @IsLatitude()
  latitude?: number;

  @IsOptional()
  @IsLongitude()
  longitude?: number;
}

export class BusinessDetailsDto {
  @IsOptional()
  @IsString()
  gstNumber?: string;

  @IsOptional()
  @IsString()
  panNumber?: string;

  @IsOptional()
  @IsString()
  businessRegNumber?: string;

  @IsOptional()
  @IsString()
  description?: string;
}

export class ScheduleItemDto {
  @IsInt()
  @Min(0)
  @Max(6)
  dayOfWeek!: number;

  @Matches(TIME_RE, { message: 'openTime must be HH:MM' })
  openTime!: string;

  @Matches(TIME_RE, { message: 'closeTime must be HH:MM' })
  closeTime!: string;

  @IsBoolean()
  isOpen!: boolean;
}

export class SetupSchedulesDto {
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => ScheduleItemDto)
  schedules!: ScheduleItemDto[];
}

export class BreakTimeDto {
  @IsInt()
  @Min(0)
  @Max(6)
  dayOfWeek!: number;

  @Matches(TIME_RE)
  startTime!: string;

  @Matches(TIME_RE)
  endTime!: string;
}

export class HolidayDto {
  @IsString()
  date!: string; // YYYY-MM-DD

  @IsOptional()
  @IsString()
  description?: string;
}

export class CreateServiceDto {
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @IsOptional()
  @IsString()
  categoryName?: string;

  @IsString()
  @IsNotEmpty()
  name!: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsNumber()
  @IsPositive()
  price!: number;

  @IsInt()
  @IsPositive()
  duration!: number;

  @IsOptional()
  @IsEnum(Gender)
  gender?: Gender;

  @IsOptional()
  @IsString()
  imageUrl?: string;
}

export class CreateStaffDto {
  @IsString()
  @IsNotEmpty()
  fullName!: string;

  @IsString()
  @IsNotEmpty()
  phone!: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsString()
  @IsNotEmpty()
  designation!: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  assignedServiceIds?: string[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ScheduleItemDto)
  workingHours?: ScheduleItemDto[];
}

export class BankDetailsDto {
  @IsString()
  @IsNotEmpty()
  accountHolder!: string;

  @IsString()
  @IsNotEmpty()
  bankName!: string;

  @IsString()
  @IsNotEmpty()
  accountNumber!: string;

  @IsString()
  @IsNotEmpty()
  ifsc!: string;

  @IsOptional()
  @IsString()
  upiId?: string;
}

export class KycDocumentDto {
  @IsEnum(DocumentType)
  documentType!: DocumentType;
}

export class SubscriptionCheckoutDto {
  @IsUUID()
  planId!: string;
}

export class CustomerOnboardingDto {
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  interests?: string[];

  @IsOptional()
  @IsBoolean()
  locationAllowed?: boolean;

  @IsOptional()
  @IsBoolean()
  notificationsAllowed?: boolean;

  @IsOptional()
  @IsString()
  referralCode?: string;

  @IsOptional()
  @IsString()
  firstName?: string;

  @IsOptional()
  @IsString()
  lastName?: string;

  @IsOptional()
  @IsString()
  fullName?: string;

  @IsOptional()
  @IsString()
  dateOfBirth?: string;

  @IsOptional()
  @IsEnum(Gender)
  gender?: Gender;
}
