/**
 * Trimly — database seed.
 *
 * Creates the bootstrap super-admin user and the platform default-commission
 * setting. Safe to run multiple times: it upserts on stable keys.
 *
 * Credentials come from env (see `.env.example`):
 *   SUPERADMIN_EMAIL, SUPERADMIN_PHONE, SUPERADMIN_PASSWORD, SUPERADMIN_FULL_NAME
 */
import { PrismaClient, UserRole, UserStatus, AuthProvider } from '../src/generated/prisma/index.js';
import bcrypt from 'bcryptjs';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';

function loadRootEnv() {
  let currentDir = process.cwd();
  const envPathCandidates: string[] = [];

  while (true) {
    const candidate = join(currentDir, '.env');
    if (existsSync(candidate)) {
      envPathCandidates.push(candidate);
    }

    const parentDir = dirname(currentDir);
    if (parentDir === currentDir) break;
    currentDir = parentDir;
  }

  const envPath = envPathCandidates.at(-1);
  if (!envPath) return;

  for (const line of readFileSync(envPath, 'utf8').split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;

    const separatorIndex = trimmed.indexOf('=');
    if (separatorIndex === -1) continue;

    const key = trimmed.slice(0, separatorIndex).trim();
    const rawValue = trimmed.slice(separatorIndex + 1).trim();
    if (!key || process.env[key] !== undefined) continue;

    process.env[key] = rawValue.replace(/^(['"])(.*)\1$/, '$2');
  }
}

loadRootEnv();

const prisma = new PrismaClient();

async function main() {
  const email = (process.env.SUPERADMIN_EMAIL ?? 'admin@trimly.test').toLowerCase();
  const phone = process.env.SUPERADMIN_PHONE ?? '+919999999999';
  const password = process.env.SUPERADMIN_PASSWORD ?? 'ChangeMe!2026';
  const fullName = process.env.SUPERADMIN_FULL_NAME ?? 'Trimly Super Admin';

  const passwordHash = await bcrypt.hash(password, 12);
  // E.164-ish normalization: strip spaces, keep leading +.
  const phoneNormalized = phone.replace(/[^\d+]/g, '');

  const admin = await prisma.user.upsert({
    where: { email },
    update: {
      role: UserRole.SUPER_ADMIN,
      status: UserStatus.ACTIVE,
      // keep password in sync with env for the bootstrap admin
      passwordHash,
    },
    create: {
      email,
      phone,
      phoneNormalized,
      passwordHash,
      fullName,
      role: UserRole.SUPER_ADMIN,
      status: UserStatus.ACTIVE,
      authProvider: AuthProvider.EMAIL,
      emailVerifiedAt: new Date(),
      phoneVerifiedAt: new Date(),
    },
  });

  console.info(`✔ Seeded super-admin: ${admin.email} (${admin.id})`);

  // Platform default commission (overridable per-tenant). Sprint 11 reads this.
  await prisma.setting.upsert({
    where: { key: 'platform.defaultCommissionPct' },
    update: {},
    create: { key: 'platform.defaultCommissionPct', value: 15 },
  });

  await prisma.setting.upsert({
    where: { key: 'platform.currency' },
    update: {},
    create: { key: 'platform.currency', value: 'INR' },
  });

  console.info('✔ Seeded platform settings (defaultCommissionPct=15, currency=INR)');

  // Demo tenant + salon-owner + customer — lets the customer-app and
  // salon-app login screens (which prefill these exact credentials) log in
  // against a freshly seeded local backend without any manual setup.
  const demoTenant = await prisma.tenant.upsert({
    where: { slug: 'trimly-demo-salon' },
    update: {},
    create: {
      slug: 'trimly-demo-salon',
      name: 'Trimly Demo Salon',
      status: 'APPROVED',
      isActive: true,
      ownerEmail: 'owner@trimly.test',
      primaryCity: 'Bengaluru',
    },
  });

  const ownerPasswordHash = await bcrypt.hash('ChangeMe!2026', 12);
  await prisma.user.upsert({
    where: { email: 'owner@trimly.test' },
    update: { role: UserRole.SALON_OWNER, status: UserStatus.ACTIVE, tenantId: demoTenant.id, passwordHash: ownerPasswordHash },
    create: {
      email: 'owner@trimly.test',
      phone: '+919999999901',
      phoneNormalized: '+919999999901',
      passwordHash: ownerPasswordHash,
      fullName: 'Demo Salon Owner',
      role: UserRole.SALON_OWNER,
      status: UserStatus.ACTIVE,
      authProvider: AuthProvider.EMAIL,
      tenantId: demoTenant.id,
      emailVerifiedAt: new Date(),
      phoneVerifiedAt: new Date(),
    },
  });
  console.info('✔ Seeded demo salon owner: owner@trimly.test / ChangeMe!2026');

  const customerPasswordHash = await bcrypt.hash('Password123', 12);
  await prisma.user.upsert({
    where: { email: 'customer@trimly.test' },
    update: { role: UserRole.CUSTOMER, status: UserStatus.ACTIVE, passwordHash: customerPasswordHash },
    create: {
      email: 'customer@trimly.test',
      phone: '+919999999902',
      phoneNormalized: '+919999999902',
      passwordHash: customerPasswordHash,
      fullName: 'Demo Customer',
      role: UserRole.CUSTOMER,
      status: UserStatus.ACTIVE,
      authProvider: AuthProvider.EMAIL,
      emailVerifiedAt: new Date(),
      phoneVerifiedAt: new Date(),
    },
  });
  console.info('✔ Seeded demo customer: customer@trimly.test / Password123');
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (e) => {
    console.error('✖ Seed failed:', e);
    await prisma.$disconnect();
    process.exit(1);
  });
