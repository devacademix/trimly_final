import { NextResponse } from 'next/server';
import { backendFetch, BackendError } from '@/lib/backend';

export async function GET() {
  try {
    const plans = await backendFetch('/plans/all');
    return NextResponse.json({ success: true, data: plans });
  } catch (error) {
    if (error instanceof BackendError) {
      return NextResponse.json({ success: false, error: { message: error.message } }, { status: error.status });
    }
    return NextResponse.json({ success: false, error: { message: 'Internal Server Error' } }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const plan = await backendFetch('/plans', {
      method: 'POST',
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
