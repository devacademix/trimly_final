import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { NotificationService } from './notification.service';
import { ApiResponse, UserRole } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { TestEmailDto, TestSmsDto, RegisterDeviceTokenDto } from './dto/notification.dto';

@ApiTags('Unified Notification System')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationController {
  constructor(private notifService: NotificationService) {}

  @Post('device-token')
  @ApiOperation({ summary: 'Register (or refresh) the current device\'s FCM push token' })
  async registerDeviceToken(
    @CurrentUser() user: any,
    @Body() dto: RegisterDeviceTokenDto,
  ): Promise<ApiResponse<{ success: boolean }>> {
    await this.notifService.registerDeviceToken(user.id, dto.token);
    return { success: true, data: { success: true } };
  }

  @Post('test-email')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Send a test email notification' })
  async testEmail(@Body() dto: TestEmailDto): Promise<ApiResponse<any>> {
    const success = await this.notifService.sendEmail(dto.to, dto.subject, dto.body);
    return {
      success: true,
      data: { success, message: 'Test email processed' },
    };
  }

  @Post('test-sms')
  @UseGuards(RolesGuard)
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Send a test SMS notification' })
  async testSMS(@Body() dto: TestSmsDto): Promise<ApiResponse<any>> {
    const success = await this.notifService.sendSMS(dto.to, dto.message);
    return {
      success: true,
      data: { success, message: 'Test SMS processed' },
    };
  }
}
