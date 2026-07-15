import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateCommissionDto } from './dto/payroll.dto';

@Injectable()
export class PayrollService {
  constructor(private prisma: PrismaService) {}

  async calculateMonthlyPayroll(tenantId: string, month: number, year: number) {
    // month is 1-12
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59, 999);

    const staffProfiles = await this.prisma.staffProfile.findMany({
      where: { tenantId },
      include: {
        user: {
          select: { fullName: true, phone: true }
        },
        bookings: {
          where: {
            tenantId,
            status: 'COMPLETED',
            startTime: {
              gte: startDate,
              lte: endDate,
            },
          },
          select: {
            totalPrice: true,
          }
        },
        payrollRecords: {
          where: {
            tenantId,
            periodMonth: month,
            periodYear: year,
          }
        }
      }
    });

    return staffProfiles.map(staff => {
      const baseSalary = Number(staff.baseSalary ?? 0);
      const commissionRate = Number(staff.commissionRate ?? 0);
      
      const totalServicesRevenue = staff.bookings.reduce((sum: number, booking) => sum + Number(booking.totalPrice), 0);
      const commissionAmount = (totalServicesRevenue * commissionRate) / 100.0;
      
      const totalAmount = baseSalary + commissionAmount;
      
      const record = staff.payrollRecords[0];

      return {
        staffId: staff.id,
        name: staff.user.fullName ?? '',
        baseSalary,
        commissionRate,
        totalServicesRevenue,
        commissionAmount,
        totalAmount,
        status: record ? record.status : 'PENDING',
        paidAt: record ? record.paidAt : null,
      };
    });
  }

  async markAsPaid(tenantId: string, staffId: string, month: number, year: number) {
    const existing = await this.prisma.payrollRecord.findUnique({
      where: {
        staffId_periodMonth_periodYear: {
          staffId,
          periodMonth: month,
          periodYear: year,
        }
      }
    });

    if (existing && existing.status === 'PAID') {
      throw new BadRequestException('Already paid for this month');
    }

    const staff = await this.prisma.staffProfile.findUnique({
      where: { id: staffId, tenantId },
      include: {
        bookings: {
          where: {
            tenantId,
            status: 'COMPLETED',
            startTime: {
              gte: new Date(year, month - 1, 1),
              lte: new Date(year, month, 0, 23, 59, 59, 999),
            },
          },
        }
      }
    });

    if (!staff) throw new NotFoundException('Staff not found');

    const baseSalary = Number(staff.baseSalary ?? 0);
    const commissionRate = Number(staff.commissionRate ?? 0);
    const totalServicesRevenue = staff.bookings.reduce((sum: number, booking) => sum + Number(booking.totalPrice), 0);
    const commissionAmount = (totalServicesRevenue * commissionRate) / 100.0;
    const totalAmount = baseSalary + commissionAmount;

    return this.prisma.payrollRecord.upsert({
      where: {
        staffId_periodMonth_periodYear: {
          staffId,
          periodMonth: month,
          periodYear: year,
        }
      },
      create: {
        staffId,
        tenantId,
        periodMonth: month,
        periodYear: year,
        baseAmount: baseSalary,
        commissionAmount,
        totalAmount,
        status: 'PAID',
        paidAt: new Date(),
      },
      update: {
        baseAmount: baseSalary,
        commissionAmount,
        totalAmount,
        status: 'PAID',
        paidAt: new Date(),
      }
    });
  }

  async updateCommission(tenantId: string, staffId: string, data: UpdateCommissionDto) {
    return this.prisma.staffProfile.update({
      where: { id: staffId, tenantId },
      data,
    });
  }
}
