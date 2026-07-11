import { Controller, Post, Body, HttpCode, HttpStatus, UnauthorizedException, Get, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UserRole, ApiResponse, AuthSession, AuthUser } from '@trimly/types';
import { ApiTags, ApiOperation, ApiResponse as ApiSwaggerResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { CurrentUser } from './decorators/current-user.decorator';

@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register')
  @ApiOperation({ summary: 'Register a new user' })
  @ApiSwaggerResponse({ status: 201, description: 'User successfully registered' })
  async register(
    @Body() dto: { email: string; password?: string; fullName: string; role: UserRole },
  ): Promise<ApiResponse<AuthUser>> {
    const user = await this.authService.register(dto);
    return {
      success: true,
      data: user,
    };
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login with email and password' })
  @ApiSwaggerResponse({ status: 200, description: 'Authentication token details' })
  async login(
    @Body() dto: { email: string; password?: string },
  ): Promise<ApiResponse<AuthSession>> {
    const session = await this.authService.login(dto);
    return {
      success: true,
      data: session,
    };
  }

  @Post('otp/send')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Send OTP code to phone number' })
  async sendOtp(
    @Body() dto: { phone: string },
  ): Promise<ApiResponse<{ success: boolean; message: string }>> {
    const res = await this.authService.sendOtp(dto.phone);
    return {
      success: true,
      data: res,
    };
  }

  @Post('otp/verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify OTP code and authenticate user' })
  async verifyOtp(
    @Body() dto: { phone: string; otp: string },
  ): Promise<ApiResponse<AuthSession>> {
    const session = await this.authService.verifyOtp(dto.phone, dto.otp);
    return {
      success: true,
      data: session,
    };
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Refresh active login session' })
  async refresh(
    @Body() dto: { refreshToken: string },
  ): Promise<ApiResponse<AuthSession>> {
    const session = await this.authService.refreshSession(dto.refreshToken);
    return {
      success: true,
      data: session,
    };
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Revoke active refresh token/session' })
  async logout(
    @Body() dto: { refreshToken: string },
  ): Promise<ApiResponse<{ success: boolean }>> {
    const res = await this.authService.logout(dto.refreshToken);
    return {
      success: true,
      data: res,
    };
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current user profile session details' })
  async me(@CurrentUser() user: any): Promise<ApiResponse<any>> {
    return {
      success: true,
      data: user,
    };
  }
}
