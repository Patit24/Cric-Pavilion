'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { store } from '@/lib/store/mock-db';
import ScoringKeypad from '@/components/scorer/ScoringKeypad';
import TossWizard from '@/components/scorer/TossWizard';
import {
  Radio,
  Trophy,
  ArrowRight,
  Shield,
  Calendar,
  MapPin,
  RotateCcw,
  PlusCircle,
  Coins,
  CheckCircle2,
  AlertCircle,
} from 'lucide-react';

export default function ScorerPage() {
  const [state, setState] = useState(() => store.getState());
  const [selectedMatchId, setSelectedMatchId] = useState<string>('match_1');
  const [showNewMatchModal, setShowNewMatchModal] = useState(false);
  const [selectedInningsNum, setSelectedInningsNum] = useState<number>(1);

  // New match form state
  const [newMatchTeamA, setNewMatchTeamA] = useState<string>('team_barasat');
  const [newMatchTeamB, setNewMatchTeamB] = useState<string>('team_kolkata');
  const [newMatchOvers, setNewMatchOvers] = useState<number>(20);
  const [newMatchVenue, setNewMatchVenue] = useState<string>('Eden Gardens, Kolkata');

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  const activeMatch = state.matches.find((m) => m.id === selectedMatchId) || state.matches[0];
  const tournament = state.tournaments.find((t) => t.id === activeMatch?.tournamentId);
  const teamA = state.teams.find((t) => t.id === activeMatch?.teamAId);
  const teamB = state.teams.find((t) => t.id === activeMatch?.teamBId);

  // Inning 1 & Inning 2
  const matchInnings = state.innings.filter((i) => i.matchId === activeMatch?.id);
  const inn1 = matchInnings.find((i) => i.inningsNumber === 1);
  const inn2 = matchInnings.find((i) => i.inningsNumber === 2);

  // Automatically track active innings number
  useEffect(() => {
    if (activeMatch?.currentInningsNumber) {
      setSelectedInningsNum(activeMatch.currentInningsNumber);
    } else if (inn1?.isCompleted && inn2) {
      setSelectedInningsNum(2);
    }
  }, [activeMatch?.currentInningsNumber, inn1?.isCompleted, inn2]);

  const currentInnings = selectedInningsNum === 2 && inn2 ? inn2 : inn1;

  // Rosters for both teams
  const teamAPlayers = state.players.filter((p) =>
    state.tournamentPlayers.some((tp) => tp.teamId === activeMatch?.teamAId && tp.playerId === p.id)
  );
  const teamBPlayers = state.players.filter((p) =>
    state.tournamentPlayers.some((tp) => tp.teamId === activeMatch?.teamBId && tp.playerId === p.id)
  );

  // Fallbacks if team rosters not yet customized
  const safeTeamAPlayers = teamAPlayers.length > 0 ? teamAPlayers : state.players.slice(0, 8);
  const safeTeamBPlayers = teamBPlayers.length > 0 ? teamBPlayers : state.players.slice(8, 16);

  // Current batting & bowling teams for active innings
  const battingTeamId = currentInnings?.battingTeamId || (activeMatch?.battingFirstId || activeMatch?.teamAId);
  const bowlingTeamId = currentInnings?.bowlingTeamId || (battingTeamId === activeMatch?.teamAId ? activeMatch?.teamBId : activeMatch?.teamAId);

  const battingTeamPlayers = battingTeamId === activeMatch?.teamAId ? safeTeamAPlayers : safeTeamBPlayers;
  const bowlingTeamPlayers = bowlingTeamId === activeMatch?.teamAId ? safeTeamAPlayers : safeTeamBPlayers;

  // Crease players for active innings
  const striker = currentInnings?.currentStrikerId
    ? state.players.find((p) => p.id === currentInnings.currentStrikerId) || battingTeamPlayers[0] || null
    : battingTeamPlayers[0] || null;
  const nonStriker = currentInnings?.currentNonStrikerId
    ? state.players.find((p) => p.id === currentInnings.currentNonStrikerId) || battingTeamPlayers[1] || null
    : battingTeamPlayers[1] || null;
  const bowler = currentInnings?.currentBowlerId
    ? state.players.find((p) => p.id === currentInnings.currentBowlerId) || null
    : null;

  const recentDeliveries = state.deliveries.filter((d) => d.matchId === activeMatch?.id && !d.isUndone);

  const handleCreateNewMatch = (e: React.FormEvent) => {
    e.preventDefault();
    if (newMatchTeamA === newMatchTeamB) {
      alert('Please select two distinct teams for the match.');
      return;
    }

    const created = store.createMatch({
      tournamentId: tournament?.id || 'tourn_bpl_2026',
      teamAId: newMatchTeamA,
      teamBId: newMatchTeamB,
      venue: newMatchVenue,
      dateTime: new Date().toISOString(),
      overs: newMatchOvers,
      stage: `Match #${state.matches.length + 1}`,
    });

    setSelectedMatchId(created.id);
    setShowNewMatchModal(false);
  };

  const handleResetCurrentMatch = () => {
    if (!activeMatch) return;
    const confirmed = confirm(
      `Are you sure you want to reset "${activeMatch.stage}"? This will clear recorded deliveries and allow you to restart the match or conduct the toss again.`
    );
    if (confirmed) {
      store.resetMatch(activeMatch.id);
    }
  };

  const isPreMatch = activeMatch && (activeMatch.status === 'scheduled' || activeMatch.status === 'toss' || !inn1);

  return (
    <div className="max-w-4xl mx-auto px-4 py-8 space-y-6">
      {/* Header & Controls Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-200">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-rose-50 border border-rose-200 text-rose-700 text-xs font-bold uppercase tracking-wider mb-1">
            <Radio size={14} className="animate-pulse" />
            <span>Official Scorer Console</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">
            Ball-by-Ball Live Scoring
          </h1>
          <p className="text-xs text-slate-500">
            Certified match recorder interface with official ICC / BCCI cricket rules and coin toss management.
          </p>
        </div>

        {/* Action Controls */}
        <div className="flex flex-wrap items-center gap-2">
          {/* Match Picker */}
          <select
            value={selectedMatchId}
            onChange={(e) => {
              setSelectedMatchId(e.target.value);
              const m = state.matches.find((x) => x.id === e.target.value);
              if (m?.currentInningsNumber) setSelectedInningsNum(m.currentInningsNumber);
            }}
            className="p-2.5 rounded-xl border border-slate-300 text-xs font-bold bg-white shadow-xs max-w-[200px] truncate"
          >
            {state.matches.map((m) => (
              <option key={m.id} value={m.id}>
                {m.stage} ({m.status.toUpperCase()})
              </option>
            ))}
          </select>

          {/* New Match Button */}
          <button
            onClick={() => setShowNewMatchModal(true)}
            className="py-2.5 px-3 rounded-xl bg-cricket-600 hover:bg-cricket-500 text-white text-xs font-bold transition flex items-center gap-1.5 shadow-xs"
            title="Schedule a new fixture"
          >
            <PlusCircle size={14} />
            <span>New Match</span>
          </button>

          {/* Reset Match Button */}
          {activeMatch && (
            <button
              onClick={handleResetCurrentMatch}
              className="py-2.5 px-3 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition flex items-center gap-1.5 border border-slate-200"
              title="Reset this match to start fresh"
            >
              <RotateCcw size={13} />
              <span>Reset</span>
            </button>
          )}
        </div>
      </div>

      {/* Innings Tabs Bar if match is live or has multiple innings */}
      {!isPreMatch && activeMatch && (
        <div className="flex items-center gap-2 bg-slate-100 p-1.5 rounded-2xl text-xs font-bold border border-slate-200">
          <button
            onClick={() => setSelectedInningsNum(1)}
            className={`flex-1 py-2 px-3 rounded-xl transition flex items-center justify-center gap-2 ${
              selectedInningsNum === 1
                ? 'bg-white text-slate-900 shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <span>Innings 1</span>
            {inn1 && (
              <span className="text-[10px] px-2 py-0.5 rounded-full bg-slate-100 text-slate-700 font-mono">
                {inn1.totalRuns}/{inn1.wickets} ({inn1.oversStr} ov)
                {inn1.isCompleted ? ' • Complete' : ''}
              </span>
            )}
          </button>

          <button
            onClick={() => {
              if (inn2) {
                setSelectedInningsNum(2);
              } else if (inn1?.isCompleted) {
                setSelectedInningsNum(2);
              } else {
                alert('Innings 2 will unlock automatically once Innings 1 is completed (all 20 overs bowled or 10 wickets).');
              }
            }}
            className={`flex-1 py-2 px-3 rounded-xl transition flex items-center justify-center gap-2 ${
              selectedInningsNum === 2
                ? 'bg-white text-slate-900 shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            } ${!inn2 && !inn1?.isCompleted ? 'opacity-50 cursor-not-allowed' : ''}`}
          >
            <span>Innings 2</span>
            {inn2 ? (
              <span className="text-[10px] px-2 py-0.5 rounded-full bg-amber-100 text-amber-900 font-mono">
                {inn2.totalRuns}/{inn2.wickets} ({inn2.oversStr} ov) • Target: {inn2.targetRuns}
              </span>
            ) : inn1?.isCompleted ? (
              <span className="text-[10px] px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800">
                Ready to Start →
              </span>
            ) : (
              <span className="text-[10px] text-slate-400">Locked until Innings 1 ends</span>
            )}
          </button>
        </div>
      )}

      {/* RENDER VIEW: PRE-MATCH TOSS WIZARD OR LIVE SCORING KEYPAD */}
      {isPreMatch && teamA && teamB ? (
        <TossWizard
          match={activeMatch}
          teamA={teamA}
          teamB={teamB}
          teamAPlayers={safeTeamAPlayers}
          teamBPlayers={safeTeamBPlayers}
          onMatchStarted={() => {
            setSelectedInningsNum(1);
          }}
        />
      ) : activeMatch && currentInnings ? (
        <ScoringKeypad
          match={activeMatch}
          innings={currentInnings}
          striker={striker}
          nonStriker={nonStriker}
          bowler={bowler}
          battingTeamPlayers={battingTeamPlayers}
          bowlingTeamPlayers={bowlingTeamPlayers}
          recentDeliveries={recentDeliveries}
        />
      ) : (
        <div className="p-12 text-center bg-white rounded-3xl border border-slate-200">
          <p className="text-sm text-slate-500">No active match selected. Please pick or schedule a match above.</p>
        </div>
      )}

      {/* Create New Match Modal */}
      {showNewMatchModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm animate-in fade-in">
          <form
            onSubmit={handleCreateNewMatch}
            className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 space-y-4"
          >
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-base font-black text-slate-900">Schedule New Fixture</h3>
              <button
                type="button"
                onClick={() => setShowNewMatchModal(false)}
                className="text-slate-400 hover:text-slate-600 text-xs font-bold"
              >
                ✕
              </button>
            </div>

            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Team A</label>
              <select
                value={newMatchTeamA}
                onChange={(e) => setNewMatchTeamA(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-300 text-xs font-semibold bg-white"
              >
                {state.teams.map((t) => (
                  <option key={t.id} value={t.id}>
                    {t.name}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Team B</label>
              <select
                value={newMatchTeamB}
                onChange={(e) => setNewMatchTeamB(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-300 text-xs font-semibold bg-white"
              >
                {state.teams.map((t) => (
                  <option key={t.id} value={t.id} disabled={t.id === newMatchTeamA}>
                    {t.name} {t.id === newMatchTeamA ? '(Selected as Team A)' : ''}
                  </option>
                ))}
              </select>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">Overs Per Innings</label>
                <input
                  type="number"
                  min="2"
                  max="50"
                  value={newMatchOvers}
                  onChange={(e) => setNewMatchOvers(Number(e.target.value))}
                  className="w-full p-2.5 rounded-xl border border-slate-300 text-xs font-bold"
                />
              </div>

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">Venue</label>
                <input
                  type="text"
                  value={newMatchVenue}
                  onChange={(e) => setNewMatchVenue(e.target.value)}
                  className="w-full p-2.5 rounded-xl border border-slate-300 text-xs font-semibold"
                />
              </div>
            </div>

            <div className="flex gap-2 pt-2">
              <button
                type="button"
                onClick={() => setShowNewMatchModal(false)}
                className="flex-1 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="flex-1 py-2.5 rounded-xl bg-cricket-600 hover:bg-cricket-500 text-white text-xs font-bold shadow-md shadow-cricket-600/20"
              >
                Create &amp; Conduct Toss
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}