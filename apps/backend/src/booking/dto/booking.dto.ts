import { IsEnum, IsISO8601, IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';
import { BookingStatus } from '@trimly/database';

export class CreateBookingDto {
  @IsUUID()
  branchId!: string;

  @IsUUID()
  serviceId!: string;

  @IsOptional()
  @IsUUID()
  staffId?: string;

  @IsISO8601()
  startTime!: string;
}

export class CancelBookingDto {
  @IsOptional()
  @IsString()
  notes?: string;
}

export class RescheduleBookingDto {
  @IsISO8601()
  startTime!: string;
}

export class JoinWaitingListDto {
  @IsISO8601()
  startTime!: string;
}

export class UpdateBookingStatusDto {
  @IsEnum(BookingStatus)
  status!: BookingStatus;
}
