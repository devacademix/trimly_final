import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { WalletService } from './wallet.service';
import { ApiResponse, UserRole } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { TenantGuard } from '../common/guards/tenant.guard';
import { TenantId } from '../common/decorators/tenant.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('Wallets & Payout Settlements')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('wallet')
export class WalletController {
  constructor(private walletService: WalletService) {}

  @Get('balance')
  @UseGuards(TenantGuard)
  @ApiHeader({ name: 'x-tenant-id', required: false })
  @ApiOperation({ summary: 'Retrieve active wallet balance and transaction history' })
  async getBalance(
    @TenantId() tenantId: string,
    @CurrentUser() user: any,
  ): Promise<ApiResponse<any>> {
    if (user.role === UserRole.SALON_OWNER) {
      const data = await this.walletService.getWalletDetails(undefined, tenantId);
      return { success: true, data };
    } else {
      const data = await this.walletService.getWalletDetails(user.id, undefined);
      return { success: true, data };
    }
  }

  @Post('withdraw')
  @Roles(UserRole.CUSTOMER)
  @UseGuards(RolesGuard)
  @ApiOperation({ summary: 'Request withdrawal/payout from wallet' })
  async withdraw(
    @CurrentUser() user: any,
    @Body() dto: { amount: number },
  ): Promise<ApiResponse<any>> {
    const res = await this.walletService.requestWithdrawal(user.id, dto.amount);
    return {
      success: true,
      data: res,
    };
  }

  @Get('settlements')
  @UseGuards(TenantGuard, RolesGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiHeader({ name: 'x-tenant-id' })
  @ApiOperation({ summary: 'Get active payout settlements history' })
  async getSettlements(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const settlements = await this.walletService.getSettlements(tenantId);
    return {
      success: true,
      data: settlements,
    };
  }

  @Post('settle')
  @UseGuards(TenantGuard, RolesGuard)
  @Roles(UserRole.SALON_OWNER)
  @ApiHeader({ name: 'x-tenant-id' })
  @ApiOperation({ summary: 'Trigger manual settlement payout of pending balance' })
  async settle(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const settlement = await this.walletService.settleSalonBalance(tenantId);
    return {
      success: true,
      data: settlement,
    };
  }
}
