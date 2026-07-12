import { backendFetch } from '@/lib/backend';
import { handleBackend } from '@/lib/api-route';
import type { AdminBooking } from '@/types/admin';

export async function GET() {
  return handleBackend(() => backendFetch<AdminBooking[]>('/admin/bookings'));
}
