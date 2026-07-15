import { IsString, IsNumber, IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreatePlanDto {
  @ApiProperty({ example: 'Premium Plan' })
  @IsString()
  name!: string;

  @ApiPropertyOptional({ example: 'All features included' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 99.99 })
  @IsNumber()
  price!: number;

  @ApiProperty({ example: 'MONTHLY' })
  @IsString()
  billingPeriod!: string;

  @ApiPropertyOptional({ example: 5 })
  @IsOptional()
  @IsNumber()
  branchLimit?: number;

  @ApiPropertyOptional({ example: 10 })
  @IsOptional()
  @IsNumber()
  staffLimit?: number;

  @ApiPropertyOptional({ example: 500 })
  @IsOptional()
  @IsNumber()
  bookingLimit?: number;

  @ApiPropertyOptional({ example: 1024 })
  @IsOptional()
  @IsNumber()
  storageLimitMb?: number;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdatePlanDto {
  @ApiPropertyOptional({ example: 'Premium Plan' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: 'All features included' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ example: 99.99 })
  @IsOptional()
  @IsNumber()
  price?: number;

  @ApiPropertyOptional({ example: 'MONTHLY' })
  @IsOptional()
  @IsString()
  billingPeriod?: string;

  @ApiPropertyOptional({ example: 5 })
  @IsOptional()
  @IsNumber()
  branchLimit?: number;

  @ApiPropertyOptional({ example: 10 })
  @IsOptional()
  @IsNumber()
  staffLimit?: number;

  @ApiPropertyOptional({ example: 500 })
  @IsOptional()
  @IsNumber()
  bookingLimit?: number;

  @ApiPropertyOptional({ example: 1024 })
  @IsOptional()
  @IsNumber()
  storageLimitMb?: number;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
