import { backendFetch } from '@/lib/backend';
import { handleBackend } from '@/lib/api-route';
import type { Salon } from '@/types/admin';

export async function PATCH(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const body = await request.json().catch(() => ({}));

  return handleBackend(() =>
    backendFetch<Salon>(`/admin/salons/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    }),
  );
}
