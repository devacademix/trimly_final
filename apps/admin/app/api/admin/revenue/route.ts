import { backendFetch } from '@/lib/backend';
import { handleBackend } from '@/lib/api-route';
import type { RevenueStats } from '@/types/admin';

export async function GET() {
  return handleBackend(() => backendFetch<RevenueStats>('/admin/revenue'));
}
