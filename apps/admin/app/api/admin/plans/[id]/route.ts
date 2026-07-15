import { NextResponse } from 'next/server';
import { backendFetch, BackendError } from '@/lib/backend';

export async function PATCH(req: Request, context: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await context.params;
    const body = await req.json();
    const plan = await backendFetch(`/plans/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    });
    return NextResponse.json({ success: true, data: plan });
  } catch (error) {
    if (error instanceof BackendError) {
      return NextResponse.json({ success: false, error: { message: error.message, fields: error.fields } }, { status: error.status });
    }
    return NextResponse.json({ success: false, error: { message: 'Internal Server Error' } }, { status: 500 });
  }
}
