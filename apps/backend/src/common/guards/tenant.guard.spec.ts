import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { TenantGuard } from './tenant.guard';
import { UserRole } from '@trimly/types';

describe('TenantGuard', () => {
  let guard: TenantGuard;
  let prisma: any;

  const makeContext = (request: any) => ({
    switchToHttp: () => ({ getRequest: () => request }),
  }) as any;

  beforeEach(() => {
    prisma = { tenant: { findUnique: jest.fn() } };
    guard = new TenantGuard(prisma);
  });

  it('rejects an invalid (non-UUID) tenant identifier', async () => {
    const request = { headers: { 'x-tenant-id': 'not-a-uuid' }, query: {}, params: {} };
    await expect(guard.canActivate(makeContext(request))).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects when the requested tenant does not exist', async () => {
    prisma.tenant.findUnique.mockResolvedValue(null);
    const request = {
      headers: { 'x-tenant-id': '11111111-1111-1111-1111-111111111111' },
      query: {},
      params: {},
    };
    await expect(guard.canActivate(makeContext(request))).rejects.toBeInstanceOf(NotFoundException);
  });

  it('rejects when the tenant is inactive', async () => {
    prisma.tenant.findUnique.mockResolvedValue({ id: '11111111-1111-1111-1111-111111111111', isActive: false });
    const request = {
      headers: { 'x-tenant-id': '11111111-1111-1111-1111-111111111111' },
      query: {},
      params: {},
    };
    await expect(guard.canActivate(makeContext(request))).rejects.toBeInstanceOf(BadRequestException);
  });

  const TENANT_OWN = '22222222-2222-2222-2222-222222222222';
  const TENANT_ATTACKER = '33333333-3333-3333-3333-333333333333';

  it('forces the tenant scope to the SALON_OWNER’s own profile, ignoring a mismatched header', async () => {
    prisma.tenant.findUnique.mockResolvedValue({ id: TENANT_OWN, isActive: true });
    const request = {
      headers: { 'x-tenant-id': TENANT_ATTACKER },
      query: {},
      params: {},
      user: { role: UserRole.SALON_OWNER, tenantId: TENANT_OWN },
    };

    await expect(guard.canActivate(makeContext(request))).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('allows a SALON_OWNER whose header matches their own tenant and sets request.tenantId', async () => {
    prisma.tenant.findUnique.mockResolvedValue({ id: TENANT_OWN, isActive: true });
    const request: any = {
      headers: { 'x-tenant-id': TENANT_OWN },
      query: {},
      params: {},
      user: { role: UserRole.SALON_OWNER, tenantId: TENANT_OWN },
    };

    const result = await guard.canActivate(makeContext(request));
    expect(result).toBe(true);
    expect(request.tenantId).toBe(TENANT_OWN);
  });

  it('rejects a SALON_OWNER with no tenant profile', async () => {
    const request = {
      headers: {},
      query: {},
      params: {},
      user: { role: UserRole.SALON_OWNER, tenantId: null },
    };
    await expect(guard.canActivate(makeContext(request))).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('allows a request with no tenant id at all to pass through (public/unscoped route)', async () => {
    const request = { headers: {}, query: {}, params: {} };
    const result = await guard.canActivate(makeContext(request));
    expect(result).toBe(true);
    expect(prisma.tenant.findUnique).not.toHaveBeenCalled();
  });
});
