import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const ACCESS_TOKEN_COOKIE = 'trimly_access_token';
const PUBLIC_PATHS = ['/login'];
// Legal pages: publicly reachable (app store reviewers, users, search
// engines) regardless of login state — unlike /login they must NOT redirect
// an authenticated admin away.
const ALWAYS_PUBLIC_PATHS = ['/privacy', '/terms'];

// UX-level gate only — decodes (does not verify) the JWT to avoid an obvious
// redirect flash for logged-out users. The NestJS backend independently
// verifies the token's signature and SUPER_ADMIN role on every real request
// made from the Route Handlers in app/api/**, so this is not the security
// boundary, just routing convenience.
function decodeRole(token: string): string | null {
  try {
    const [, payloadB64] = token.split('.');
    if (!payloadB64) return null;
    const json = Buffer.from(payloadB64, 'base64url').toString('utf8');
    return (JSON.parse(json)?.role as string) ?? null;
  } catch {
    return null;
  }
}

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  if (ALWAYS_PUBLIC_PATHS.includes(pathname)) {
    return NextResponse.next();
  }

  const token = request.cookies.get(ACCESS_TOKEN_COOKIE)?.value;
  const isPublicPath = PUBLIC_PATHS.includes(pathname);

  if (isPublicPath) {
    if (token) {
      return NextResponse.redirect(new URL('/', request.url));
    }
    return NextResponse.next();
  }

  if (!token) {
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('next', pathname);
    return NextResponse.redirect(loginUrl);
  }

  const role = decodeRole(token);
  if (role !== 'SUPER_ADMIN') {
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('error', 'forbidden');
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  // Page routes only. API routes (app/api/**) are never redirected here —
  // a redirect response to a fetch() call would break JSON parsing on the
  // client. Each Route Handler under app/api/admin/** independently fails
  // closed (missing token -> the backend rejects the unauthenticated
  // request -> the handler surfaces that as a 401 JSON response).
  matcher: ['/((?!_next/static|_next/image|favicon.ico|api).*)'],
};
