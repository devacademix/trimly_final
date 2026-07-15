import { IsString, IsNumber, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateCommissionDto {
  @ApiProperty({ example: 10000 })
  @IsOptional()
  @IsNumber()
  baseSalary?: number;

  @ApiProperty({ example: 20.0 })
  @IsOptional()
  @IsNumber()
  commissionRate?: number;
}
