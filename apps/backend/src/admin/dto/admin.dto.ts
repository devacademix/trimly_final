import { IsBoolean, IsEnum, IsNumber, Max, Min } from 'class-validator';
import { UserRole, UserStatus } from '@trimly/types';

// Tenant.status is a free-form String column (no DB enum), so we constrain
// it to known application states at the validation layer.
export enum TenantStatus {
  PENDING_APPROVAL = 'PENDING_APPROVAL',
  APPROVED = 'APPROVED',
  SUSPENDED = 'SUSPENDED',
  REJECTED = 'REJECTED',
}

export class UpdateSalonStatusDto {
  @IsEnum(TenantStatus)
  status!: TenantStatus;

  @IsBoolean()
  isActive!: boolean;
}

export class UpdateSalonCommissionDto {
  @IsNumber()
  @Min(0)
  @Max(100)
  commissionPct!: number;
}

export class SetGlobalCommissionDto {
  @IsNumber()
  @Min(0)
  @Max(100)
  commissionPct!: number;
}

export class UpdateUserStatusDto {
  @IsEnum(UserStatus)
  status!: UserStatus;
}

export class UpdateUserRoleDto {
  @IsEnum(UserRole)
  role!: UserRole;
}

