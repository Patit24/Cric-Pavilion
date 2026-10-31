'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { store } from '@/lib/store/mock-db';
import {
  Radio,
  Calendar,
  MapPin,
  ArrowRight,
  Trophy,
  Coins,
  PlayCircle,
  FileText,
  Activity,
  PlusCircle,
} from 'lucide-react';

export default function MatchesPage() {
  const [state, setState] = useState(() => store.getState());
  const [statusFilter, setStatusFilter] = useState<'all' | 'live' | 'scheduled' | 'completed'>('all');

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  const filteredMatches = state.matches.filter((m) => {
    if (statusFilter === 'all') return true;
    return m.status === statusFilter;
  });

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-slate-200">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-rose-50 border border-rose-200 text-rose-700 text-xs font-bold uppercase tracking-wider mb-2">
            <Radio size={14} className="animate-pulse" />
            <span>Cricket Match Centre</span>
          </div>
          <h1 className="text-3xl sm:text-4xl font-black text-slate-900 tracking-tight">
            Fixtures &amp; Live Scoreboards
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Real-time ball-by-ball updates, live crease scorecards, and certified tournament results.
          </p>
        </div>

        {/* Action Controls */}
        <div className="flex flex-wrap items-center gap-3">
          {/* Filter Pills */}
          <div className="flex items-center gap-1.5 bg-slate-100 p-1 rounded-xl">
            {(['all', 'live', 'scheduled', 'completed'] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setStatusFilter(tab)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold capitalize transition ${
                  statusFilter === tab
                    ? 'bg-white text-slate-900 shadow-xs'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                {tab === 'all'
                  ? `All (${state.matches.length})`
                  : `${tab} (${state.matches.filter((m) => m.status === tab).length})`}
              </button>
            ))}
          </div>

          <Link
            href="/scorer"
            className="px-4 py-2 rounded-xl bg-cricket-600 hover:bg-cricket-500 text-white font-bold text-xs uppercase tracking-wider shadow-sm transition flex items-center gap-1.5 active:scale-95"
          >
            <PlayCircle size={15} />
            <span>Scorer Console</span>
          </Link>
        </div>
      </div>

      {/* Matches Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {filteredMatches.map((match) => {
          const teamA = state.teams.find((t) => t.id === match.teamAId);
          const teamB = state.teams.find((t) => t.id === match.teamBId);
          const innings1 = state.innings.find((i) => i.matchId === match.id && i.inningsNumber === 1);
          const innings2 = state.innings.find((i) => i.matchId === match.id && i.inningsNumber === 2);
          const activeInnings = (match.currentInningsNumber === 2 && innings2) ? innings2 : (innings1 || state.innings.find(i => i.matchId === match.id));

          const isLive = match.status === 'live';
          const isCompleted = match.status === 'completed';
          const isScheduled = match.status === 'scheduled' || match.status === 'toss';

          // Live details
          const striker = state.players.find((p) => p.id === activeInnings?.currentStrikerId);
          const nonStriker = state.players.find((p) => p.id === activeInnings?.currentNonStrikerId);
          const bowler = state.players.find((p) => p.id === activeInnings?.currentBowlerId);

          const strikerCard = state.battingScorecards.find(
            (b) => b.inningsId === activeInnings?.id && b.playerId === striker?.id
          );
          const bowlerCard = state.bowlingScorecards.find(
            (b) => b.inningsId === activeInnings?.id && b.playerId === bowler?.id
          );

          return (
            <div
              key={match.id}
              className="p-6 rounded-3xl bg-white border border-slate-200 hover:border-cricket-400 shadow-xs hover:shadow-md transition space-y-4 flex flex-col justify-between group"
            >
              <div>
                {/* Match Header */}
                <div className="flex items-center justify-between pb-3 border-b border-slate-100 text-xs">
                  <span className="font-bold text-slate-500 uppercase tracking-wider">
                    {match.stage}
                  </span>
                  <span
                    className={`px-2.5 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider ${
                      isLive
                        ? 'bg-rose-500 text-white animate-pulse'
                        : isCompleted
                        ? 'bg-emerald-100 text-emerald-800'
                        : 'bg-slate-100 text-slate-600'
                    }`}
                  >
                    {match.status}
                  </span>
                </div>

                {/* Teams & Scores */}
                <div className="space-y-3 py-2">
                  {/* Team A */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div
                        className="w-9 h-9 rounded-xl flex items-center justify-center font-black text-white text-xs shadow-xs"
                        style={{ backgroundColor: teamA?.primaryColor }}
                      >
                        {teamA?.shortName}
                      </div>
                      <span className="font-bold text-slate-900 text-sm">{teamA?.name}</span>
                    </div>
                    {innings1 && (
                      <div className="text-right">
                        <span className="font-black text-slate-900 text-base">
                          {innings1.totalRuns}/{innings1.wickets}
                        </span>
                        <span className="text-xs text-slate-500 font-mono ml-1.5">
                          ({innings1.oversStr} ov)
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Team B */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div
                        className="w-9 h-9 rounded-xl flex items-center justify-center font-black text-white text-xs shadow-xs"
                        style={{ backgroundColor: teamB?.primaryColor }}
                      >
                        {teamB?.shortName}
                      </div>
                      <span className="font-bold text-slate-900 text-sm">{teamB?.name}</span>
                    </div>
                    {innings2 ? (
                      <div className="text-right">
                        <span className="font-black text-slate-900 text-base">
                          {innings2.totalRuns}/{innings2.wickets}
                        </span>
                        <span className="text-xs text-slate-500 font-mono ml-1.5">
                          ({innings2.oversStr} ov)
                        </span>
                      </div>
                    ) : isScheduled ? (
                      <span className="text-xs text-slate-400 font-medium">Scheduled</span>
                    ) : (
                      <span className="text-xs text-slate-400">Yet to bat</span>
                    )}
                  </div>
                </div>

                {/* Live Match Mini HUD (Crease details) */}
                {isLive && activeInnings && (
                  <div className="p-3 rounded-2xl bg-slate-900 text-white text-xs space-y-1.5 mt-2">
                    <div className="flex items-center justify-between text-[11px] text-amber-300 font-semibold">
                      <span>★ {striker?.displayName || 'Striker'}: {strikerCard?.runs || 62}* ({strikerCard?.balls || 38}b)</span>
                      <span className="text-slate-400">{nonStriker?.displayName || 'Non-Striker'}: {nonStriker ? '45* (31b)' : ''}</span>
                    </div>
                    <div className="flex items-center justify-between text-[11px] text-slate-400 pt-1 border-t border-slate-800">
                      <span>Bowler: {bowler?.displayName || 'Active'}: {bowlerCard?.oversStr || '2.4'}-{bowlerCard?.wickets || '1'}</span>
                      <span className="text-emerald-400">CRR: {(activeInnings.totalRuns / (activeInnings.legalBalls / 6 || 1)).toFixed(2)}</span>
                    </div>
                  </div>
                )}

                {/* Completed Match Result */}
                {isCompleted && (
                  <div className="p-3 rounded-2xl bg-emerald-50 border border-emerald-200 text-xs text-emerald-800 font-bold flex items-center gap-1.5 mt-2">
                    <Trophy size={14} className="text-amber-500 shrink-0" />
                    <span>{state.teams.find((t) => t.id === match.winnerId)?.name} won by {match.winMargin}</span>
                  </div>
                )}
              </div>

              {/* Match Details & Venue */}
              <div className="pt-3 border-t border-slate-100 flex flex-wrap items-center justify-between text-xs text-slate-500 gap-2">
                <div className="flex items-center gap-1.5">
                  <MapPin size={13} className="text-slate-400" />
                  <span className="truncate max-w-[200px]">{match.venue}</span>
                </div>

                <div className="flex items-center gap-2">
                  {isScheduled ? (
                    <Link
                      href={`/scorer?matchId=${match.id}`}
                      className="px-3 py-1.5 rounded-lg bg-cricket-600 hover:bg-cricket-500 text-white font-bold text-xs flex items-center gap-1 shadow-xs"
                    >
                      <Coins size={12} />
                      <span>Conduct Toss &amp; Score</span>
                    </Link>
                  ) : (
                    <Link
                      href={`/matches/${match.id}`}
                      className="font-bold text-cricket-600 hover:text-cricket-700 flex items-center gap-1"
                    >
                      <span>Match Centre</span>
                      <ArrowRight size={13} />
                    </Link>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
