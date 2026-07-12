import { IsArray, IsEnum, IsISO8601, IsInt, IsNotEmpty, IsNumber, IsOptional, IsPositive, IsString, IsUUID, Max, Min } from 'class-validator';
import { CouponType } from '@trimly/database';

export class CreateCouponDto {
  @IsString()
  @IsNotEmpty()
  code!: string;

  @IsEnum(CouponType)
  type!: CouponType;

  @IsNumber()
  @IsPositive()
  value!: number;

  @IsOptional()
  @IsNumber()
  @IsPositive()
  maxDiscount?: number;

  @IsOptional()
  @IsNumber()
  @IsPositive()
  minOrderVal?: number;

  @IsOptional()
  @IsInt()
  @IsPositive()
  usageLimit?: number;

  @IsISO8601()
  startDate!: string;

  @IsISO8601()
  endDate!: string;
}

export class CreateReviewDto {
  @IsUUID()
  salonId!: string;

  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @IsOptional()
  @IsString()
  comment?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  imageUrls?: string[];
}

export class ReplyReviewDto {
  @IsString()
  @IsNotEmpty()
  replyText!: string;
}
