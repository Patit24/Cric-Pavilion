'use client';

import React, { useState, useEffect } from 'react';
import { Delivery, DismissalType, ExtrasType, Innings, Match, Player } from '@/lib/types';
import { store } from '@/lib/store/mock-db';
import { generateCommentaryLine } from '@/lib/cricket-engine/commentary';
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

  // Sync dismissed batter default when modal opens
  useEffect(() => {
    if (showWicketModal) {
      setDismissedBatterId(striker?.id || '');
      setWicketStep(1);
      // Auto pre-select first available dugout batsman
      const availableBatsmen = getAvailableDugoutBatsmen();
      if (availableBatsmen.length > 0) {
        setNextBatterId(availableBatsmen[0].id);
      } else {
        setNextBatterId('');
      }
    }
  }, [showWicketModal, striker?.id]);

  // Find batsmen in batting team who haven't batted or gotten out yet
  const getAvailableDugoutBatsmen = () => {
    const scorecards = store.getState().battingScorecards.filter((b) => b.inningsId === innings.id);
    const dismissedIds = new Set(scorecards.filter((b) => b.isOut).map((b) => b.playerId));
    
    // Also exclude current striker and non-striker
    const currentOnCrease = new Set([striker?.id, nonStriker?.id].filter(Boolean));

    return battingTeamPlayers.filter((p) => !dismissedIds.has(p.id) && !currentOnCrease.has(p.id));
  };

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
    if (!striker || !nonStriker || !bowler) {
      alert('Please ensure Striker, Non-Striker, and Bowler are set.');
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

    // Check if over completed!
    if (res.isOverComplete && !res.isMatchWon && !res.isAllOut) {
      const overNum = Math.floor((res.updatedInnings?.legalBalls || innings.legalBalls) / 6);
      setCompletedOverNumber(overNum);
      setPreviousBowlerId(currentBowlerId);
      setShowOverCompleteModal(true);
    }
  };

  const handleSelectNewBowler = (newBowlerId: string) => {
    store.setBowler(innings.id, newBowlerId);
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

  const availableDugoutBatsmen = getAvailableDugoutBatsmen();
  const isAllOutAfterThis = innings.wickets + 1 >= 10 || availableDugoutBatsmen.length === 0;

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
        <button
          onClick={handleUndo}
          className="flex items-center gap-1.5 px-3 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold text-xs transition border border-slate-700 active:scale-95 shadow-xs"
          title="Undo last recorded delivery"
        >
          <RotateCcw size={13} />
          <span>Undo Delivery</span>
        </button>
      </div>

      {/* Main High-Contrast Scoreboard Banner */}
      <div className="p-5 rounded-3xl bg-gradient-to-br from-cricket-900 via-cricket-950 to-slate-950 text-white shadow-xl border border-cricket-800/60">
        <div className="flex items-center justify-between text-xs text-cricket-300 font-semibold">
          <span>{match.stage} • Innings {innings.inningsNumber}</span>
          <span>Max {match.overs} Overs</span>
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

        {/* Batters & Bowler at Crease */}
        <div className="mt-4 pt-3 border-t border-cricket-800/80 grid grid-cols-2 gap-3 text-xs">
          {/* Batters on Crease */}
          <div className="p-3 rounded-2xl bg-cricket-950/70 border border-cricket-800/50 space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-[10px] text-cricket-400 uppercase font-bold tracking-wider">Batters</span>
              <button
                onClick={handleSwapEnds}
                className="text-[10px] text-amber-400 hover:text-amber-300 flex items-center gap-1 font-semibold underline"
                title="Manually swap striker and non-striker ends"
              >
                <ArrowRightLeft size={10} /> Swap Ends
              </button>
            </div>
            <div className="space-y-1">
              <div className="flex items-center justify-between text-white font-bold p-1 rounded-lg bg-cricket-900/60 border border-cricket-700/50">
                <span className="flex items-center gap-1.5 truncate">
                  <span className="text-amber-400">★</span> {striker?.displayName || 'Striker'}
                </span>
                <span className="text-[10px] px-1.5 py-0.2 rounded bg-amber-400/20 text-amber-300 font-mono shrink-0">Strike</span>
              </div>
              <div className="flex items-center justify-between text-slate-300 px-1 py-0.5">
                <span className="truncate">{nonStriker?.displayName || 'Non-Striker'}</span>
                <span className="text-slate-500 text-[10px]">Non-Strike</span>
              </div>
            </div>
          </div>

          {/* Bowler on Crease */}
          <div className="p-3 rounded-2xl bg-cricket-950/70 border border-cricket-800/50 flex flex-col justify-between">
            <div>
              <span className="text-[10px] text-cricket-400 uppercase font-bold tracking-wider block">Current Bowler</span>
              <div className="mt-1 font-bold text-white truncate text-sm">
                {bowler?.displayName || 'Select Bowler'}
              </div>
              <span className="text-[10px] text-slate-400 capitalize block truncate">
                {bowler?.bowlingStyle.replace(/_/g, ' ') || 'Bowling'}
              </span>
            </div>
            <button
              onClick={() => setShowBowlerModal(true)}
              className="mt-2 py-1 px-2.5 rounded-lg bg-cricket-900 hover:bg-cricket-800 text-[11px] text-cricket-300 font-bold transition flex items-center justify-between border border-cricket-700/60"
            >
              <span>Change Bowler</span>
              <ChevronRight size={12} />
            </button>
          </div>
        </div>
      </div>

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

            {/* Lockout Notice for previous bowler */}
            {previousBowlerId && (
              <div className="p-2.5 rounded-xl bg-amber-50 border border-amber-200 text-xs text-amber-800 flex items-center gap-2">
                <AlertCircle size={15} className="text-amber-600 shrink-0" />
                <span>
                  <strong>{bowlingTeamPlayers.find((p) => p.id === previousBowlerId)?.displayName}</strong> just bowled this over and cannot bowl consecutive overs.
                </span>
              </div>
            )}

            {/* List of Eligible Bowlers */}
            <div className="space-y-2 max-h-64 overflow-y-auto pr-1">
              {bowlingTeamPlayers
                .filter((p) => p.id !== previousBowlerId)
                .map((p) => (
                  <button
                    key={p.id}
                    onClick={() => handleSelectNewBowler(p.id)}
                    className="w-full p-3 rounded-2xl border border-slate-200 hover:border-cricket-500 hover:bg-cricket-50/50 flex items-center justify-between text-left transition group shadow-xs"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl overflow-hidden bg-slate-100 border border-slate-200 shrink-0">
                        <img src={p.photoUrl} alt={p.fullName} className="w-full h-full object-cover object-top" />
                      </div>
                      <div>
                        <span className="font-bold text-slate-900 text-sm block group-hover:text-cricket-700">
                          {p.fullName}
                        </span>
                        <span className="text-[11px] text-slate-500 capitalize">
                          {p.role.replace(/_/g, ' ')} • {p.bowlingStyle.replace(/_/g, ' ')}
                        </span>
                      </div>
                    </div>
                    <span className="text-xs font-bold text-cricket-600 group-hover:translate-x-1 transition">
                      Bowl Over →
                    </span>
                  </button>
                ))}
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
                      The team is all out. Confirming this dismissal will conclude this innings.
                    </p>
                  </div>
                ) : (
                  <div>
                    <span className="text-xs font-bold text-slate-800 block mb-2 uppercase tracking-wider">
                      Select Incoming Batsman ({availableDugoutBatsmen.length} in dugout)
                    </span>

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
      {/* 4. MANUAL BOWLER CHANGE MODAL                                   */}
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
              {bowlingTeamPlayers
                .filter((p) => p.id !== bowler?.id)
                .map((p) => (
                  <button
                    key={p.id}
                    onClick={() => handleSelectNewBowler(p.id)}
                    className="w-full p-3 rounded-2xl flex items-center justify-between text-left hover:bg-slate-50 border border-slate-200 transition group"
                  >
                    <div>
                      <span className="font-bold text-xs text-slate-900 block group-hover:text-cricket-700">{p.fullName}</span>
                      <span className="text-[11px] text-slate-500 capitalize">{p.role.replace(/_/g, ' ')} • {p.bowlingStyle.replace(/_/g, ' ')}</span>
                    </div>
                    <span className="text-xs font-semibold text-cricket-600">Select →</span>
                  </button>
                ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
