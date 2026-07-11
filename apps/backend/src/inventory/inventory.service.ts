import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { InventoryMovementType } from '@trimly/database';

@Injectable()
export class InventoryService {
  constructor(private prisma: PrismaService) {}

  // Categories
  async createCategory(tenantId: string, name: string) {
    return this.prisma.productCategory.create({
      data: { tenantId, name },
    });
  }

  async getCategories(tenantId: string) {
    return this.prisma.productCategory.findMany({
      where: { tenantId, deletedAt: null },
    });
  }

  // Products
  async createProduct(tenantId: string, data: any) {
    return this.prisma.product.create({
      data: {
        tenantId,
        categoryId: data.categoryId,
        name: data.name,
        description: data.description || null,
        price: data.price,
        sku: data.sku || null,
        stockQty: data.stockQty || 0,
      },
    });
  }

  async getProducts(tenantId: string) {
    return this.prisma.product.findMany({
      where: { tenantId, deletedAt: null },
      include: { category: true },
    });
  }

  // Stock Movement Ledger
  async addStockMovement(tenantId: string, data: any) {
    const product = await this.prisma.product.findFirst({
      where: { id: data.productId, tenantId },
    });

    if (!product) {
      throw new NotFoundException('Product not found in this salon');
    }

    const type = data.movementType as InventoryMovementType;
    const quantity = data.quantity;

    let newQty = product.stockQty;
    if (type === InventoryMovementType.IN) {
      newQty += quantity;
    } else if (type === InventoryMovementType.OUT) {
      if (product.stockQty < quantity) {
        throw new BadRequestException('Insufficient stock available');
      }
      newQty -= quantity;
    } else if (type === InventoryMovementType.ADJUSTMENT) {
      newQty = quantity; // sets absolute quantity
    }

    return this.prisma.$transaction(async (tx) => {
      const movement = await tx.inventoryMovement.create({
        data: {
          productId: product.id,
          movementType: type,
          quantity,
          reason: data.reason || null,
        },
      });

      await tx.product.update({
        where: { id: product.id },
        data: { stockQty: newQty },
      });

      return movement;
    });
  }

  // Expense Logger
  async logExpense(tenantId: string, data: any) {
    return this.prisma.expense.create({
      data: {
        tenantId,
        amount: data.amount,
        category: data.category,
        notes: data.notes || null,
      },
    });
  }

  async getExpenses(tenantId: string) {
    return this.prisma.expense.findMany({
      where: { tenantId },
      orderBy: { createdAt: 'desc' },
    });
  }
}
