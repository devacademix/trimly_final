import { backendFetch } from '@/lib/backend';
import { handleBackend } from '@/lib/api-route';

export async function PATCH(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const body = await request.json().catch(() => ({}));

  return handleBackend(() =>
    backendFetch(`/admin/users/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    }),
  );
}
