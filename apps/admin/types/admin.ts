export enum UserRole {
  SUPER_ADMIN = 'SUPER_ADMIN',
  SALON_OWNER = 'SALON_OWNER',
  STAFF = 'STAFF',
  CUSTOMER = 'CUSTOMER',
}

export enum UserStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  SUSPENDED = 'SUSPENDED',
  PENDING_VERIFICATION = 'PENDING_VERIFICATION',
}

export enum TenantStatus {
  PENDING_APPROVAL = 'PENDING_APPROVAL',
  APPROVED = 'APPROVED',
  SUSPENDED = 'SUSPENDED',
  REJECTED = 'REJECTED',
}

export enum BookingStatus {
  PENDING = 'PENDING',
  CONFIRMED = 'CONFIRMED',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
  NO_SHOW = 'NO_SHOW',
}

export interface AdminUser {
  id: string;
  role: UserRole;
  status: UserStatus;
  email?: string | null;
  phone?: string | null;
  fullName?: string | null;
  tenantId?: string | null;
  profileImageUrl?: string | null;
}

export interface Salon {
  id: string;
  slug: string;
  name: string;
  legalName?: string | null;
  description?: string | null;
  gstNumber?: string | null;
  panNumber?: string | null;
  status: string;
  isActive: boolean;
  ownerEmail?: string | null;
  ownerPhone?: string | null;
  logoUrl?: string | null;
  coverImageUrl?: string | null;
  primaryCity?: string | null;
  primaryCountry: string;
  currency: string;
  timezone: string;
  commissionPct?: string | null;
  createdAt: string;
  updatedAt: string;
  _count?: {
    users: number;
    branches: number;
    bookings: number;
  };
}

export interface PlatformUser {
  id: string;
  email?: string | null;
  phone?: string | null;
  fullName?: string | null;
  role: UserRole;
  status: UserStatus;
  tenantId?: string | null;
  createdAt: string;
}

export interface AdminBooking {
  id: string;
  tenantId: string;
  branchId: string;
  customerId: string;
  staffId?: string | null;
  startTime: string;
  endTime: string;
  status: BookingStatus;
  totalPrice: string;
  notes?: string | null;
  createdAt: string;
  tenant: { name: string };
  customer: { fullName?: string | null; email?: string | null };
}

export interface RevenueStats {
  totalVolume: number;
  totalPlatformCommission: number;
  totalSalonRevenue: number;
  salonCount: number;
  bookingCount: number;
}
