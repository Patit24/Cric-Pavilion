import { NextRequest, NextResponse } from 'next/server';
import { store } from '@/lib/store/mock-db';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { auctionId } = body;

    if (!auctionId) {
      return NextResponse.json({ success: false, error: 'Missing auctionId' }, { status: 400 });
    }

    const selectedLot = store.spinPlayerLot(auctionId);
    if (!selectedLot) {
      return NextResponse.json({ success: false, error: 'No eligible player lots found' }, { status: 404 });
    }

    return NextResponse.json({ success: true, selectedLot });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message || 'Server error' }, { status: 500 });
  }
}
