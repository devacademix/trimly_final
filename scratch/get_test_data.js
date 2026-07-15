const { PrismaClient } = require('../packages/database/src/generated/prisma');
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: 'postgresql://trimly:trimly@localhost:5434/trimly?schema=public'
    }
  }
});

async function main() {
  const bookings = await prisma.booking.findMany({
    take: 5,
    orderBy: { createdAt: 'desc' }
  });
  console.log('Bookings:', JSON.stringify(bookings, null, 2));
  await prisma.$disconnect();
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
