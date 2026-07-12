import { NextResponse } from 'next/server';
import { backendFetch } from '@/lib/backend';
import { clearSessionCookies, getRefreshToken } from '@/lib/session';

export async function POST() {
  const refreshToken = await getRefreshToken();

  if (refreshToken) {
    await backendFetch('/auth/logout', {
      method: 'POST',
      body: JSON.stringify({ refreshToken }),
      skipAuth: true,
    }).catch(() => {
      // Best-effort — clear the local session regardless of backend outcome.
    });
  }

  await clearSessionCookies();
  return NextResponse.json({ success: true, data: { success: true } });
}
