const { PrismaClient } = require('../packages/database/src/generated/prisma');
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: 'postgresql://trimly:trimly@localhost:5434/trimly?schema=public'
    }
  }
});

async function main() {
  // Find or create tenant
  let tenant = await prisma.tenant.findFirst();
  if (!tenant) {
    tenant = await prisma.tenant.create({
      data: {
        name: 'Test Salon',
        slug: 'test-salon',
        kycStatus: 'APPROVED'
      }
    });
  }

  // Find or create branch
  let branch = await prisma.branch.findFirst({
    where: { tenantId: tenant.id }
  });
  if (!branch) {
    branch = await prisma.branch.create({
      data: {
        tenantId: tenant.id,
        name: 'Main Branch',
        address: '123 Main St'
      }
    });
  }

  // Find or create customer (User)
  let customer = await prisma.user.findFirst({
    where: { role: 'CUSTOMER' }
  });
  if (!customer) {
    customer = await prisma.user.create({
      data: {
        email: 'customer@test.com',
        fullName: 'Test Customer',
        role: 'CUSTOMER',
        status: 'ACTIVE'
      }
    });
  }

  // Create booking
  const booking = await prisma.booking.create({
    data: {
      tenantId: tenant.id,
      branchId: branch.id,
      customerId: customer.id,
      startTime: new Date(),
      endTime: new Date(Date.now() + 30 * 60 * 1000), // 30 mins later
      totalPrice: 500.0,
      status: 'PENDING'
    }
  });

  console.log('Created Booking:', JSON.stringify(booking, null, 2));
  await prisma.$disconnect();
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
