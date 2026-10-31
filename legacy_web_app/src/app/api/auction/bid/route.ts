import { NextRequest, NextResponse } from 'next/server';
import { store } from '@/lib/store/mock-db';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { auctionId, teamId, userId, amount } = body;

    if (!auctionId || !teamId || !userId) {
      return NextResponse.json({ success: false, error: 'Missing required parameters' }, { status: 400 });
    }

    const result = store.placeBid({
      auctionId,
      teamId,
      userId,
      amount,
    });

    if (!result.success) {
      return NextResponse.json(result, { status: 400 });
    }

    return NextResponse.json(result);
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message || 'Server error' }, { status: 500 });
  }
}
