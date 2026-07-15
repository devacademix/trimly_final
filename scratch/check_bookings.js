const { PrismaClient } = require('../packages/database/src/generated/prisma');
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: "postgresql://trimly:trimly@localhost:5434/trimly?schema=public"
    }
  }
});

async function main() {
  console.log("Checking bookings...");
  const bookings = await prisma.booking.findMany({
    orderBy: { createdAt: 'desc' },
    select: {
      id: true,
      status: true,
      createdAt: true,
      startTime: true,
      totalPrice: true,
      customer: { select: { fullName: true } }
    }
  });
  console.log("Bookings count:", bookings.length);
  console.log(JSON.stringify(bookings, null, 2));
  await prisma.$disconnect();
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
