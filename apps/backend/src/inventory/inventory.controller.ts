import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { InventoryService } from './inventory.service';
import { ApiResponse, UserRole } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { TenantGuard } from '../common/guards/tenant.guard';
import { TenantId } from '../common/decorators/tenant.decorator';
import { CreateCategoryDto, CreateProductDto, StockMovementDto, LogExpenseDto } from './dto/inventory.dto';

@ApiTags('Inventory & Retail Products')
@ApiBearerAuth()
@ApiHeader({ name: 'x-tenant-id' })
@UseGuards(JwtAuthGuard, TenantGuard, RolesGuard)
@Roles(UserRole.SALON_OWNER, UserRole.STAFF)
@Controller('inventory')
export class InventoryController {
  constructor(private inventoryService: InventoryService) {}

  @Post('categories')
  @Roles(UserRole.SALON_OWNER)
  @ApiOperation({ summary: 'Create a new product category' })
  async createCategory(
    @TenantId() tenantId: string,
    @Body() dto: CreateCategoryDto,
  ): Promise<ApiResponse<any>> {
    const category = await this.inventoryService.createCategory(tenantId, dto.name);
    return {
      success: true,
      data: category,
    };
  }

  @Get('categories')
  @ApiOperation({ summary: 'List product categories' })
  async getCategories(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const categories = await this.inventoryService.getCategories(tenantId);
    return {
      success: true,
      data: categories,
    };
  }

  @Post('products')
  @Roles(UserRole.SALON_OWNER)
  @ApiOperation({ summary: 'Add a new retail product' })
  async createProduct(
    @TenantId() tenantId: string,
    @Body() data: CreateProductDto,
  ): Promise<ApiResponse<any>> {
    const product = await this.inventoryService.createProduct(tenantId, data);
    return {
      success: true,
      data: product,
    };
  }

  @Get('products')
  @ApiOperation({ summary: 'List retail products' })
  async getProducts(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const products = await this.inventoryService.getProducts(tenantId);
    return {
      success: true,
      data: products,
    };
  }

  @Post('movements')
  @ApiOperation({ summary: 'Log product stock level changes (IN/OUT/ADJUSTMENT)' })
  async addStockMovement(
    @TenantId() tenantId: string,
    @Body() data: StockMovementDto,
  ): Promise<ApiResponse<any>> {
    const movement = await this.inventoryService.addStockMovement(tenantId, data);
    return {
      success: true,
      data: movement,
    };
  }

  @Post('expenses')
  @Roles(UserRole.SALON_OWNER)
  @ApiOperation({ summary: 'Log salon business expense' })
  async logExpense(
    @TenantId() tenantId: string,
    @Body() data: LogExpenseDto,
  ): Promise<ApiResponse<any>> {
    const expense = await this.inventoryService.logExpense(tenantId, data);
    return {
      success: true,
      data: expense,
    };
  }

  @Get('expenses')
  @Roles(UserRole.SALON_OWNER)
  @ApiOperation({ summary: 'List salon business expenses' })
  async getExpenses(@TenantId() tenantId: string): Promise<ApiResponse<any>> {
    const expenses = await this.inventoryService.getExpenses(tenantId);
    return {
      success: true,
      data: expenses,
    };
  }
}
