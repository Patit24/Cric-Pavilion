import { NextRequest, NextResponse } from 'next/server';
import { store } from '@/lib/store/mock-db';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { auctionId, poolId } = body;

    if (!auctionId || !poolId) {
      return NextResponse.json({ success: false, error: 'Missing auctionId or poolId' }, { status: 400 });
    }

    const result = store.confirmSold(auctionId, poolId);
    if (!result.success) {
      return NextResponse.json(result, { status: 400 });
    }

    return NextResponse.json(result);
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message || 'Server error' }, { status: 500 });
  }
}
