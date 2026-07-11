/**
 * @trimly/types — shared API contracts for the Trimly platform.
 *
 * Consumed by:
 *   - apps/backend   (NestJS response shapes & error codes)
 *   - apps/admin     (Next.js fetch typing)
 *   - Flutter apps    (regenerated into Dart via Sprint 8's codegen step; until
 *                      then these act as the canonical source of truth)
 *
 * Enums are intentionally duplicated from the Prisma schema (not imported) so
 * the runtime packages don't need to pull the whole Prisma client. Keep these
 * in sync with packages/database/prisma/schema.prisma.
 */

// ─── User / identity ─────────────────────────────────────────────────────────

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

export enum AuthProvider {
  EMAIL = 'EMAIL',
  OTP = 'OTP',
  GOOGLE = 'GOOGLE',
  APPLE = 'APPLE',
}

export enum Gender {
  MALE = 'MALE',
  FEMALE = 'FEMALE',
  OTHER = 'OTHER',
  PREFER_NOT_TO_SAY = 'PREFER_NOT_TO_SAY',
}

// ─── Generic API envelope ────────────────────────────────────────────────────

export interface ApiResponseOk<T> {
  success: true;
  data: T;
  meta?: ResponseMeta;
}

export interface ApiResponseErr {
  success: false;
  error: ApiError;
  meta?: ResponseMeta;
}

export type ApiResponse<T> = ApiResponseOk<T> | ApiResponseErr;

export interface ResponseMeta {
  /** Echoed back to clients for distributed tracing. */
  requestId?: string;
  /** Cursor/page pagination. */
  pagination?: PaginationMeta;
  /** Wall-clock server time of the response (ISO 8601). */
  timestamp?: string;
}

export interface PaginationMeta {
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
  hasMore: boolean;
}

export interface Paginated<T> {
  items: T[];
  pagination: PaginationMeta;
}

export interface ApiError {
  /** Stable machine-readable code, see `ErrorCode`. */
  code: string;
  /** Human-readable message safe to show end users. */
  message: string;
  /** Field-level validation errors, when applicable. */
  fields?: Record<string, string[]>;
  /** Optional free-form detail for debugging (never secrets). */
  details?: unknown;
}

// ─── Stable error codes ──────────────────────────────────────────────────────

export const ErrorCode = {
  // Auth
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  TOKEN_EXPIRED: 'TOKEN_EXPIRED',
  INVALID_CREDENTIALS: 'INVALID_CREDENTIALS',
  OTP_INVALID: 'OTP_INVALID',
  OTP_EXPIRED: 'OTP_EXPIRED',
  // Resource
  NOT_FOUND: 'NOT_FOUND',
  CONFLICT: 'CONFLICT',
  VALIDATION_FAILED: 'VALIDATION_FAILED',
  // Tenancy
  TENANT_MISMATCH: 'TENANT_MISMATCH',
  // System
  RATE_LIMITED: 'RATE_LIMITED',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
  SERVICE_UNAVAILABLE: 'SERVICE_UNAVAILABLE',
} as const;

export type ErrorCode = (typeof ErrorCode)[keyof typeof ErrorCode];

// ─── Health ──────────────────────────────────────────────────────────────────

export interface HealthResponse {
  status: 'ok' | 'degraded' | 'down';
  service: string;
  version: string;
  timestamp: string;
  uptimeSeconds: number;
  checks?: Record<string, ComponentHealth>;
}

export interface ComponentHealth {
  status: 'ok' | 'degraded' | 'down';
  latencyMs?: number;
  details?: string;
}

// ─── Auth (preview — fleshed out in Sprint 2) ────────────────────────────────

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  /** Seconds until the access token expires. */
  expiresIn: number;
  tokenType: 'Bearer';
}

export interface AuthSession extends AuthTokens {
  user: AuthUser;
}

export interface AuthUser {
  id: string;
  role: UserRole;
  status: UserStatus;
  email?: string | null;
  phone?: string | null;
  fullName?: string | null;
  tenantId?: string | null;
  profileImageUrl?: string | null;
}
