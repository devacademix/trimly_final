import { Injectable, CanActivate, ExecutionContext, BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UserRole } from '@trimly/types';

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
