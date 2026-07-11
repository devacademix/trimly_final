import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WalletType, TransactionType, TransactionStatus } from '@trimly/database';

@Injectable()
export class WalletService {
  constructor(private prisma: PrismaService) {}

  // Get or Create user/tenant wallet
  async getOrCreateWallet(userId?: string, tenantId?: string, type: WalletType = WalletType.CUSTOMER) {
    if (!userId && !tenantId) {
      throw new BadRequestException('Provide either userId or tenantId to resolve wallet');
    }

    const where = tenantId ? { tenantId } : { userId };

    let wallet = await this.prisma.wallet.findUnique({
      where: where as any,
    });

    if (!wallet) {
      wallet = await this.prisma.wallet.create({
        data: {
          userId: userId || null,
          tenantId: tenantId || null,
          type,
          balance: 0.0,
        },
      });
    }

    return wallet;
  }

  // Get wallet details + transaction ledger
  async getWalletDetails(userId?: string, tenantId?: string) {
    const wallet = await this.getOrCreateWallet(userId, tenantId);
    const transactions = await this.prisma.walletTransaction.findMany({
      where: { walletId: wallet.id },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    return {
      wallet,
      transactions,
    };
  }

  // Process Payout / Withdrawal request
  async requestWithdrawal(userId: string, amount: number) {
    const wallet = await this.getOrCreateWallet(userId, undefined, WalletType.CUSTOMER);
    if (Number(wallet.balance) < amount) {
      throw new BadRequestException('Insufficient wallet balance');
    }

    return this.prisma.$transaction(async (tx) => {
      // Deduct balance
      const updatedWallet = await tx.wallet.update({
        where: { id: wallet.id },
        data: { balance: { decrement: amount } },
      });

      // Log transaction
      const transaction = await tx.walletTransaction.create({
        data: {
          walletId: wallet.id,
          type: TransactionType.WITHDRAWAL,
          status: TransactionStatus.SUCCESS,
          amount,
          description: 'Withdrawal payout processed successfully',
        },
      });

      return { wallet: updatedWallet, transaction };
    });
  }

  // List Salon settlements
  async getSettlements(tenantId: string) {
    return this.prisma.settlement.findMany({
      where: { tenantId },
      orderBy: { createdAt: 'desc' },
    });
  }

  // Run Salon settlement (Auto/Manual transfer)
  async settleSalonBalance(tenantId: string) {
    const wallet = await this.getOrCreateWallet(undefined, tenantId, WalletType.SALON);
    const pendingBalance = Number(wallet.balance);

    if (pendingBalance <= 0) {
      throw new BadRequestException('No pending balance to settle for this salon');
    }

    return this.prisma.$transaction(async (tx) => {
      // Deduct balance to zero
      await tx.wallet.update({
        where: { id: wallet.id },
        data: { balance: 0.0 },
      });

      // Log transaction
      await tx.walletTransaction.create({
        data: {
          walletId: wallet.id,
          type: TransactionType.SETTLEMENT,
          status: TransactionStatus.SUCCESS,
          amount: pendingBalance,
          description: `Settled balance to registered bank account`,
        },
      });

      // Create settlement report
      return tx.settlement.create({
        data: {
          tenantId,
          amount: pendingBalance,
          status: 'SETTLED',
          settledAt: new Date(),
          referenceId: `set_ref_${Date.now()}`,
        },
      });
    });
  }
}
