import { NextResponse } from 'next/server';
import { backendFetch, BackendError } from '@/lib/backend';
import type { AdminUser } from '@/types/admin';

export async function GET() {
  try {
    const user = await backendFetch<AdminUser>('/auth/me');
    return NextResponse.json({ success: true, data: user });
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
