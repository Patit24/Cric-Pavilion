import { NextRequest, NextResponse } from 'next/server';
import { store } from '@/lib/store/mock-db';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const {
      inningsId,
      strikerId,
      nonStrikerId,
      bowlerId,
      runsBatter,
      extrasType,
      extrasRuns,
      isWicket,
      dismissalType,
      dismissedPlayerId,
      assistedByPlayerId,
      nextBatterId,
      commentaryText,
    } = body;

    if (!inningsId || !strikerId || !nonStrikerId || !bowlerId) {
      return NextResponse.json({ success: false, error: 'Missing required match delivery parameters' }, { status: 400 });
    }

    const result = store.recordDelivery({
      inningsId,
      strikerId,
      nonStrikerId,
      bowlerId,
      runsBatter: runsBatter || 0,
      extrasType,
      extrasRuns: extrasRuns || 0,
      isWicket: Boolean(isWicket),
      dismissalType,
      dismissedPlayerId,
      assistedByPlayerId,
      nextBatterId,
      commentaryText,
    });

    if (!result.success) {
      return NextResponse.json(result, { status: 400 });
    }

    return NextResponse.json(result);
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message || 'Server error' }, { status: 500 });
  }
}
