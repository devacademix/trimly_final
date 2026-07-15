import { Controller, Get, Post, Patch, Body, Param, Query, UseGuards, ParseIntPipe } from '@nestjs/common';
import { PayrollService } from './payroll.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '@trimly/types';
import { TenantGuard } from '../common/guards/tenant.guard';
import { TenantId } from '../common/decorators/tenant.decorator';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { UpdateCommissionDto } from './dto/payroll.dto';

@ApiTags('Payroll & Commission')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, TenantGuard, RolesGuard)
@Roles(UserRole.SALON_OWNER, UserRole.MANAGER)
@Controller('payroll')
export class PayrollController {
  constructor(private payrollService: PayrollService) {}

  @Get()
  @ApiOperation({ summary: 'Calculate monthly payroll for all staff' })
  @ApiQuery({ name: 'month', type: Number, required: true })
  @ApiQuery({ name: 'year', type: Number, required: true })
  async getMonthlyPayroll(
    @TenantId() tenantId: string,
    @Query('month', ParseIntPipe) month: number,
    @Query('year', ParseIntPipe) year: number,
  ) {
    const data = await this.payrollService.calculateMonthlyPayroll(tenantId, month, year);
    return { success: true, data };
  }

  @Post(':staffId/pay')
  @ApiOperation({ summary: 'Mark a staff member as paid for a specific month' })
  async markAsPaid(
    @TenantId() tenantId: string,
    @Param('staffId') staffId: string,
    @Body('month', ParseIntPipe) month: number,
    @Body('year', ParseIntPipe) year: number,
  ) {
    const data = await this.payrollService.markAsPaid(tenantId, staffId, month, year);
    return { success: true, data };
  }

  @Patch('staff/:staffId/commission')
  @ApiOperation({ summary: 'Update base salary and commission rate for a staff' })
  async updateCommission(
    @TenantId() tenantId: string,
    @Param('staffId') staffId: string,
    @Body() dto: UpdateCommissionDto,
  ) {
    const data = await this.payrollService.updateCommission(tenantId, staffId, dto);
    return { success: true, data };
  }
}
