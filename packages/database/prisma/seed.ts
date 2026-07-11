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
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (e) => {
    console.error('✖ Seed failed:', e);
    await prisma.$disconnect();
    process.exit(1);
  });
