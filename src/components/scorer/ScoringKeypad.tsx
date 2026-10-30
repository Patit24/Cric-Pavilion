'use client';

import React, { useState } from 'react';
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
  const [showExtrasModal, setShowExtrasModal] = useState(false);
  const [showWicketModal, setShowWicketModal] = useState(false);
  const [showBowlerModal, setShowBowlerModal] = useState(false);
  const [isOnline, setIsOnline] = useState(true);

  // Extras state
  const [selectedExtraType, setSelectedExtraType] = useState<ExtrasType>('wide');
  const [extrasRuns, setExtrasRuns] = useState<number>(1);

  // Wicket state
  const [dismissalType, setDismissalType] = useState<DismissalType>('caught');
  const [dismissedBatterId, setDismissedBatterId] = useState<string>(striker?.id || '');
  const [assistedPlayerId, setAssistedPlayerId] = useState<string>('');
  const [nextBatterId, setNextBatterId] = useState<string>('');

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

    store.recordDelivery({
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

  return (
    <div className="w-full max-w-xl mx-auto space-y-4">
      {/* Synchronization & Connection Status Bar */}
      <div className="flex items-center justify-between px-4 py-2 bg-slate-900 rounded-2xl text-xs text-white">
        <div className="flex items-center gap-2">
          {isOnline ? (
            <>
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
              <span className="text-emerald-400 font-semibold flex items-center gap-1">
                <Wifi size={13} /> Live Server Connected
              </span>
            </>
          ) : (
            <>
              <span className="w-2.5 h-2.5 rounded-full bg-amber-400"></span>
              <span className="text-amber-400 font-semibold flex items-center gap-1">
                <WifiOff size={13} /> Offline Event Queue Active
              </span>
            </>
          )}
        </div>
        <button
          onClick={handleUndo}
          className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 font-bold text-xs transition border border-slate-700 active:scale-95"
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

        {/* Batters & Bowler on Crease */}
        <div className="mt-4 pt-3 border-t border-cricket-800/80 grid grid-cols-2 gap-3 text-xs">
          {/* Batters */}
          <div className="p-2.5 rounded-xl bg-cricket-950/70 border border-cricket-800/50">
            <span className="text-[10px] text-cricket-400 uppercase font-bold tracking-wider block">Batters</span>
            <div className="mt-1 space-y-1">
              <div className="flex items-center justify-between text-white font-bold">
                <span className="flex items-center gap-1">
                  <span className="text-amber-400">★</span> {striker?.displayName || 'Striker'}
                </span>
                <span className="text-cricket-300 text-[11px] font-mono">On Strike</span>
              </div>
              <div className="flex items-center justify-between text-slate-300">
                <span>{nonStriker?.displayName || 'Non-Striker'}</span>
                <span className="text-slate-500 text-[10px]">Non-Striker</span>
              </div>
            </div>
          </div>

          {/* Bowler */}
          <div className="p-2.5 rounded-xl bg-cricket-950/70 border border-cricket-800/50 flex flex-col justify-between">
            <div>
              <span className="text-[10px] text-cricket-400 uppercase font-bold tracking-wider block">Bowler</span>
              <div className="mt-1 font-bold text-white truncate">
                {bowler?.displayName || 'Select Bowler'}
              </div>
            </div>
            <button
              onClick={() => setShowBowlerModal(true)}
              className="mt-1 text-[11px] text-cricket-400 hover:text-cricket-300 text-left font-semibold underline flex items-center gap-1"
            >
              <ArrowRightLeft size={11} /> Change Bowler
            </button>
          </div>
        </div>
      </div>

      {/* Recent Deliveries Pills */}
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

      {/* EXTRAS MODAL */}
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
                  { id: 'no_ball' as ExtrasType, label: 'No Ball' },
                  { id: 'bye' as ExtrasType, label: 'Bye' },
                  { id: 'leg_bye' as ExtrasType, label: 'Leg Bye' },
                ].map((item) => (
                  <button
                    key={item.id}
                    onClick={() => setSelectedExtraType(item.id)}
                    className={`p-3 rounded-xl text-xs font-bold transition border ${
                      selectedExtraType === item.id
                        ? 'bg-amber-500 text-slate-950 border-amber-600'
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

      {/* WICKET MODAL */}
      {showWicketModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm animate-in fade-in">
          <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-base font-bold text-rose-600">Record Wicket (Dismissal)</h3>
              <button onClick={() => setShowWicketModal(false)} className="p-1 rounded-lg hover:bg-slate-100 text-slate-400">
                <X size={18} />
              </button>
            </div>

            <div className="mt-4 space-y-4">
              <div>
                <span className="text-xs font-semibold text-slate-600 block mb-1">Dismissal Type</span>
                <div className="grid grid-cols-2 gap-2 text-xs">
                  {[
                    { id: 'caught' as DismissalType, label: 'Caught' },
                    { id: 'bowled' as DismissalType, label: 'Clean Bowled' },
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
                          ? 'bg-rose-600 text-white border-rose-700'
                          : 'bg-slate-50 text-slate-700 hover:bg-slate-100 border-slate-200'
                      }`}
                    >
                      {d.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Dismissed Batter */}
              <div>
                <span className="text-xs font-semibold text-slate-600 block mb-1">Dismissed Batter</span>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    onClick={() => setDismissedBatterId(striker?.id || '')}
                    className={`p-2 rounded-xl text-xs font-bold border ${
                      dismissedBatterId === striker?.id ? 'bg-slate-900 text-white' : 'bg-slate-50'
                    }`}
                  >
                    Striker: {striker?.displayName}
                  </button>
                  <button
                    onClick={() => setDismissedBatterId(nonStriker?.id || '')}
                    className={`p-2 rounded-xl text-xs font-bold border ${
                      dismissedBatterId === nonStriker?.id ? 'bg-slate-900 text-white' : 'bg-slate-50'
                    }`}
                  >
                    Non-Striker: {nonStriker?.displayName}
                  </button>
                </div>
              </div>

              {/* Fielder Assist (for caught/runout/stumped) */}
              {(dismissalType === 'caught' || dismissalType === 'run_out' || dismissalType === 'stumped') && (
                <div>
                  <span className="text-xs font-semibold text-slate-600 block mb-1">Assisted by (Fielder / Wicketkeeper)</span>
                  <select
                    value={assistedPlayerId}
                    onChange={(e) => setAssistedPlayerId(e.target.value)}
                    className="w-full p-2.5 rounded-xl border border-slate-300 text-xs bg-slate-50 font-medium"
                  >
                    <option value="">Select Fielder...</option>
                    {bowlingTeamPlayers.map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.fullName} ({p.role})
                      </option>
                    ))}
                  </select>
                </div>
              )}

              {/* Next Incoming Batter */}
              <div>
                <span className="text-xs font-semibold text-slate-600 block mb-1">Next Incoming Batter</span>
                <select
                  value={nextBatterId}
                  onChange={(e) => setNextBatterId(e.target.value)}
                  className="w-full p-2.5 rounded-xl border border-slate-300 text-xs bg-slate-50 font-medium"
                >
                  <option value="">Select Next Batter...</option>
                  {battingTeamPlayers
                    .filter((p) => p.id !== striker?.id && p.id !== nonStriker?.id)
                    .map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.fullName} ({p.role})
                      </option>
                    ))}
                </select>
              </div>

              <button
                onClick={() => {
                  handleRecordBall({
                    runsBatter: 0,
                    isWicket: true,
                    dismissalType,
                    dismissedPlayerId: dismissedBatterId || striker?.id,
                    assistedByPlayerId: assistedPlayerId || null,
                    nextBatterId: nextBatterId || null,
                  });
                  setShowWicketModal(false);
                }}
                className="w-full py-3.5 rounded-xl bg-rose-600 hover:bg-rose-500 font-black text-sm text-white uppercase tracking-wider"
              >
                Confirm Wicket
              </button>
            </div>
          </div>
        </div>
      )}

      {/* BOWLER CHANGE MODAL */}
      {showBowlerModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm animate-in fade-in">
          <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-slate-200">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-base font-bold text-slate-900">Select New Bowler</h3>
              <button onClick={() => setShowBowlerModal(false)} className="p-1 rounded-lg hover:bg-slate-100 text-slate-400">
                <X size={18} />
              </button>
            </div>

            <div className="mt-4 space-y-2 max-h-60 overflow-y-auto">
              {bowlingTeamPlayers
                .filter((p) => p.id !== bowler?.id)
                .map((p) => (
                  <button
                    key={p.id}
                    onClick={() => {
                      innings.currentBowlerId = p.id;
                      setShowBowlerModal(false);
                      store.recalculateStandings(match.tournamentId); // trigger update
                    }}
                    className="w-full p-3 rounded-xl flex items-center justify-between text-left hover:bg-slate-50 border border-slate-200 transition"
                  >
                    <div>
                      <span className="font-bold text-xs text-slate-900 block">{p.fullName}</span>
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
