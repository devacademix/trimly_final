import { Controller, Post, Get, Body, Param, Query, Res, Headers, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { PaymentService } from './payment.service';
import { ApiResponse, UserRole } from '@trimly/types';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { TenantGuard } from '../common/guards/tenant.guard';
import { TenantId } from '../common/decorators/tenant.decorator';

@ApiTags('Payment & Commission Split')
@Controller('payments')
export class PaymentController {
  constructor(private paymentService: PaymentService) {}

  @Post('checkout')
  @UseGuards(JwtAuthGuard, TenantGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Initiate a checkout session for booking (calculates platform split)' })
  async checkout(
    @TenantId() tenantId: string,
    @Body() dto: { bookingId: string },
  ): Promise<ApiResponse<any>> {
    const session = await this.paymentService.createBookingCheckout(tenantId, dto.bookingId);
    return {
      success: true,
      data: session,
    };
  }

  @Get('razorpay/checkout-page')
  @ApiOperation({ summary: 'Serve standard Razorpay hosted checkout page' })
  checkoutPage(
    @Query('orderId') orderId: string,
    @Query('keyId') keyId: string,
    @Query('amount') amount: string,
    @Res() res: any,
  ) {
    const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <title>Trimly Secure Payment</title>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              height: 100vh;
              margin: 0;
              background-color: #0c1a30;
              color: white;
            }
            .loader {
              border: 4px solid rgba(255,255,255,0.1);
              width: 36px;
              height: 36px;
              border-radius: 50%;
              border-left-color: #6366F1;
              animation: spin 1s linear infinite;
            }
            @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
          </style>
        </head>
        <body>
          <div class="loader"></div>
          <p style="margin-top: 20px; font-weight: bold;">Loading Secure Razorpay Portal...</p>
          <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
          <script>
            var options = {
              "key": "${keyId}",
              "amount": "${Number(amount) * 100}", // amount in paise
              "currency": "INR",
              "name": "Trimly Bookings",
              "description": "Secure Salon Settlement",
              "order_id": "${orderId}",
              "handler": function (response) {
                document.body.innerHTML = "<h2>Payment Successful!</h2><p>You can close this window now.</p>";
              },
              "theme": {
                "color": "#6366F1"
              }
            };
            var rzp = new Razorpay(options);
            rzp.on('payment.failed', function (response){
              document.body.innerHTML = "<h2>Payment Failed</h2><p>" + response.error.description + "</p>";
            });
            window.onload = function() {
              rzp.open();
            };
          </script>
        </body>
      </html>
    `;
    res.setHeader('Content-Type', 'text/html');
    res.send(html);
  }

  @Post('webhook')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Razorpay payment capture webhook endpoint' })
  async webhook(
    @Headers('x-razorpay-signature') signature: string,
    @Body() payload: any,
  ): Promise<any> {
    return this.paymentService.handleWebhook(signature, payload);
  }

  @Post(':id/refund')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.SUPER_ADMIN, UserRole.SALON_OWNER)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Initiate refund and reclaim platform split proportionally' })
  async refund(@Param('id') id: string): Promise<ApiResponse<any>> {
    const res = await this.paymentService.refundPayment(id);
    return {
      success: true,
      data: res,
    };
  }
}
