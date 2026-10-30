'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { store } from '@/lib/store/mock-db';
import ScoringKeypad from '@/components/scorer/ScoringKeypad';
import { Radio, Trophy, ArrowRight, Shield, Calendar, MapPin, CheckCircle2 } from 'lucide-react';

export default function ScorerPage() {
  const [state, setState] = useState(() => store.getState());
  const [selectedMatchId, setSelectedMatchId] = useState<string>('match_1');

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  const activeMatch = state.matches.find((m) => m.id === selectedMatchId) || state.matches[0];
  const tournament = state.tournaments.find((t) => t.id === activeMatch?.tournamentId);
  const teamA = state.teams.find((t) => t.id === activeMatch?.teamAId);
  const teamB = state.teams.find((t) => t.id === activeMatch?.teamBId);
  const currentInnings = state.innings.find((i) => i.matchId === activeMatch?.id);

  // Determine batting and bowling rosters
  const battingTeamId = currentInnings?.battingTeamId || activeMatch?.teamAId;
  const bowlingTeamId = currentInnings?.bowlingTeamId || activeMatch?.teamBId;

  const battingTeamPlayerIds = state.tournamentPlayers
    .filter((tp) => tp.teamId === battingTeamId)
    .map((tp) => tp.playerId);

  const bowlingTeamPlayerIds = state.tournamentPlayers
    .filter((tp) => tp.teamId === bowlingTeamId)
    .map((tp) => tp.playerId);

  let battingTeamPlayers = state.players.filter((p) => battingTeamPlayerIds.includes(p.id));
  if (battingTeamPlayers.length < 6) {
    battingTeamPlayers = state.players.filter((_, idx) => idx % 2 === 0);
  }

  let bowlingTeamPlayers = state.players.filter((p) => bowlingTeamPlayerIds.includes(p.id));
  if (bowlingTeamPlayers.length < 6) {
    bowlingTeamPlayers = state.players.filter((_, idx) => idx % 2 === 1);
  }

  // Crease players
  const striker = currentInnings?.currentStrikerId
    ? state.players.find((p) => p.id === currentInnings.currentStrikerId) || null
    : battingTeamPlayers[0] || null;
  const nonStriker = currentInnings?.currentNonStrikerId
    ? state.players.find((p) => p.id === currentInnings.currentNonStrikerId) || null
    : battingTeamPlayers[1] || null;
  const bowler = currentInnings?.currentBowlerId
    ? state.players.find((p) => p.id === currentInnings.currentBowlerId) || null
    : null;

  const recentDeliveries = state.deliveries.filter((d) => d.matchId === activeMatch?.id && !d.isUndone);

  return (
    <div className="max-w-4xl mx-auto px-4 py-8 space-y-6">
      {/* Header & Match Selector Bar */}
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
            Certified match recorder interface. All deliveries validated against cricket scoring laws.
          </p>
        </div>

        {/* Match picker if multiple matches */}
        <div className="flex items-center gap-2">
          <select
            value={selectedMatchId}
            onChange={(e) => setSelectedMatchId(e.target.value)}
            className="p-2.5 rounded-xl border border-slate-300 text-xs font-semibold bg-white shadow-xs"
          >
            {state.matches.map((m) => (
              <option key={m.id} value={m.id}>
                Match #{m.matchNumber}: {m.stage} ({m.status.toUpperCase()})
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Main Ergonomic Scorer Console */}
      {activeMatch && currentInnings && (
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
      )}
    </div>
  );
}
