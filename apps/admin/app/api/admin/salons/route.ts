import { backendFetch } from '@/lib/backend';
import { handleBackend } from '@/lib/api-route';
import type { Salon } from '@/types/admin';

export async function GET() {
  return handleBackend(() => backendFetch<Salon[]>('/admin/salons'));
}
