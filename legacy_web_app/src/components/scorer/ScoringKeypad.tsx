'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { Delivery, DismissalType, ExtrasType, Innings, Match, Player } from '@/lib/types';
import { store } from '@/lib/store/mock-db';
import { generateCommentaryLine } from '@/lib/cricket-engine/commentary';
import {
  validateBowlerEligibility,
  getAvailableIncomingBatsmen,
  getDismissedPlayerIds,
  getPreviousOverBowlerId,
} from '@/lib/cricket-engine/rules';
import {
  RotateCcw,
  AlertCircle,
  CheckCircle2,
  Users,
  Radio,
  Flame,
  ArrowRightLeft,
  X,
  Wifi,
  WifiOff,
  UserCheck,
  ChevronRight,
  Shield,
  Zap,
  Lock,
} from 'lucide-react';

interface ScoringKeypadProps {
  match: Match;
  innings: Innings;
  striker: Player | null;
  nonStriker: Player | null;
  bowler: Player | null;
  battingTeamPlayers: Player[];
  bowlingTeamPlayers: Player[];
  recentDeliveries: Delivery[];
}

export default function ScoringKeypad({
  match,
  innings,
  striker,
  nonStriker,
  bowler,
  battingTeamPlayers,
  bowlingTeamPlayers,
  recentDeliveries,
}: ScoringKeypadProps) {
  // Modal states
  const [showExtrasModal, setShowExtrasModal] = useState(false);
  const [showWicketModal, setShowWicketModal] = useState(false);
  const [showOverCompleteModal, setShowOverCompleteModal] = useState(false);
  const [showBowlerModal, setShowBowlerModal] = useState(false);
  const [showInnings1CompleteModal, setShowInnings1CompleteModal] = useState(false);
  const [showMatchCompleteModal, setShowMatchCompleteModal] = useState(false);
  const [showFullScorecardModal, setShowFullScorecardModal] = useState(false);
  const [isOnline, setIsOnline] = useState(true);

  // Over complete summary info
  const [completedOverNumber, setCompletedOverNumber] = useState<number>(0);
  const [previousBowlerId, setPreviousBowlerId] = useState<string | null>(null);

  // Extras state
  const [selectedExtraType, setSelectedExtraType] = useState<ExtrasType>('wide');
  const [extrasRuns, setExtrasRuns] = useState<number>(1);

  // Wicket dismissal state
  const [dismissalType, setDismissalType] = useState<DismissalType>('caught');
  const [dismissedBatterId, setDismissedBatterId] = useState<string>('');
  const [catcherType, setCatcherType] = useState<'fielder' | 'keeper' | 'bowler'>('fielder');
  const [catcherFielderId, setCatcherFielderId] = useState<string>('');
  const [runoutCompletedRuns, setRunoutCompletedRuns] = useState<number>(0);
  const [runoutThrowerId, setRunoutThrowerId] = useState<string>('');
  const [runoutBrokenBy, setRunoutBrokenBy] = useState<string>('direct_hit');
  const [nextBatterId, setNextBatterId] = useState<string>('');
  const [wicketStep, setWicketStep] = useState<1 | 2>(1); // 1 = dismissal details, 2 = select new batsman

  const maxOversPerBowler = Math.ceil(match.overs / 5); // 4 overs in T20

  // Real-time Batting and Bowling Scorecards from Store
  const allBattingCards = store.getState().battingScorecards.filter(
    (b) => b.inningsId === innings.id
  );
  const allBowlingCards = store.getState().bowlingScorecards.filter(
    (b) => b.inningsId === innings.id
  );

  const strikerScorecard = allBattingCards.find((b) => b.playerId === striker?.id) || {
    runs: 0,
    balls: 0,
    fours: 0,
    sixes: 0,
    strikeRate: 0,
  };

  const nonStrikerScorecard = allBattingCards.find((b) => b.playerId === nonStriker?.id) || {
    runs: 0,
    balls: 0,
    fours: 0,
    sixes: 0,
    strikeRate: 0,
  };

  const bowlerScorecard = allBowlingCards.find((b) => b.playerId === bowler?.id) || {
    oversStr: '0.0',
    maidens: 0,
    runsConceded: 0,
    wickets: 0,
    economy: 0,
  };

  // Derive previous over bowler from official cricket rules
  const rulePrevBowlerId = getPreviousOverBowlerId(
    store.getState().deliveries,
    innings.id,
    innings.legalBalls
  );
  const effectivePrevBowlerId = rulePrevBowlerId || previousBowlerId;

  // Get dismissed player IDs
  const allDismissedIds = getDismissedPlayerIds(store.getState().deliveries, innings.id);
  store.getState().battingScorecards
    .filter((b) => b.inningsId === innings.id && b.isOut)
    .forEach((b) => allDismissedIds.add(b.playerId));

  // Eligible incoming batsmen (CANNOT BE ALREADY DISMISSED OR CURRENTLY BATTING)
  const availableDugoutBatsmen = getAvailableIncomingBatsmen({
    battingTeamPlayers,
    deliveries: store.getState().deliveries,
    inningsId: innings.id,
    currentStrikerId: striker?.id || null,
    currentNonStrikerId: nonStriker?.id || null,
    dismissedPlayerId: dismissedBatterId || striker?.id,
  });

  const isAllOutAfterThis = innings.wickets + 1 >= 10 || availableDugoutBatsmen.length === 0;

  // Auto-open bowler selection modal if no bowler is selected on an active innings
  useEffect(() => {
    if (!bowler && !innings.isCompleted) {
      const overNum = Math.floor(innings.legalBalls / 6);
      setCompletedOverNumber(overNum);
      setShowOverCompleteModal(true);
    }
  }, [bowler, innings.legalBalls, innings.isCompleted]);

  // Sync dismissed batter default when modal opens
  useEffect(() => {
    if (showWicketModal) {
      setDismissedBatterId(striker?.id || '');
      setWicketStep(1);
      if (availableDugoutBatsmen.length > 0) {
        setNextBatterId(availableDugoutBatsmen[0].id);
      } else {
        setNextBatterId('');
      }
    }
  }, [showWicketModal, striker?.id]);

  const handleRecordBall = (params: {
    runsBatter: number;
    extrasType?: ExtrasType | null;
    extrasRuns?: number;
    isWicket?: boolean;
    dismissalType?: DismissalType | null;
    dismissedPlayerId?: string | null;
    assistedByPlayerId?: string | null;
    nextBatterId?: string | null;
  }) => {
    // Guard: Prevent recording once innings is finished
    if (innings.isCompleted || innings.legalBalls >= match.overs * 6 || innings.wickets >= 10) {
      if (innings.inningsNumber === 1) {
        setShowInnings1CompleteModal(true);
      } else {
        setShowMatchCompleteModal(true);
      }
      return;
    }

    if (!striker || !nonStriker || !bowler) {
      if (!bowler) {
        setShowOverCompleteModal(true);
      } else {
        alert('Please ensure both Striker and Non-Striker are selected.');
      }
      return;
    }

    const currentBowlerId = bowler.id;

    const commText = generateCommentaryLine({
      bowlerName: bowler.displayName || bowler.fullName,
      strikerName: striker.displayName || striker.fullName,
      runs: params.runsBatter,
      extrasType: params.extrasType,
      extrasRuns: params.extrasRuns,
      isWicket: params.isWicket,
      dismissalType: params.dismissalType,
      assistName: params.assistedByPlayerId
        ? bowlingTeamPlayers.find((p) => p.id === params.assistedByPlayerId)?.displayName
        : undefined,
    });

    const res = store.recordDelivery({
      inningsId: innings.id,
      strikerId: striker.id,
      nonStrikerId: nonStriker.id,
      bowlerId: bowler.id,
      runsBatter: params.runsBatter,
      extrasType: params.extrasType,
      extrasRuns: params.extrasRuns,
      isWicket: params.isWicket,
      dismissalType: params.dismissalType,
      dismissedPlayerId: params.dismissedPlayerId,
      assistedByPlayerId: params.assistedByPlayerId,
      nextBatterId: params.nextBatterId,
      commentaryText: commText,
    });

    // Check if Innings 1 is completed
    if (res.isFirstInningsComplete) {
      setShowInnings1CompleteModal(true);
      return;
    }

    // Check if match won
    if (res.isMatchWon) {
      setShowMatchCompleteModal(true);
      return;
    }

    // Check if over completed!
    if (res.isOverComplete && !res.isMatchWon && !res.isAllOut) {
      const overNum = Math.floor((res.updatedInnings?.legalBalls || innings.legalBalls) / 6);
      setCompletedOverNumber(overNum);
      setPreviousBowlerId(currentBowlerId);
      setShowOverCompleteModal(true);
    }
  };

  const handleSelectNewBowler = (newBowlerId: string) => {
    // Validate bowler eligibility
    const eligibility = validateBowlerEligibility({
      bowlerId: newBowlerId,
      previousOverBowlerId: effectivePrevBowlerId,
      deliveries: store.getState().deliveries,
      inningsId: innings.id,
      maxOversPerBowler,
    });

    if (!eligibility.isEligible) {
      alert(`Invalid Bowler: ${eligibility.reason}`);
      return;
    }

    store.setBowler(innings.id, newBowlerId);
    setPreviousBowlerId(effectivePrevBowlerId);
    setShowOverCompleteModal(false);
    setShowBowlerModal(false);
  };

  const handleSwapEnds = () => {
    if (!striker || !nonStriker) return;
    store.setBatters(innings.id, nonStriker.id, striker.id);
  };

  const handleUndo = () => {
    store.undoLastDelivery(innings.id);
  };

  // Run Rates
  const completedOversDecimal = innings.legalBalls / 6;
  const currentRunRate =
    completedOversDecimal > 0 ? (innings.totalRuns / completedOversDecimal).toFixed(2) : '0.00';
  const runsRemaining = innings.targetRuns ? innings.targetRuns - innings.totalRuns : null;
  const ballsRemaining = match.overs * 6 - innings.legalBalls;
  const reqRunRate =
    runsRemaining && ballsRemaining > 0
      ? ((runsRemaining / ballsRemaining) * 6).toFixed(2)
      : null;

  // Wicketkeeper of bowling team
  const wicketKeeper =
    bowlingTeamPlayers.find((p) => p.role === 'wicket_keeper') || bowlingTeamPlayers[1];

  return (
    <div className="w-full max-w-xl mx-auto space-y-4">
      {/* Synchronization & Connection Status Bar */}
      <div className="flex items-center justify-between px-4 py-2 bg-slate-900 rounded-2xl text-xs text-white shadow-xs">
        <div className="flex items-center gap-2">
          {isOnline ? (
            <>
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
              <span className="text-emerald-400 font-semibold flex items-center gap-1">
                <Wifi size={13} /> Live Match Connected
              </span>
            </>
          ) : (
            <>
              <span className="w-2.5 h-2.5 rounded-full bg-amber-400"></span>
              <span className="text-amber-400 font-semibold flex items-center gap-1">
                <WifiOff size={13} /> Offline Queue Active
              </span>
            </>
          )}
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowFullScorecardModal(true)}
            className="flex items-center gap-1.5 px-3 py-1 rounded-lg bg-cricket-700 hover:bg-cricket-600 text-white font-bold text-xs transition border border-cricket-600 active:scale-95 shadow-xs"
            title="Inspect full batting and bowling scorecard"
          >
            <span>📊 Full Scorecard</span>
          </button>

          <button
            onClick={handleUndo}
            className="flex items-center gap-1.5 px-3 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold text-xs transition border border-slate-700 active:scale-95 shadow-xs"
            title="Undo last recorded delivery"
          >
            <RotateCcw size={13} />
            <span>Undo</span>
          </button>
        </div>
      </div>

      {/* Main High-Contrast Scoreboard Banner */}
      <div className="p-5 rounded-3xl bg-gradient-to-br from-cricket-900 via-cricket-950 to-slate-950 text-white shadow-xl border border-cricket-800/60">
        <div className="flex items-center justify-between text-xs text-cricket-300 font-semibold">
          <span>{match.stage} • Innings {innings.inningsNumber}</span>
          <span>Max {match.overs} Overs ({maxOversPerBowler} ov/bowler)</span>
        </div>

        <div className="flex items-baseline justify-between mt-2">
          <div>
            <div className="text-4xl sm:text-5xl font-black tracking-tight text-white">
              {innings.totalRuns}
              <span className="text-cricket-400">/{innings.wickets}</span>
            </div>
            <div className="text-xs text-slate-300 font-medium mt-0.5">
              Overs: <strong className="text-white font-mono text-sm">{innings.oversStr}</strong> ({innings.legalBalls} balls)
            </div>
          </div>

          <div className="text-right">
            <div className="text-xs text-slate-400">CRR: <strong className="text-cricket-400">{currentRunRate}</strong></div>
            {innings.targetRuns && (
              <div className="text-xs text-amber-300 mt-0.5">
                Target: <strong>{innings.targetRuns}</strong> (Need {runsRemaining} from {ballsRemaining}b, RRR: {reqRunRate})
              </div>
            )}
          </div>
        </div>

        {/* Real-Time Batters & Bowler at Crease HUD */}
        <div className="mt-4 pt-3 border-t border-cricket-800/80 space-y-3 text-xs">
          {/* Batters on Crease Table */}
          <div className="p-3.5 rounded-2xl bg-cricket-950/80 border border-cricket-800/60 shadow-inner space-y-2">
            <div className="flex items-center justify-between pb-1.5 border-b border-cricket-800/60">
              <span className="text-[10px] text-cricket-400 uppercase font-black tracking-widest">
                Batters at Crease
              </span>
              <button
                onClick={handleSwapEnds}
                className="text-[11px] text-amber-400 hover:text-amber-300 flex items-center gap-1 font-bold underline transition"
                title="Swap striker and non-striker ends"
              >
                <ArrowRightLeft size={11} />
                <span>Swap Ends</span>
              </button>
            </div>

            {/* Batters Table Header */}
            <div className="grid grid-cols-12 text-[10px] font-black uppercase text-slate-400 pb-0.5 px-1">
              <span className="col-span-5">Batter</span>
              <span className="col-span-2 text-right">R (B)</span>
              <span className="col-span-1 text-right">4s</span>
              <span className="col-span-1 text-right">6s</span>
              <span className="col-span-3 text-right">SR</span>
            </div>

            {/* Striker Row */}
            <div className="grid grid-cols-12 items-center py-1.5 px-2 rounded-xl bg-cricket-900/80 border border-cricket-700/60 text-white font-bold text-xs">
              <div className="col-span-5 flex items-center gap-1.5 truncate">
                <span className="text-amber-400 text-sm">★</span>
                <span className="truncate">{striker?.displayName || 'Striker'}</span>
                <span className="text-[9px] px-1 py-0.2 rounded bg-amber-400/25 text-amber-300 font-mono shrink-0 uppercase tracking-tighter">
                  Strike
                </span>
              </div>
              <div className="col-span-2 text-right font-black text-amber-300">
                {strikerScorecard.runs} <span className="text-slate-400 font-normal text-[10px]">({strikerScorecard.balls})</span>
              </div>
              <div className="col-span-1 text-right text-slate-300 font-mono">
                {strikerScorecard.fours}
              </div>
              <div className="col-span-1 text-right text-slate-300 font-mono">
                {strikerScorecard.sixes}
              </div>
              <div className="col-span-3 text-right font-mono text-emerald-400 text-[11px]">
                {strikerScorecard.strikeRate.toFixed(1)}
              </div>
            </div>

            {/* Non-Striker Row */}
            <div className="grid grid-cols-12 items-center py-1.5 px-2 rounded-xl text-slate-300 font-medium text-xs hover:bg-cricket-900/40">
              <div className="col-span-5 flex items-center gap-1.5 truncate text-slate-200">
                <span className="text-slate-600 text-sm">•</span>
                <span className="truncate">{nonStriker?.displayName || 'Non-Striker'}</span>
              </div>
              <div className="col-span-2 text-right font-bold text-slate-200">
                {nonStrikerScorecard.runs} <span className="text-slate-400 font-normal text-[10px]">({nonStrikerScorecard.balls})</span>
              </div>
              <div className="col-span-1 text-right text-slate-400 font-mono">
                {nonStrikerScorecard.fours}
              </div>
              <div className="col-span-1 text-right text-slate-400 font-mono">
                {nonStrikerScorecard.sixes}
              </div>
              <div className="col-span-3 text-right font-mono text-slate-400 text-[11px]">
                {nonStrikerScorecard.strikeRate.toFixed(1)}
              </div>
            </div>
          </div>

          {/* Bowler on Crease Table */}
          <div className={`p-3.5 rounded-2xl border space-y-2 ${
            !bowler
              ? 'bg-amber-950/60 border-amber-500/80 ring-2 ring-amber-500/50'
              : 'bg-cricket-950/80 border-cricket-800/60 shadow-inner'
          }`}>
            <div className="flex items-center justify-between pb-1.5 border-b border-cricket-800/60">
              <span className="text-[10px] text-cricket-400 uppercase font-black tracking-widest">
                Active Bowler
              </span>
              <button
                onClick={() => setShowBowlerModal(true)}
                className={`py-1 px-2.5 rounded-lg text-[11px] font-black transition flex items-center gap-1 border ${
                  !bowler
                    ? 'bg-amber-500 hover:bg-amber-400 text-slate-950 border-amber-400 shadow-sm'
                    : 'bg-cricket-900 hover:bg-cricket-800 text-cricket-300 border-cricket-700/60'
                }`}
              >
                <span>{bowler ? 'Change Bowler' : 'Choose Bowler'}</span>
                <ChevronRight size={11} />
              </button>
            </div>

            {bowler ? (
              <>
                {/* Bowling Table Header */}
                <div className="grid grid-cols-12 text-[10px] font-black uppercase text-slate-400 pb-0.5 px-1">
                  <span className="col-span-4">Bowler</span>
                  <span className="col-span-2 text-right">O</span>
                  <span className="col-span-1 text-right">M</span>
                  <span className="col-span-2 text-right">R</span>
                  <span className="col-span-1 text-right">W</span>
                  <span className="col-span-2 text-right">ECON</span>
                </div>

                {/* Bowler Row */}
                <div className="grid grid-cols-12 items-center py-1.5 px-2 rounded-xl bg-cricket-900/80 border border-cricket-700/60 text-white font-bold text-xs">
                  <div className="col-span-4 truncate">
                    <span className="block truncate font-bold text-white">{bowler.displayName}</span>
                    <span className="text-[10px] text-slate-400 capitalize font-normal truncate block">
                      {bowler.bowlingStyle.replace(/_/g, ' ')}
                    </span>
                  </div>
                  <div className="col-span-2 text-right font-mono text-white">
                    {bowlerScorecard.oversStr}
                  </div>
                  <div className="col-span-1 text-right font-mono text-slate-300">
                    {bowlerScorecard.maidens}
                  </div>
                  <div className="col-span-2 text-right font-mono text-white font-black">
                    {bowlerScorecard.runsConceded}
                  </div>
                  <div className="col-span-1 text-right font-mono text-amber-300 font-black">
                    {bowlerScorecard.wickets}
                  </div>
                  <div className="col-span-2 text-right font-mono text-emerald-400 text-[11px]">
                    {bowlerScorecard.economy.toFixed(2)}
                  </div>
                </div>
              </>
            ) : (
              <div className="py-2 text-center">
                <span className="text-amber-400 font-bold text-xs block animate-pulse">
                  ⚠️ Over completed — Select bowler for next over
                </span>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Over Complete Bowler Banner if bowler is not yet chosen */}
      {!bowler && !innings.isCompleted && (
        <div className="p-4 rounded-2xl bg-amber-500/15 border-2 border-dashed border-amber-500 text-amber-950 flex flex-col sm:flex-row items-center justify-between gap-3 shadow-sm animate-pulse">
          <div className="flex items-center gap-2.5">
            <AlertCircle size={22} className="text-amber-600 shrink-0" />
            <div>
              <span className="font-black text-xs uppercase tracking-wider text-amber-950 block">
                Over Completed — Select Next Bowler
              </span>
              <span className="text-[11px] text-amber-800">
                Law 17.8: Same bowler cannot bowl consecutive overs. Select an eligible bowler to unlock keypad.
              </span>
            </div>
          </div>
          <button
            onClick={() => setShowOverCompleteModal(true)}
            className="w-full sm:w-auto px-4 py-2 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-black text-xs shrink-0 shadow-sm flex items-center justify-center gap-1.5"
          >
            <span>Select Bowler</span>
            <ChevronRight size={14} />
          </button>
        </div>
      )}

      {/* Recent Deliveries Carousel */}
      <div className="p-3 bg-white rounded-2xl border border-slate-200 shadow-xs flex items-center gap-2 overflow-x-auto">
        <span className="text-xs font-bold text-slate-400 uppercase tracking-wider shrink-0 mr-1">This Over:</span>
        {recentDeliveries.slice(-6).map((del, idx) => {
          let badgeColor = 'bg-slate-100 text-slate-800 border-slate-200';
          let label = del.runsBatter.toString();

          if (del.runsBatter === 4) badgeColor = 'bg-blue-600 text-white border-blue-700';
          if (del.runsBatter === 6) badgeColor = 'bg-purple-600 text-white border-purple-700';
          if (del.isWicket) {
            badgeColor = 'bg-rose-600 text-white border-rose-700 font-bold';
            label = 'W';
          }
          if (del.extrasType === 'wide') {
            badgeColor = 'bg-amber-100 text-amber-900 border-amber-300';
            label = `${del.extrasRuns || 1}wd`;
          }
          if (del.extrasType === 'no_ball') {
            badgeColor = 'bg-amber-500 text-white border-amber-600';
            label = `${(del.extrasRuns || 0) + 1}nb`;
          }

          return (
            <div
              key={del.id || idx}
              className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-black shrink-0 border shadow-xs ${badgeColor}`}
            >
              {label}
            </div>
          );
        })}
      </div>

      {/* If Innings is completed or over limit reached, lock the keypad */}
      {innings.isCompleted || innings.legalBalls >= match.overs * 6 || innings.wickets >= 10 ? (
        <div className="p-6 rounded-3xl bg-slate-900 text-white shadow-xl border border-slate-800 text-center space-y-4 animate-in fade-in">
          <div className="w-14 h-14 rounded-2xl bg-amber-500/20 text-amber-400 flex items-center justify-center mx-auto text-2xl">
            {innings.inningsNumber === 1 ? '🏏' : '🏆'}
          </div>
          <div>
            <span className="text-[11px] font-black uppercase tracking-wider text-amber-400 block mb-1">
              {innings.inningsNumber === 1 ? 'Innings 1 Completed!' : 'Match Completed!'}
            </span>
            <h3 className="text-2xl sm:text-3xl font-black text-white">
              {innings.totalRuns}/{innings.wickets} ({innings.oversStr}/{match.overs} Overs)
            </h3>
            {innings.inningsNumber === 1 ? (
              <p className="text-xs text-slate-300 mt-2">
                Target for 2nd Innings: <strong className="text-emerald-400 font-black text-base">{innings.totalRuns + 1} runs</strong> from {match.overs} overs (RRR: {((innings.totalRuns + 1) / match.overs).toFixed(2)})
              </p>
            ) : (
              <p className="text-xs text-slate-300 mt-2">
                Match concluded. Standings and Net Run Rate have been updated.
              </p>
            )}
          </div>

          {innings.inningsNumber === 1 ? (
            <button
              onClick={() => {
                match.currentInningsNumber = 2;
                window.location.reload();
              }}
              className="py-4 px-8 rounded-2xl bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-black text-sm uppercase tracking-wider shadow-lg shadow-emerald-500/25 transition active:scale-95 flex items-center justify-center gap-2 mx-auto"
            >
              <span>Start 2nd Innings (Next Team Batting) →</span>
            </button>
          ) : (
            <div className="flex gap-2 justify-center pt-2">
              <Link
                href={`/matches/${match.id}`}
                className="py-3 px-5 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-bold text-xs"
              >
                View Match Scorecard
              </Link>
              <Link
                href="/tournaments"
                className="py-3 px-5 rounded-xl bg-cricket-600 hover:bg-cricket-500 text-white font-bold text-xs"
              >
                Tournament Standings &amp; NRR
              </Link>
            </div>
          )}
        </div>
      ) : (
        <>
          {/* Big Ergonomic Scoring Keypad (Runs: 0, 1, 2, 3, 4, 6) */}
          <div className="grid grid-cols-3 gap-3">
            {[0, 1, 2, 3, 4, 6].map((run) => (
              <button
                key={run}
                onClick={() => handleRecordBall({ runsBatter: run })}
                className={`py-5 rounded-2xl font-black text-2xl sm:text-3xl shadow-md transition transform active:scale-95 border flex flex-col items-center justify-center ${
                  run === 4
                    ? 'bg-blue-600 hover:bg-blue-500 text-white border-blue-400 shadow-blue-500/20'
                    : run === 6
                    ? 'bg-purple-600 hover:bg-purple-500 text-white border-purple-400 shadow-purple-500/20'
                    : run === 0
                    ? 'bg-slate-100 hover:bg-slate-200 text-slate-800 border-slate-300'
                    : 'bg-white hover:bg-slate-50 text-slate-900 border-slate-200'
                }`}
              >
                <span>{run}</span>
                <span className="text-[10px] font-semibold opacity-70 tracking-wider uppercase">
                  {run === 0 ? 'Dot' : run === 4 ? 'Boundary' : run === 6 ? 'Maximum' : 'Runs'}
                </span>
              </button>
            ))}
          </div>

          {/* Action Row: Extras & Wickets */}
          <div className="grid grid-cols-2 gap-3 pt-1">
            <button
              onClick={() => setShowExtrasModal(true)}
              className="py-4 px-4 rounded-2xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-black text-sm uppercase tracking-wider shadow-md transition active:scale-95 flex items-center justify-center gap-2 border border-amber-300"
            >
              <span>EXTRAS (Wd / Nb / B / Lb)</span>
            </button>

            <button
              onClick={() => setShowWicketModal(true)}
              className="py-4 px-4 rounded-2xl bg-rose-600 hover:bg-rose-500 text-white font-black text-sm uppercase tracking-wider shadow-md transition active:scale-95 flex items-center justify-center gap-2 border border-rose-400"
            >
              <span>WICKET (OUT!)</span>
            </button>
          </div>
        </>
      )}

      {/* ============================================================== */}
      {/* 1. AUTOMATIC OVER COMPLETE & SELECT NEXT BOWLER MODAL          */}
      {/* ============================================================== */}
      {showOverCompleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/85 backdrop-blur-md animate-in fade-in duration-200">
          <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="text-center space-y-1 pb-3 border-b border-slate-100">
              <span className="px-3 py-1 rounded-full bg-emerald-100 text-emerald-800 text-[11px] font-black uppercase tracking-wider">
                OVER {completedOverNumber} COMPLETED!
              </span>
              <h3 className="text-xl font-black text-slate-900 pt-1">Select Bowler for Next Over</h3>
              <p className="text-xs text-slate-500">
                Score: <strong className="text-slate-900">{innings.totalRuns}/{innings.wickets}</strong> ({innings.oversStr} ov). Bowler ends swap automatically.
              </p>
            </div>

            {/* List of Bowlers with Strict Consecutive & Quota Lockout */}
            <div className="space-y-2 max-h-64 overflow-y-auto pr-1">
              {bowlingTeamPlayers.map((p) => {
                const eligibility = validateBowlerEligibility({
                  bowlerId: p.id,
                  previousOverBowlerId: effectivePrevBowlerId,
                  deliveries: store.getState().deliveries,
                  inningsId: innings.id,
                  maxOversPerBowler,
                });

                const isLocked = !eligibility.isEligible;

                return (
                  <button
                    key={p.id}
                    disabled={isLocked}
                    onClick={() => handleSelectNewBowler(p.id)}
                    className={`w-full p-3 rounded-2xl border flex items-center justify-between text-left transition shadow-xs ${
                      isLocked
                        ? 'bg-slate-100/80 border-slate-200 opacity-60 cursor-not-allowed'
                        : 'border-slate-200 hover:border-cricket-500 hover:bg-cricket-50/50 group'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl overflow-hidden bg-slate-100 border border-slate-200 shrink-0">
                        <img src={p.photoUrl} alt={p.fullName} className="w-full h-full object-cover object-top" />
                      </div>
                      <div>
                        <span className={`font-bold text-sm block ${isLocked ? 'text-slate-500' : 'text-slate-900 group-hover:text-cricket-700'}`}>
                          {p.fullName}
                        </span>
                        <span className="text-[11px] text-slate-500 capitalize">
                          {p.role.replace(/_/g, ' ')} • {eligibility.oversStr} ov bowled
                        </span>
                      </div>
                    </div>

                    {isLocked ? (
                      <span className="text-[10px] font-black text-rose-600 bg-rose-50 border border-rose-200 px-2 py-0.5 rounded-full flex items-center gap-1">
                        <Lock size={10} /> {eligibility.reason}
                      </span>
                    ) : (
                      <span className="text-xs font-bold text-cricket-600 group-hover:translate-x-1 transition">
                        Bowl Over →
                      </span>
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* 2. AUTOMATIC WICKET FLOW: CATCH / RUNOUT & NEW BATSMAN DIALOG   */}
      {/* ============================================================== */}
      {showWicketModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/85 backdrop-blur-md animate-in fade-in duration-200">
          <div className="w-full max-w-lg bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto space-y-5">
            {/* Header */}
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-rose-500 animate-pulse"></span>
                <h3 className="text-lg font-black text-rose-600 tracking-tight">Record Wicket (Dismissal)</h3>
              </div>
              <button onClick={() => setShowWicketModal(false)} className="p-1 rounded-lg hover:bg-slate-100 text-slate-400">
                <X size={18} />
              </button>
            </div>

            {/* STEP 1: DISMISSAL TYPE & FIELDER ASSIST */}
            {wicketStep === 1 && (
              <div className="space-y-4">
                {/* Dismissal Type Selector */}
                <div>
                  <span className="text-xs font-bold text-slate-700 block mb-1.5 uppercase tracking-wider">
                    How was the batsman dismissed?
                  </span>
                  <div className="grid grid-cols-3 gap-2 text-xs">
                    {[
                      { id: 'caught' as DismissalType, label: 'Caught' },
                      { id: 'bowled' as DismissalType, label: 'Bowled' },
                      { id: 'lbw' as DismissalType, label: 'LBW' },
                      { id: 'run_out' as DismissalType, label: 'Run Out' },
                      { id: 'stumped' as DismissalType, label: 'Stumped' },
                      { id: 'hit_wicket' as DismissalType, label: 'Hit Wicket' },
                    ].map((d) => (
                      <button
                        key={d.id}
                        onClick={() => setDismissalType(d.id)}
                        className={`p-2.5 rounded-xl font-bold transition border ${
                          dismissalType === d.id
                            ? 'bg-rose-600 text-white border-rose-700 shadow-sm'
                            : 'bg-slate-50 text-slate-700 hover:bg-slate-100 border-slate-200'
                        }`}
                      >
                        {d.label}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Who is Dismissed? (Striker or Non-Striker) */}
                <div>
                  <span className="text-xs font-bold text-slate-700 block mb-1.5 uppercase tracking-wider">
                    Which batsman is out?
                  </span>
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    <button
                      onClick={() => setDismissedBatterId(striker?.id || '')}
                      className={`p-3 rounded-xl border text-left transition flex items-center justify-between ${
                        dismissedBatterId === striker?.id
                          ? 'bg-rose-50 border-rose-400 text-rose-950 font-black'
                          : 'bg-slate-50 border-slate-200 text-slate-700'
                      }`}
                    >
                      <div>
                        <span className="text-[10px] text-slate-400 block uppercase">Striker</span>
                        <span>{striker?.displayName}</span>
                      </div>
                      {dismissedBatterId === striker?.id && <CheckCircle2 size={16} className="text-rose-600" />}
                    </button>

                    <button
                      onClick={() => setDismissedBatterId(nonStriker?.id || '')}
                      className={`p-3 rounded-xl border text-left transition flex items-center justify-between ${
                        dismissedBatterId === nonStriker?.id
                          ? 'bg-rose-50 border-rose-400 text-rose-950 font-black'
                          : 'bg-slate-50 border-slate-200 text-slate-700'
                      }`}
                    >
                      <div>
                        <span className="text-[10px] text-slate-400 block uppercase">Non-Striker</span>
                        <span>{nonStriker?.displayName}</span>
                      </div>
                      {dismissedBatterId === nonStriker?.id && <CheckCircle2 size={16} className="text-rose-600" />}
                    </button>
                  </div>
                </div>

                {/* IF CAUGHT: Select Fielder */}
                {dismissalType === 'caught' && (
                  <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-200 space-y-2.5">
                    <span className="text-xs font-bold text-slate-800 block">Who took the catch?</span>
                    <div className="grid grid-cols-3 gap-2">
                      <button
                        onClick={() => {
                          setCatcherType('fielder');
                          if (!catcherFielderId && bowlingTeamPlayers.length > 0) {
                            setCatcherFielderId(bowlingTeamPlayers[0].id);
                          }
                        }}
                        className={`py-2 rounded-xl text-xs font-bold border ${
                          catcherType === 'fielder' ? 'bg-slate-900 text-white' : 'bg-white border-slate-200 text-slate-700'
                        }`}
                      >
                        Fielder
                      </button>
                      <button
                        onClick={() => {
                          setCatcherType('keeper');
                          setCatcherFielderId(wicketKeeper.id);
                        }}
                        className={`py-2 rounded-xl text-xs font-bold border ${
                          catcherType === 'keeper' ? 'bg-slate-900 text-white' : 'bg-white border-slate-200 text-slate-700'
                        }`}
                      >
                        Wicketkeeper
                      </button>
                      <button
                        onClick={() => {
                          setCatcherType('bowler');
                          setCatcherFielderId(bowler?.id || '');
                        }}
                        className={`py-2 rounded-xl text-xs font-bold border ${
                          catcherType === 'bowler' ? 'bg-slate-900 text-white' : 'bg-white border-slate-200 text-slate-700'
                        }`}
                      >
                        Caught & Bowled
                      </button>
                    </div>

                    {catcherType === 'fielder' && (
                      <select
                        value={catcherFielderId}
                        onChange={(e) => setCatcherFielderId(e.target.value)}
                        className="w-full p-2.5 rounded-xl border border-slate-300 text-xs bg-white font-medium"
                      >
                        <option value="">Select Catching Fielder...</option>
                        {bowlingTeamPlayers.map((p) => (
                          <option key={p.id} value={p.id}>
                            {p.fullName} ({p.role.replace(/_/g, ' ')})
                          </option>
                        ))}
                      </select>
                    )}
                  </div>
                )}

                {/* IF RUN OUT: Select Details */}
                {dismissalType === 'run_out' && (
                  <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-200 space-y-3 text-xs">
                    <div>
                      <span className="font-bold text-slate-800 block mb-1">Runs completed before run-out:</span>
                      <div className="flex gap-2">
                        {[0, 1, 2, 3].map((r) => (
                          <button
                            key={r}
                            onClick={() => setRunoutCompletedRuns(r)}
                            className={`flex-1 py-1.5 rounded-lg font-bold border ${
                              runoutCompletedRuns === r ? 'bg-slate-900 text-white' : 'bg-white border-slate-200'
                            }`}
                          >
                            {r}
                          </button>
                        ))}
                      </div>
                    </div>

                    <div>
                      <span className="font-bold text-slate-800 block mb-1">Fielder involved / Thrower:</span>
                      <select
                        value={runoutThrowerId}
                        onChange={(e) => setRunoutThrowerId(e.target.value)}
                        className="w-full p-2 rounded-xl border border-slate-300 text-xs bg-white font-medium"
                      >
                        <option value="">Select Throwing Fielder...</option>
                        {bowlingTeamPlayers.map((p) => (
                          <option key={p.id} value={p.id}>
                            {p.fullName}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <span className="font-bold text-slate-800 block mb-1">Stumps broken by:</span>
                      <select
                        value={runoutBrokenBy}
                        onChange={(e) => setRunoutBrokenBy(e.target.value)}
                        className="w-full p-2 rounded-xl border border-slate-300 text-xs bg-white font-medium"
                      >
                        <option value="direct_hit">Direct Hit</option>
                        <option value="wicket_keeper">Wicketkeeper ({wicketKeeper.displayName})</option>
                        <option value="bowler">Bowler ({bowler?.displayName})</option>
                      </select>
                    </div>
                  </div>
                )}

                {/* Next Step: Proceed to New Batsman */}
                <button
                  onClick={() => setWicketStep(2)}
                  className="w-full py-3.5 rounded-2xl bg-slate-900 hover:bg-slate-800 text-white font-black text-sm uppercase tracking-wider transition flex items-center justify-center gap-2 shadow-md"
                >
                  <span>Next: Select New Batsman</span>
                  <ChevronRight size={16} />
                </button>
              </div>
            )}

            {/* STEP 2: AUTOMATIC SELECT NEW BATSMAN */}
            {wicketStep === 2 && (
              <div className="space-y-4">
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-xs text-rose-900 flex items-center justify-between">
                  <span>
                    Dismissed: <strong>{battingTeamPlayers.find((p) => p.id === dismissedBatterId)?.fullName || 'Batsman'}</strong> ({dismissalType.toUpperCase()})
                  </span>
                  <button onClick={() => setWicketStep(1)} className="text-[11px] underline font-bold text-rose-700">
                    Change Details
                  </button>
                </div>

                {isAllOutAfterThis ? (
                  <div className="p-6 rounded-2xl bg-slate-900 text-white text-center space-y-2">
                    <span className="text-2xl">🏏</span>
                    <h4 className="text-lg font-black text-amber-400">10 Wickets Down — All Out!</h4>
                    <p className="text-xs text-slate-400">
                      All 10 wickets have fallen. Confirming this dismissal will conclude the innings. No more batsmen can enter.
                    </p>
                  </div>
                ) : (
                  <div>
                    <span className="text-xs font-bold text-slate-800 block mb-2 uppercase tracking-wider">
                      Select Incoming Batsman ({availableDugoutBatsmen.length} in dugout)
                    </span>

                    {/* Eligible incoming batsmen list */}
                    <div className="space-y-2 max-h-56 overflow-y-auto pr-1">
                      {availableDugoutBatsmen.map((b) => (
                        <button
                          key={b.id}
                          onClick={() => setNextBatterId(b.id)}
                          className={`w-full p-3 rounded-2xl border flex items-center justify-between text-left transition ${
                            nextBatterId === b.id
                              ? 'bg-cricket-50 border-cricket-600 ring-2 ring-cricket-600 text-slate-900 shadow-sm'
                              : 'bg-slate-50 border-slate-200 hover:bg-slate-100 text-slate-700'
                          }`}
                        >
                          <div className="flex items-center gap-3">
                            <div className="w-9 h-9 rounded-xl overflow-hidden bg-slate-200 border border-slate-300 shrink-0">
                              <img src={b.photoUrl} alt={b.fullName} className="w-full h-full object-cover object-top" />
                            </div>
                            <div>
                              <span className="font-bold text-xs block">{b.fullName}</span>
                              <span className="text-[10px] text-slate-500 capitalize">{b.role.replace(/_/g, ' ')} • {b.battingStyle.replace(/_/g, ' ')}</span>
                            </div>
                          </div>
                          {nextBatterId === b.id && (
                            <span className="px-2 py-0.5 rounded-full bg-cricket-600 text-white text-[10px] font-bold">
                              Selected
                            </span>
                          )}
                        </button>
                      ))}
                    </div>

                    {/* Already Out Batsmen List (Non-repeatable) */}
                    {allDismissedIds.size > 0 && (
                      <div className="mt-4 pt-3 border-t border-slate-200">
                        <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest block mb-1">
                          Already Dismissed (Cannot Bat Again):
                        </span>
                        <div className="flex flex-wrap gap-1.5">
                          {Array.from(allDismissedIds).map((pId) => {
                            const p = battingTeamPlayers.find((x) => x.id === pId);
                            if (!p) return null;
                            return (
                              <span
                                key={p.id}
                                className="text-[10px] px-2 py-0.5 rounded-md bg-rose-50 text-rose-700 border border-rose-200 line-through font-medium"
                              >
                                {p.displayName} (OUT)
                              </span>
                            );
                          })}
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {/* Final Submit Button */}
                <button
                  onClick={() => {
                    let assistId = catcherFielderId;
                    if (dismissalType === 'stumped') assistId = wicketKeeper.id;
                    if (dismissalType === 'run_out') assistId = runoutThrowerId;

                    handleRecordBall({
                      runsBatter: dismissalType === 'run_out' ? runoutCompletedRuns : 0,
                      isWicket: true,
                      dismissalType,
                      dismissedPlayerId: dismissedBatterId || striker?.id,
                      assistedByPlayerId: assistId || null,
                      nextBatterId: isAllOutAfterThis ? null : nextBatterId,
                    });

                    setShowWicketModal(false);
                  }}
                  disabled={!isAllOutAfterThis && !nextBatterId}
                  className={`w-full py-4 rounded-2xl font-black text-sm uppercase tracking-wider text-white shadow-xl transition ${
                    !isAllOutAfterThis && !nextBatterId
                      ? 'bg-slate-400 cursor-not-allowed'
                      : 'bg-rose-600 hover:bg-rose-500 shadow-rose-600/30'
                  }`}
                >
                  {isAllOutAfterThis
                    ? 'Confirm 10th Wicket (All Out)'
                    : `Confirm Wicket & Send In ${battingTeamPlayers.find((p) => p.id === nextBatterId)?.displayName || 'New Batsman'}`}
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* 3. EXTRAS MODAL                                                */}
      {/* ============================================================== */}
      {showExtrasModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm animate-in fade-in">
          <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-slate-200">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-base font-bold text-slate-900">Record Extras</h3>
              <button onClick={() => setShowExtrasModal(false)} className="p-1 rounded-lg hover:bg-slate-100 text-slate-400">
                <X size={18} />
              </button>
            </div>

            <div className="mt-4 space-y-3">
              <span className="text-xs font-semibold text-slate-600 block">Extras Type</span>
              <div className="grid grid-cols-2 gap-2">
                {[
                  { id: 'wide' as ExtrasType, label: 'Wide Ball' },
                  { id: 'no_ball' as ExtrasType, label: 'No Ball (Free Hit)' },
                  { id: 'bye' as ExtrasType, label: 'Bye' },
                  { id: 'leg_bye' as ExtrasType, label: 'Leg Bye' },
                ].map((item) => (
                  <button
                    key={item.id}
                    onClick={() => setSelectedExtraType(item.id)}
                    className={`p-3 rounded-xl text-xs font-bold transition border ${
                      selectedExtraType === item.id
                        ? 'bg-amber-500 text-slate-950 border-amber-600 shadow-sm'
                        : 'bg-slate-50 text-slate-700 hover:bg-slate-100 border-slate-200'
                    }`}
                  >
                    {item.label}
                  </button>
                ))}
              </div>

              <div className="pt-2">
                <span className="text-xs font-semibold text-slate-600 block mb-1">Additional Runs Completed</span>
                <div className="flex gap-2">
                  {[0, 1, 2, 3, 4].map((r) => (
                    <button
                      key={r}
                      onClick={() => setExtrasRuns(r)}
                      className={`flex-1 py-2 rounded-lg font-bold text-xs border ${
                        extrasRuns === r ? 'bg-slate-900 text-white border-slate-900' : 'bg-slate-50 border-slate-200'
                      }`}
                    >
                      {r}
                    </button>
                  ))}
                </div>
              </div>

              <button
                onClick={() => {
                  handleRecordBall({
                    runsBatter: selectedExtraType === 'no_ball' ? extrasRuns : 0,
                    extrasType: selectedExtraType,
                    extrasRuns: selectedExtraType === 'wide' ? Math.max(1, extrasRuns) : extrasRuns,
                  });
                  setShowExtrasModal(false);
                }}
                className="w-full mt-4 py-3 rounded-xl bg-amber-500 hover:bg-amber-400 font-black text-sm text-slate-950 uppercase tracking-wider"
              >
                Confirm Extras
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* 4. MANUAL BOWLER CHANGE MODAL WITH CONSECUTIVE/QUOTA LOCKOUT   */}
      {/* ============================================================== */}
      {showBowlerModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm animate-in fade-in">
          <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-base font-bold text-slate-900">Change Current Bowler</h3>
              <button onClick={() => setShowBowlerModal(false)} className="p-1 rounded-lg hover:bg-slate-100 text-slate-400">
                <X size={18} />
              </button>
            </div>

            <div className="space-y-2 max-h-60 overflow-y-auto pr-1">
              {bowlingTeamPlayers.map((p) => {
                const isCurrentlyBowling = bowler?.id === p.id;
                const eligibility = validateBowlerEligibility({
                  bowlerId: p.id,
                  previousOverBowlerId: effectivePrevBowlerId,
                  deliveries: store.getState().deliveries,
                  inningsId: innings.id,
                  maxOversPerBowler,
                });

                const isLocked = isCurrentlyBowling || !eligibility.isEligible;
                const lockoutReason = isCurrentlyBowling
                  ? 'Currently Bowling'
                  : eligibility.reason;

                return (
                  <button
                    key={p.id}
                    disabled={isLocked}
                    onClick={() => handleSelectNewBowler(p.id)}
                    className={`w-full p-3 rounded-2xl flex items-center justify-between text-left border transition ${
                      isLocked
                        ? 'bg-slate-100/70 border-slate-200 opacity-60 cursor-not-allowed'
                        : 'hover:bg-slate-50 border-slate-200 group'
                    }`}
                  >
                    <div>
                      <span className={`font-bold text-xs block ${isLocked ? 'text-slate-500' : 'text-slate-900 group-hover:text-cricket-700'}`}>
                        {p.fullName}
                      </span>
                      <span className="text-[11px] text-slate-500 capitalize">
                        {p.role.replace(/_/g, ' ')} • {eligibility.oversStr} ov bowled
                      </span>
                    </div>

                    {isLocked ? (
                      <span className="text-[10px] font-black text-rose-600 bg-rose-50 border border-rose-200 px-2 py-0.5 rounded-full flex items-center gap-1">
                        <Lock size={10} /> {lockoutReason}
                      </span>
                    ) : (
                      <span className="text-xs font-semibold text-cricket-600">Select →</span>
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* 5. INNINGS 1 COMPLETE MODAL: AUTOMATIC SWITCH TO NEXT TEAM     */}
      {/* ============================================================== */}
      {showInnings1CompleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/85 backdrop-blur-md animate-in fade-in duration-200">
          <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 text-center space-y-4">
            <div className="w-16 h-16 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto text-3xl">
              🏏
            </div>
            <span className="px-3 py-1 rounded-full bg-emerald-100 text-emerald-800 text-[11px] font-black uppercase tracking-wider inline-block">
              INNINGS 1 COMPLETED!
            </span>
            <h3 className="text-2xl font-black text-slate-900">
              {innings.totalRuns}/{innings.wickets} ({innings.oversStr} Overs)
            </h3>
            <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200 text-xs text-slate-600 space-y-1">
              <span className="font-bold text-slate-900 block">Target for 2nd Innings:</span>
              <strong className="text-emerald-600 font-black text-2xl block">
                {innings.totalRuns + 1} RUNS
              </strong>
              <span>Required Run Rate: {((innings.totalRuns + 1) / match.overs).toFixed(2)} RPO</span>
            </div>

            <button
              onClick={() => {
                setShowInnings1CompleteModal(false);
                match.currentInningsNumber = 2;
                window.location.reload();
              }}
              className="w-full py-4 rounded-2xl bg-cricket-600 hover:bg-cricket-500 text-white font-black text-sm uppercase tracking-wider shadow-lg shadow-cricket-600/25 transition active:scale-95 flex items-center justify-center gap-2"
            >
              <span>Start 2nd Innings (Next Team Batting) →</span>
            </button>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* 6. MATCH COMPLETE MODAL                                        */}
      {/* ============================================================== */}
      {showMatchCompleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/85 backdrop-blur-md animate-in fade-in duration-200">
          <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 text-center space-y-4">
            <div className="w-16 h-16 rounded-full bg-amber-100 text-amber-600 flex items-center justify-center mx-auto text-3xl">
              🏆
            </div>
            <span className="px-3 py-1 rounded-full bg-amber-100 text-amber-900 text-[11px] font-black uppercase tracking-wider inline-block">
              MATCH COMPLETED!
            </span>
            <h3 className="text-2xl font-black text-slate-900">
              {match.winnerId ? `${store.getState().teams.find((t) => t.id === match.winnerId)?.name} WON!` : 'MATCH TIED!'}
            </h3>
            <p className="text-xs text-slate-500">
              {match.winMargin ? `Won by ${match.winMargin} ${match.winType}` : 'Match concluded with tied scores.'}
            </p>

            <div className="flex gap-2 pt-2">
              <Link
                href={`/matches/${match.id}`}
                className="flex-1 py-3.5 rounded-2xl bg-slate-900 hover:bg-slate-800 text-white font-black text-xs uppercase tracking-wider text-center"
              >
                Scorecard
              </Link>
              <Link
                href="/tournaments"
                className="flex-1 py-3.5 rounded-2xl bg-cricket-600 hover:bg-cricket-500 text-white font-black text-xs uppercase tracking-wider text-center"
              >
                Standings &amp; NRR
              </Link>
            </div>
          </div>
        </div>
      )}

      {/* ============================================================== */}
      {/* 7. FULL LIVE SCORECARD MODAL                                   */}
      {/* ============================================================== */}
      {showFullScorecardModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/85 backdrop-blur-md animate-in fade-in duration-200">
          <div className="w-full max-w-2xl bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto space-y-5">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div>
                <h3 className="text-base font-black text-slate-900">
                  {match.stage} • Innings {innings.inningsNumber} Scorecard
                </h3>
                <span className="text-xs text-slate-500 font-bold">
                  {innings.totalRuns}/{innings.wickets} in {innings.oversStr} Overs
                </span>
              </div>
              <button
                onClick={() => setShowFullScorecardModal(false)}
                className="p-1 rounded-lg hover:bg-slate-100 text-slate-400 font-bold"
              >
                ✕
              </button>
            </div>

            {/* BATTING SCORECARD */}
            <div className="space-y-2">
              <span className="text-xs font-black text-slate-700 uppercase tracking-wider block">
                Batting Scorecard
              </span>
              <div className="border border-slate-200 rounded-2xl overflow-hidden">
                <table className="w-full text-xs text-left">
                  <thead className="bg-slate-50 text-[10px] text-slate-500 uppercase font-black border-b border-slate-200">
                    <tr>
                      <th className="py-2.5 px-3">Batter</th>
                      <th className="py-2.5 px-2">Dismissal</th>
                      <th className="py-2.5 px-2 text-right">R</th>
                      <th className="py-2.5 px-2 text-right">B</th>
                      <th className="py-2.5 px-2 text-right">4s</th>
                      <th className="py-2.5 px-2 text-right">6s</th>
                      <th className="py-2.5 px-3 text-right">SR</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {allBattingCards.map((b) => (
                      <tr key={b.id} className="hover:bg-slate-50/50">
                        <td className="py-2 px-3 font-bold text-slate-900">
                          {b.playerName}
                          {b.playerId === striker?.id && <span className="text-amber-500 ml-1">★</span>}
                        </td>
                        <td className="py-2 px-2 text-[11px] text-slate-500">
                          {b.isOut ? (
                            <span className="text-rose-600 font-medium">{b.dismissalText}</span>
                          ) : (
                            <span className="text-emerald-600 font-bold">not out</span>
                          )}
                        </td>
                        <td className="py-2 px-2 text-right font-black text-slate-900">{b.runs}</td>
                        <td className="py-2 px-2 text-right text-slate-600">{b.balls}</td>
                        <td className="py-2 px-2 text-right text-slate-600">{b.fours}</td>
                        <td className="py-2 px-2 text-right text-slate-600">{b.sixes}</td>
                        <td className="py-2 px-3 text-right font-mono text-slate-700">{b.strikeRate.toFixed(1)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Extras Line */}
              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200 text-xs text-slate-700 flex justify-between font-medium">
                <span>Extras:</span>
                <span className="font-bold">
                  {innings.totalExtras} (w {innings.extrasWides}, nb {innings.extrasNoBalls}, b {innings.extrasByes}, lb {innings.extrasLegByes})
                </span>
              </div>
            </div>

            {/* BOWLING SCORECARD */}
            <div className="space-y-2 pt-2">
              <span className="text-xs font-black text-slate-700 uppercase tracking-wider block">
                Bowling Figures
              </span>
              <div className="border border-slate-200 rounded-2xl overflow-hidden">
                <table className="w-full text-xs text-left">
                  <thead className="bg-slate-50 text-[10px] text-slate-500 uppercase font-black border-b border-slate-200">
                    <tr>
                      <th className="py-2.5 px-3">Bowler</th>
                      <th className="py-2.5 px-2 text-right">O</th>
                      <th className="py-2.5 px-2 text-right">M</th>
                      <th className="py-2.5 px-2 text-right">R</th>
                      <th className="py-2.5 px-2 text-right">W</th>
                      <th className="py-2.5 px-2 text-right">ECON</th>
                      <th className="py-2.5 px-3 text-right">0s</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {allBowlingCards.map((b) => (
                      <tr key={b.id} className="hover:bg-slate-50/50">
                        <td className="py-2 px-3 font-bold text-slate-900">{b.playerName}</td>
                        <td className="py-2 px-2 text-right font-mono text-slate-700">{b.oversStr}</td>
                        <td className="py-2 px-2 text-right font-mono text-slate-600">{b.maidens}</td>
                        <td className="py-2 px-2 text-right font-mono font-bold text-slate-900">{b.runsConceded}</td>
                        <td className="py-2 px-2 text-right font-mono font-black text-rose-600">{b.wickets}</td>
                        <td className="py-2 px-2 text-right font-mono text-emerald-600">{b.economy.toFixed(2)}</td>
                        <td className="py-2 px-3 text-right font-mono text-slate-500">{b.dots}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            <button
              onClick={() => setShowFullScorecardModal(false)}
              className="w-full py-3 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs uppercase tracking-wider"
            >
              Close Scorecard
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
