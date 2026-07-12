import { NextResponse } from 'next/server';
import { BackendError } from './backend';

// Wraps a Route Handler body that calls backendFetch, translating any
// BackendError (or unexpected network failure) into a consistent JSON
// error response instead of an unhandled 500.
export async function handleBackend<T>(fn: () => Promise<T>): Promise<NextResponse> {
  try {
    const data = await fn();
    return NextResponse.json({ success: true, data });
  } catch (err) {
    if (err instanceof BackendError) {
      return NextResponse.json(
        { success: false, error: { code: err.code, message: err.message, fields: err.fields } },
        { status: err.status },
      );
    }
    return NextResponse.json(
      { success: false, error: { code: 'INTERNAL_ERROR', message: 'Unable to reach the Trimly backend.' } },
      { status: 502 },
    );
  }
}
