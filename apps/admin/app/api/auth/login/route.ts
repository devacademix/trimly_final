import { NextResponse } from 'next/server';
import { backendFetch, BackendError } from '@/lib/backend';
import { setSessionCookies } from '@/lib/session';
import { UserRole, type AdminUser } from '@/types/admin';

interface AuthSession {
  accessToken: string;
  refreshToken: string;
  user: AdminUser;
}

export async function POST(request: Request) {
  const body = await request.json().catch(() => null);
  const email = typeof body?.email === 'string' ? body.email : '';
  const password = typeof body?.password === 'string' ? body.password : '';

  if (!email || !password) {
    return NextResponse.json(
      { success: false, error: { code: 'VALIDATION_FAILED', message: 'Email and password are required' } },
      { status: 400 },
    );
  }

  try {
    const session = await backendFetch<AuthSession>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
      skipAuth: true,
    });

    if (session.user.role !== UserRole.SUPER_ADMIN) {
      return NextResponse.json(
        { success: false, error: { code: 'FORBIDDEN', message: 'This account does not have super-admin access.' } },
        { status: 403 },
      );
    }

    await setSessionCookies(session.accessToken, session.refreshToken);

    return NextResponse.json({ success: true, data: { user: session.user } });
  } catch (err) {
    if (err instanceof BackendError) {
      return NextResponse.json(
        { success: false, error: { code: err.code, message: err.message } },
        { status: err.status },
      );
    }
    return NextResponse.json(
      { success: false, error: { code: 'INTERNAL_ERROR', message: 'Unable to reach the Trimly backend.' } },
      { status: 502 },
    );
  }
}
