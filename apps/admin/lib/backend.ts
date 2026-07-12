import { getAccessToken, getRefreshToken, setSessionCookies } from './session';

const BACKEND_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:4000/api/v1';

export class BackendError extends Error {
  status: number;
  code: string;
  fields?: Record<string, string[]>;

  constructor(status: number, code: string, message: string, fields?: Record<string, string[]>) {
    super(message);
    this.name = 'BackendError';
    this.status = status;
    this.code = code;
    this.fields = fields;
  }
}

interface BackendFetchOptions extends RequestInit {
  /** Skip attaching the access token / retrying on 401 (e.g. the login call itself). */
  skipAuth?: boolean;
}

// Server-only. Calls the NestJS backend with the caller's access token,
// transparently refreshing the session once on a 401 before giving up.
// Intended to be used from Next.js Route Handlers, which can both read the
// incoming cookies and set new ones on the outgoing response.
export async function backendFetch<T>(path: string, init: BackendFetchOptions = {}): Promise<T> {
  const { skipAuth, ...rest } = init;
  const token = skipAuth ? undefined : await getAccessToken();

  let res = await rawFetch(path, rest, token);

  if (res.status === 401 && !skipAuth) {
    const refreshedToken = await tryRefresh();
    if (refreshedToken) {
      res = await rawFetch(path, rest, refreshedToken);
    }
  }

  return parseResponse<T>(res);
}

async function rawFetch(path: string, init: RequestInit, token: string | undefined): Promise<Response> {
  return fetch(`${BACKEND_URL}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(init.headers ?? {}),
    },
    cache: 'no-store',
  });
}

async function parseResponse<T>(res: Response): Promise<T> {
  const body = await res.json().catch(() => null);

  if (!res.ok || body?.success === false) {
    const error = body?.error;
    throw new BackendError(
      res.status,
      error?.code ?? 'UNKNOWN',
      error?.message ?? 'Request failed',
      error?.fields,
    );
  }

  return body.data as T;
}

async function tryRefresh(): Promise<string | null> {
  const refreshToken = await getRefreshToken();
  if (!refreshToken) return null;

  const res = await fetch(`${BACKEND_URL}/auth/refresh`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken }),
    cache: 'no-store',
  });
  if (!res.ok) return null;

  const body = await res.json().catch(() => null);
  if (!body?.success) return null;

  await setSessionCookies(body.data.accessToken, body.data.refreshToken);
  return body.data.accessToken as string;
}
