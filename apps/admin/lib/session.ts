import { cookies } from 'next/headers';

export const ACCESS_TOKEN_COOKIE = 'trimly_access_token';
export const REFRESH_TOKEN_COOKIE = 'trimly_refresh_token';

const isProd = process.env.NODE_ENV === 'production';
const isSecureCookie = process.env.COOKIE_SECURE === 'false' ? false : isProd;

interface JwtPayload {
  sub: string;
  email?: string;
  role?: string;
  exp?: number;
  iat?: number;
}

// Decodes (does NOT verify) a JWT's payload — safe for UX-level checks only
// (e.g. "should the proxy redirect to /login"). The real authorization
// boundary is the NestJS backend, which verifies the signature on every
// request forwarded with this token.
export function decodeJwtPayload(token: string): JwtPayload | null {
  try {
    const [, payloadB64] = token.split('.');
    if (!payloadB64) return null;
    const json = Buffer.from(payloadB64, 'base64url').toString('utf8');
    return JSON.parse(json) as JwtPayload;
  } catch {
    return null;
  }
}

export function isJwtExpired(token: string): boolean {
  const payload = decodeJwtPayload(token);
  if (!payload?.exp) return true;
  return payload.exp * 1000 <= Date.now();
}

export async function getAccessToken(): Promise<string | undefined> {
  const store = await cookies();
  return store.get(ACCESS_TOKEN_COOKIE)?.value;
}

export async function getRefreshToken(): Promise<string | undefined> {
  const store = await cookies();
  return store.get(REFRESH_TOKEN_COOKIE)?.value;
}

// Only callable from a Route Handler / Server Function (Next.js forbids
// mutating cookies during Server Component render).
export async function setSessionCookies(accessToken: string, refreshToken: string) {
  const store = await cookies();
  const accessPayload = decodeJwtPayload(accessToken);
  const accessMaxAge = accessPayload?.exp ? Math.max(accessPayload.exp - Math.floor(Date.now() / 1000), 60) : 60 * 15;

  store.set(ACCESS_TOKEN_COOKIE, accessToken, {
    httpOnly: true,
    secure: isSecureCookie,
    sameSite: 'lax',
    path: '/',
    maxAge: accessMaxAge,
  });
  store.set(REFRESH_TOKEN_COOKIE, refreshToken, {
    httpOnly: true,
    secure: isSecureCookie,
    sameSite: 'lax',
    path: '/',
    maxAge: 60 * 60 * 24 * 30,
  });
}

export async function clearSessionCookies() {
  const store = await cookies();
  store.delete(ACCESS_TOKEN_COOKIE);
  store.delete(REFRESH_TOKEN_COOKIE);
}
