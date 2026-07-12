// Browser-side fetch helper — calls this app's own /api/** route handlers
// (never the NestJS backend directly), so the access token stays an
// httpOnly cookie the client never sees.
export async function apiClient<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(path, {
    ...init,
    headers: { 'Content-Type': 'application/json', ...(init?.headers ?? {}) },
  });
  const body = await res.json().catch(() => null);

  if (!res.ok || !body?.success) {
    throw new Error(body?.error?.message ?? 'Request failed');
  }

  return body.data as T;
}
