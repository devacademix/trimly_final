import { backendFetch } from '@/lib/backend';
import { handleBackend } from '@/lib/api-route';

export async function POST(request: Request) {
  const body = await request.json().catch(() => ({}));

  return handleBackend(() =>
    backendFetch('/admin/settings/commission', {
      method: 'POST',
      body: JSON.stringify(body),
    }),
  );
}
