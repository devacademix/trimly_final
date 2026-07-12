import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { initializeApp, cert, type App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import * as fs from 'fs';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);
  private readonly firebaseApp: App | null;

  constructor(private prisma: PrismaService) {
    this.firebaseApp = this.initFirebase();
  }

  // Lazily initializes Firebase Admin from a service-account JSON file (see
  // FIREBASE_CREDENTIALS_PATH in .env.example). If it isn't configured, push
  // sends fall back to a simulated log line — same graceful-degradation
  // pattern as sendEmail/sendSMS/sendWhatsApp below.
  private initFirebase(): App | null {
    const credentialsPath = process.env.FIREBASE_CREDENTIALS_PATH;
    if (!credentialsPath) {
      return null;
    }
    try {
      if (!fs.existsSync(credentialsPath)) {
        this.logger.warn(`FIREBASE_CREDENTIALS_PATH is set but no file exists at ${credentialsPath}`);
        return null;
      }
      const serviceAccount = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
      return initializeApp({
        credential: cert(serviceAccount),
        projectId: process.env.FIREBASE_PROJECT_ID,
      });
    } catch (err) {
      this.logger.warn(`Failed to initialize Firebase Admin SDK: ${(err as Error).message}`);
      return null;
    }
  }

  // Saves the current device's FCM token so sendPush() can target it.
  async registerDeviceToken(userId: string, token: string): Promise<void> {
    await this.prisma.user.update({ where: { id: userId }, data: { fcmToken: token } });
  }

  // 1. Core Transports
  async sendEmail(to: string, subject: string, body: string): Promise<boolean> {
    const smtpHost = process.env.SMTP_HOST;
    console.info(`[EMAIL SENDER] To: ${to} | Subject: ${subject}`);
    if (smtpHost) {
      // Real Nodemailer/SMTP client dispatch would go here.
    }
    return true;
  }

  async sendSMS(to: string, message: string): Promise<boolean> {
    const twilioSid = process.env.TWILIO_ACCOUNT_SID;
    console.info(`[SMS SENDER] To: ${to} | Message: ${message}`);
    if (twilioSid) {
      // Real Twilio API client dispatch would go here.
    }
    return true;
  }

  async sendWhatsApp(to: string, template: string, variables: Record<string, string>): Promise<boolean> {
    const waToken = process.env.WHATSAPP_ACCESS_TOKEN;
    console.info(`[WHATSAPP SENDER] To: ${to} | Template: ${template} | Variables: ${JSON.stringify(variables)}`);
    if (waToken) {
      // Real WhatsApp Business Cloud API payload dispatch would go here.
    }
    return true;
  }

  async sendPush(userId: string, title: string, body: string): Promise<boolean> {
    if (!this.firebaseApp) {
      console.info(`[PUSH SENDER - SIMULATED, no Firebase credentials configured] User: ${userId} | Title: ${title} | Body: ${body}`);
      return true;
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { fcmToken: true } });
    if (!user?.fcmToken) {
      this.logger.debug(`Skipping push for user ${userId}: no registered device token`);
      return false;
    }

    try {
      await getMessaging(this.firebaseApp).send({
        token: user.fcmToken,
        notification: { title, body },
      });
      return true;
    } catch (err) {
      this.logger.warn(`Failed to send push to user ${userId}: ${(err as Error).message}`);
      return false;
    }
  }

  // 2. Booking Triggers
  async notifyBookingCreated(bookingId: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        customer: true,
        tenant: true,
      },
    });

    if (booking) {
      const customerEmail = booking.customer.email;
      const customerPhone = booking.customer.phone;
      const salonName = booking.tenant.name;

      if (customerEmail) {
        await this.sendEmail(
          customerEmail,
          `Booking Request Placed - ${salonName}`,
          `Hi ${booking.customer.fullName || 'Customer'}, your booking request for ${booking.startTime.toISOString()} at ${salonName} has been received.`,
        );
      }

      if (customerPhone) {
        await this.sendSMS(
          customerPhone,
          `Your booking request for ${booking.startTime.toISOString()} at ${salonName} has been received. We will update you once confirmed.`,
        );

        await this.sendWhatsApp(customerPhone, 'booking_created_customer', {
          customerName: booking.customer.fullName || 'Customer',
          salonName,
          bookingTime: booking.startTime.toISOString(),
        });
      }

      // Notify Salon Owner/Staff (simulating notifications to owner user)
      if (booking.tenant.ownerEmail) {
        await this.sendEmail(
          booking.tenant.ownerEmail,
          'New Booking Request Alert',
          `A new booking request has been placed by ${booking.customer.fullName || 'Customer'} for ${booking.startTime.toISOString()}.`,
        );
      }
    }
  }

  async notifyBookingStatusChange(bookingId: string, status: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { customer: true, tenant: true },
    });

    if (booking) {
      const customerEmail = booking.customer.email;
      const customerPhone = booking.customer.phone;
      const salonName = booking.tenant.name;

      if (customerEmail) {
        await this.sendEmail(
          customerEmail,
          `Booking Status Update - ${status}`,
          `Hi ${booking.customer.fullName || 'Customer'}, your booking at ${salonName} is now ${status.toUpperCase()}.`,
        );
      }

      if (customerPhone) {
        await this.sendSMS(
          customerPhone,
          `Your booking at ${salonName} is now ${status.toUpperCase()}. Time: ${booking.startTime.toISOString()}.`,
        );
      }

      // Send Push notification to customer device
      await this.sendPush(
        booking.customerId,
        `Booking ${status.toLowerCase()}`,
        `Your appointment at ${salonName} is now ${status.toLowerCase()}.`,
      );
    }
  }

  // 3. Payment Success Trigger
  async notifyPaymentSuccess(paymentId: string) {
    const payment = await this.prisma.payment.findUnique({
      where: { id: paymentId },
      include: {
        booking: {
          include: { customer: true, tenant: true },
        },
      },
    });

    if (payment) {
      const booking = payment.booking;
      const customerEmail = booking.customer.email;
      const customerPhone = booking.customer.phone;

      if (customerEmail) {
        await this.sendEmail(
          customerEmail,
          'Payment Successful - Invoice Receipt',
          `Invoice Receipt: INR ${payment.amount} captured for booking id ${booking.id}. Thank you!`,
        );
      }

      if (customerPhone) {
        await this.sendWhatsApp(customerPhone, 'payment_success_customer', {
          customerName: booking.customer.fullName || 'Customer',
          amount: payment.amount.toString(),
          invoiceUrl: `http://localhost:4000/api/v1/invoices/${booking.id}.pdf`,
        });
      }
    }
  }
}
