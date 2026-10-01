import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
const prisma = new PrismaClient();

async function main() {
  const admin = await prisma.user.upsert({
    where: { email: 'admin@yumgo.com' },
    update: {},
    create: {
      email: 'admin@yumgo.com',
      passwordHash: await bcrypt.hash('admin123', 10),
      name: 'YumGo Admin',
      role: 'ADMIN',
    },
  });
  console.log('Admin created:', admin.email, 'password: admin123');
}
main().finally(() => prisma.$disconnect());