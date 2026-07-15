const { PrismaClient } = require('./src/generated/prisma');
const prisma = new PrismaClient();

async function run() {
  await prisma.subscriptionPlan.createMany({
    data: [
      { name: 'Free', price: 0, branchLimit: 1, staffLimit: 2, bookingLimit: 50 },
      { name: 'Starter', price: 999, branchLimit: 1, staffLimit: 5, bookingLimit: 200 },
      { name: 'Professional', price: 2499, branchLimit: 3, staffLimit: 15, bookingLimit: 1000 },
      { name: 'Enterprise', price: 5999, branchLimit: 99, staffLimit: 999, bookingLimit: 99999 }
    ],
    skipDuplicates: true
  });
  console.log('Seeded');
}
run();
