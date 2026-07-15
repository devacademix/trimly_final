import { Controller, Get, Post, Patch, Body, Param, UseGuards } from '@nestjs/common';
import { PlansService } from './plans.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CreatePlanDto, UpdatePlanDto } from './dto/plans.dto';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UserRole } from '@trimly/types';

@ApiTags('Plans')
@Controller('plans')
export class PlansController {
  constructor(private readonly plansService: PlansService) {}

  @Get()
  @ApiOperation({ summary: 'Get all active subscription plans' })
  async getActivePlans() {
    const plans = await this.plansService.findAllActive();
    return { success: true, data: plans };
  }

  @Get('all')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Get all plans including inactive (Super Admin only)' })
  async getAllPlans() {
    const plans = await this.plansService.findAll();
    return { success: true, data: plans };
  }

  @Post()
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Create a new subscription plan (Super Admin only)' })
  async createPlan(@Body() data: CreatePlanDto) {
    const plan = await this.plansService.create(data);
    return { success: true, data: plan };
  }

  @Patch(':id')
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Update an existing subscription plan (Super Admin only)' })
  async updatePlan(@Param('id') id: string, @Body() data: UpdatePlanDto) {
    const plan = await this.plansService.update(id, data);
    return { success: true, data: plan };
  }
}


