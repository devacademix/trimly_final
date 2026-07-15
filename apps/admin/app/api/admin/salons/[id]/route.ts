import { backendFetch } from '@/lib/backend';
import { handleBackend } from '@/lib/api-route';

export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  return handleBackend(() =>
    backendFetch(`/admin/salons/${id}`, {
      method: 'DELETE',
    }),
  );
}
