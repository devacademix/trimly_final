import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { NotificationService } from './notification.service';
import { ApiResponse, UserRole } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@ApiTags('Unified Notification System')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SUPER_ADMIN)
@Controller('notifications')
export class NotificationController {
  constructor(private notifService: NotificationService) {}

  @Post('test-email')
  @ApiOperation({ summary: 'Send a test email notification' })
  async testEmail(
    @Body() dto: { to: string; subject: string; body: string },
  ): Promise<ApiResponse<any>> {
    const success = await this.notifService.sendEmail(dto.to, dto.subject, dto.body);
    return {
      success: true,
      data: { success, message: 'Test email processed' },
    };
  }

  @Post('test-sms')
  @ApiOperation({ summary: 'Send a test SMS notification' })
  async testSMS(
    @Body() dto: { to: string; message: string },
  ): Promise<ApiResponse<any>> {
    const success = await this.notifService.sendSMS(dto.to, dto.message);
    return {
      success: true,
      data: { success, message: 'Test SMS processed' },
    };
  }
}
