import { IsEnum, IsInt, IsNotEmpty, IsNumber, IsOptional, IsPositive, IsString, IsUUID, Min } from 'class-validator';
import { InventoryMovementType } from '@trimly/database';

export class CreateCategoryDto {
  @IsString()
  @IsNotEmpty()
  name!: string;
}

export class CreateProductDto {
  @IsUUID()
  categoryId!: string;

  @IsString()
  @IsNotEmpty()
  name!: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsNumber()
  @IsPositive()
  price!: number;

  @IsOptional()
  @IsString()
  sku?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  stockQty?: number;
}

export class StockMovementDto {
  @IsUUID()
  productId!: string;

  @IsEnum(InventoryMovementType)
  movementType!: InventoryMovementType;

  @IsInt()
  @Min(0)
  quantity!: number;

  @IsOptional()
  @IsString()
  reason?: string;
}

export class LogExpenseDto {
  @IsNumber()
  @IsPositive()
  amount!: number;

  @IsString()
  @IsNotEmpty()
  category!: string;

  @IsOptional()
  @IsString()
  notes?: string;
}
