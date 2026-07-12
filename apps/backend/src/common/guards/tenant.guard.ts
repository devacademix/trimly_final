import { Injectable, CanActivate, ExecutionContext, BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UserRole } from '@trimly/types';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Resolves which tenant a request is scoped to.
//
// Trust model: for SALON_OWNER/STAFF, the tenant is always forced to the
// caller's own profile tenantId — a client-supplied x-tenant-id/query/param
// can never widen that. For everyone else (CUSTOMER, SUPER_ADMIN, or
// unauthenticated public routes like "browse salon availability"), the
// tenant comes from the client because the caller is choosing *which* salon
// to look at — this guard only confirms that tenant exists and is active,
// it does NOT grant ownership of that tenant's data. Any endpoint that
// mutates or returns tenant-owned records on behalf of a CUSTOMER must do
// its own ownership check in the service layer (see BookingService.assertBookingAccess,
// PaymentService.createBookingCheckout/refundPayment) — this guard alone is
// not an authorization boundary for customer-initiated writes.
@Injectable()
export class TenantGuard implements CanActivate {
  constructor(private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();

    // 1. Extract tenant ID from headers, query, or path params
    let tenantId = request.headers['x-tenant-id'] || request.query.tenantId || request.params.tenantId;

    const user = request.user;

    // 2. If user is SALON_OWNER or STAFF, enforce their profile tenantId
    if (user && (user.role === UserRole.SALON_OWNER || user.role === UserRole.STAFF)) {
      if (!user.tenantId) {
        throw new ForbiddenException('User is not associated with any tenant/salon');
      }

      // If a tenant ID was explicitly requested, make sure it matches their profile
      if (tenantId && tenantId !== user.tenantId) {
        throw new ForbiddenException('Access denied: Cross-tenant data access is prohibited');
      }

      // Force scope to their profile tenantId
      tenantId = user.tenantId;
    }

    // 3. Validate tenant if it is provided/resolved
    if (tenantId) {
      if (typeof tenantId !== 'string' || !UUID_RE.test(tenantId)) {
        throw new BadRequestException('Invalid tenant/salon identifier');
      }

      const tenant = await this.prisma.tenant.findUnique({
        where: { id: tenantId },
      });

      if (!tenant) {
        throw new NotFoundException('Requested salon/tenant not found');
      }

      if (!tenant.isActive) {
        throw new BadRequestException('Requested salon/tenant is currently inactive');
      }

      // Attach to request
      request.tenantId = tenant.id;
    }

    return true;
  }
}
