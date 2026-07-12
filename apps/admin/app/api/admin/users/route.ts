import { backendFetch } from '@/lib/backend';
import { handleBackend } from '@/lib/api-route';
import type { PlatformUser } from '@/types/admin';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const role = searchParams.get('role');
  const query = role ? `?role=${encodeURIComponent(role)}` : '';

  return handleBackend(() => backendFetch<PlatformUser[]>(`/admin/users${query}`));
}
