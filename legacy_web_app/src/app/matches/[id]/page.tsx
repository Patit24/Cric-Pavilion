'use client';

import React, { useState, useEffect, Suspense } from 'react';
import Link from 'next/link';
import { useParams, useSearchParams } from 'next/navigation';
import { store } from '@/lib/store/mock-db';
import {
  Radio,
  Trophy,
  ArrowRight,
  Shield,
  MapPin,
  Calendar,
  Activity,
  Users,
  Clock,
  Sparkles,
  Coins,
  ChevronRight,
  FileText,
  PlayCircle,
} from 'lucide-react';

function MatchDetailContent() {
  const params = useParams();
  const searchParams = useSearchParams();
  const matchId = (params?.id as string) || 'match_1';
  const initialTab = (searchParams?.get('tab') as any) || 'live';

  const [state, setState] = useState(() => store.getState());
  const [activeTab, setActiveTab] = useState<'live' | 'scorecard' | 'commentary' | 'squads' | 'info'>(
    ['live', 'scorecard', 'commentary', 'squads', 'info'].includes(initialTab) ? initialTab : 'live'
  );

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  useEffect(() => {
    const tabParam = searchParams?.get('tab');
    if (tabParam && ['live', 'scorecard', 'commentary', 'squads', 'info'].includes(tabParam)) {
      setActiveTab(tabParam as any);
    }
  }, [searchParams]);

  const match = state.matches.find((m) => m.id === matchId) || state.matches[0];
  const tournament = state.tournaments.find((t) => t.id === match?.tournamentId);
  const teamA = state.teams.find((t) => t.id === match?.teamAId);
  const teamB = state.teams.find((t) => t.id === match?.teamBId);

  // Innings 1 and Innings 2
  const matchInnings = state.innings.filter((i) => i.matchId === match?.id);
  const inn1 = matchInnings.find((i) => i.inningsNumber === 1);
  const inn2 = matchInnings.find((i) => i.inningsNumber === 2);
  const currentInnings = (match.currentInningsNumber === 2 && inn2) ? inn2 : (inn1 || matchInnings[0]);

  // Scorecards
  const battingCards = state.battingScorecards.filter((b) => b.matchId === match?.id);
  const bowlingCards = state.bowlingScorecards.filter((b) => b.matchId === match?.id);
  const matchDeliveries = state.deliveries.filter((d) => d.matchId === match?.id && !d.isUndone);

  // Identify Batting & Bowling Teams for Innings 1 and Innings 2
  const inn1BatTeam = state.teams.find((t) => t.id === inn1?.battingTeamId) || teamA;
  const inn1BowlTeam = state.teams.find((t) => t.id === inn1?.bowlingTeamId) || teamB;

  const inn2BatTeam = state.teams.find((t) => t.id === inn2?.battingTeamId) || teamB;
  const inn2BowlTeam = state.teams.find((t) => t.id === inn2?.bowlingTeamId) || teamA;

  // Batters & Bowler on crease for live view
  const striker = state.players.find((p) => p.id === currentInnings?.currentStrikerId);
  const nonStriker = state.players.find((p) => p.id === currentInnings?.currentNonStrikerId);
  const bowler = state.players.find((p) => p.id === currentInnings?.currentBowlerId);

  const strikerScore = battingCards.find(
    (b) => b.playerId === striker?.id && b.inningsId === currentInnings?.id
  ) || { runs: 62, balls: 38, fours: 6, sixes: 2, strikeRate: 163.2 };

  const nonStrikerScore = battingCards.find(
    (b) => b.playerId === nonStriker?.id && b.inningsId === currentInnings?.id
  ) || { runs: 45, balls: 31, fours: 4, sixes: 1, strikeRate: 145.2 };

  const bowlerScore = bowlingCards.find(
    (b) => b.playerId === bowler?.id && b.inningsId === currentInnings?.id
  ) || { oversStr: '2.4', maidens: 0, runsConceded: 24, wickets: 1, economy: 9.0 };

  // Team Squads
  const teamAPlayers = state.players.filter((p) =>
    state.tournamentPlayers.some((tp) => tp.teamId === teamA?.id && tp.playerId === p.id)
  );
  const teamBPlayers = state.players.filter((p) =>
    state.tournamentPlayers.some((tp) => tp.teamId === teamB?.id && tp.playerId === p.id)
  );

  const safeTeamAPlayers = teamAPlayers.length > 0 ? teamAPlayers : state.players.slice(0, 8);
  const safeTeamBPlayers = teamBPlayers.length > 0 ? teamBPlayers : state.players.slice(8, 16);

  const isLive = match.status === 'live';
  const isCompleted = match.status === 'completed';
  const isScheduled = match.status === 'scheduled' || match.status === 'toss';

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
      {/* Match Header Banner */}
      <div className="rounded-3xl bg-gradient-to-br from-slate-950 via-slate-900 to-cricket-950 text-white p-6 sm:p-8 shadow-xl border border-slate-800">
        <div className="flex flex-wrap items-center justify-between gap-4 pb-4 border-b border-slate-800 text-xs">
          <div className="flex items-center gap-2">
            <span className={`w-2.5 h-2.5 rounded-full ${isLive ? 'bg-rose-500 animate-pulse' : isCompleted ? 'bg-emerald-400' : 'bg-slate-400'}`}></span>
            <span className={`font-bold uppercase tracking-widest ${isLive ? 'text-rose-400' : isCompleted ? 'text-emerald-400' : 'text-slate-300'}`}>
              {isLive ? 'LIVE NOW' : match.status.toUpperCase()}
            </span>
            <span className="text-slate-500">•</span>
            <span className="text-slate-300 font-semibold">{tournament?.name}</span>
            <span className="text-slate-500">•</span>
            <span className="text-slate-400">{match.stage}</span>
          </div>
          <div className="flex items-center gap-2 text-slate-400">
            <MapPin size={13} />
            <span>{match.venue}</span>
          </div>
        </div>

        {/* Team Match Scores Header */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 py-6 items-center">
          {/* Team A */}
          <div className="flex items-center justify-between p-4 rounded-2xl bg-slate-900/60 border border-slate-800/80">
            <div className="flex items-center gap-3.5">
              <div
                className="w-12 h-12 rounded-xl flex items-center justify-center font-black text-white text-sm shadow-md"
                style={{ backgroundColor: teamA?.primaryColor }}
              >
                {teamA?.shortName}
              </div>
              <div>
                <h3 className="text-lg font-bold text-white">{teamA?.name}</h3>
                <span className="text-xs text-slate-400">
                  {inn1?.battingTeamId === teamA?.id ? '1st Innings' : inn2?.battingTeamId === teamA?.id ? '2nd Innings' : 'Team A'}
                </span>
              </div>
            </div>
            {inn1?.battingTeamId === teamA?.id && inn1 && (
              <div className="text-right">
                <div className="text-3xl font-black text-white">
                  {inn1.totalRuns}
                  <span className="text-cricket-400">/{inn1.wickets}</span>
                </div>
                <span className="text-xs font-mono text-slate-400">({inn1.oversStr} ov)</span>
              </div>
            )}
            {inn2?.battingTeamId === teamA?.id && inn2 && (
              <div className="text-right">
                <div className="text-3xl font-black text-white">
                  {inn2.totalRuns}
                  <span className="text-cricket-400">/{inn2.wickets}</span>
                </div>
                <span className="text-xs font-mono text-slate-400">({inn2.oversStr} ov)</span>
              </div>
            )}
            {!inn1 && isScheduled && (
              <span className="text-xs text-slate-400 font-semibold">Ready for Toss</span>
            )}
          </div>

          {/* Team B */}
          <div className="flex items-center justify-between p-4 rounded-2xl bg-slate-900/60 border border-slate-800/80">
            <div className="flex items-center gap-3.5">
              <div
                className="w-12 h-12 rounded-xl flex items-center justify-center font-black text-white text-sm shadow-md"
                style={{ backgroundColor: teamB?.primaryColor }}
              >
                {teamB?.shortName}
              </div>
              <div>
                <h3 className="text-lg font-bold text-white">{teamB?.name}</h3>
                <span className="text-xs text-slate-400">
                  {inn2?.battingTeamId === teamB?.id ? '2nd Innings' : inn1?.battingTeamId === teamB?.id ? '1st Innings' : 'Yet to bat'}
                </span>
              </div>
            </div>
            {inn2?.battingTeamId === teamB?.id && inn2 ? (
              <div className="text-right">
                <div className="text-3xl font-black text-white">
                  {inn2.totalRuns}
                  <span className="text-cricket-400">/{inn2.wickets}</span>
                </div>
                <span className="text-xs font-mono text-slate-400">({inn2.oversStr} ov)</span>
              </div>
            ) : inn1?.battingTeamId === teamB?.id && inn1 ? (
              <div className="text-right">
                <div className="text-3xl font-black text-white">
                  {inn1.totalRuns}
                  <span className="text-cricket-400">/{inn1.wickets}</span>
                </div>
                <span className="text-xs font-mono text-slate-400">({inn1.oversStr} ov)</span>
              </div>
            ) : (
              <span className="text-xs text-slate-400 font-medium">Yet to bat</span>
            )}
          </div>
        </div>

        {/* Live Toss Status / Match Result Status */}
        <div className="pt-4 border-t border-slate-800/80 flex flex-wrap items-center justify-between text-xs text-slate-400 gap-2">
          {isCompleted ? (
            <div className="flex items-center gap-2 text-emerald-400 font-black text-sm">
              <Trophy size={16} className="text-amber-400" />
              <span>{state.teams.find((t) => t.id === match.winnerId)?.name || 'Winner'} won by {match.winMargin || 'runs'}</span>
            </div>
          ) : match.tossWonBy ? (
            <div>
              Toss: <strong className="text-white">{state.teams.find((t) => t.id === match.tossWonBy)?.name}</strong> won the toss and elected to {match.tossDecision}
            </div>
          ) : (
            <div>Toss scheduled shortly before match commencement.</div>
          )}

          {currentInnings && isLive && (
            <div>
              CRR: <strong className="text-cricket-400">{(currentInnings.totalRuns / (currentInnings.legalBalls / 6 || 1)).toFixed(2)}</strong>
            </div>
          )}

          {isLive && (
            <Link
              href={`/scorer?matchId=${match.id}`}
              className="px-3 py-1.5 rounded-xl bg-cricket-600 hover:bg-cricket-500 text-white font-bold text-xs transition flex items-center gap-1 active:scale-95"
            >
              <PlayCircle size={14} />
              <span>Open Scorer Console</span>
            </Link>
          )}

          {isScheduled && (
            <Link
              href={`/scorer?matchId=${match.id}`}
              className="px-4 py-1.5 rounded-xl bg-cricket-600 hover:bg-cricket-500 text-white font-black text-xs transition flex items-center gap-1.5 active:scale-95 shadow-sm"
            >
              <Coins size={14} />
              <span>Conduct Toss &amp; Start Scoring</span>
            </Link>
          )}
        </div>
      </div>

      {/* MATCH TABS */}
      <div className="border-b border-slate-200">
        <nav className="flex space-x-6 overflow-x-auto text-sm font-bold">
          {[
            { id: 'live', label: isCompleted ? 'Match Summary' : 'Live Scoreboard' },
            { id: 'scorecard', label: 'Full Scorecard' },
            { id: 'commentary', label: 'Ball-by-Ball Commentary' },
            { id: 'squads', label: 'Playing XIs / Squads' },
            { id: 'info', label: 'Match Info' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`py-3 px-1 border-b-2 font-bold whitespace-nowrap transition ${
                activeTab === tab.id
                  ? 'border-cricket-600 text-cricket-600'
                  : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      {/* TAB 1: LIVE SCOREBOARD / MATCH SUMMARY */}
      {activeTab === 'live' && (
        <div className="space-y-6">
          {isLive ? (
            <>
              {/* Batters & Bowler at Crease HUD */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="p-5 rounded-2xl bg-white border border-slate-200 shadow-xs space-y-3">
                  <h4 className="text-xs font-black uppercase tracking-wider text-slate-400">
                    Batters at Crease
                  </h4>
                  <div className="divide-y divide-slate-100 text-xs">
                    {striker && (
                      <div className="py-2.5 flex items-center justify-between">
                        <div>
                          <span className="font-bold text-slate-900 flex items-center gap-1.5">
                            <span className="text-amber-500">★</span> {striker.fullName}
                            <span className="text-[9px] px-1.5 py-0.5 rounded bg-amber-100 text-amber-800 font-mono font-bold uppercase">
                              Strike
                            </span>
                          </span>
                          <span className="text-[11px] text-slate-500">{striker.role.replace(/_/g, ' ')}</span>
                        </div>
                        <div className="text-right">
                          <span className="font-black text-slate-900 text-sm">
                            {strikerScore.runs}* ({strikerScore.balls}b)
                          </span>
                          <span className="text-[11px] text-slate-500 block">
                            {strikerScore.fours}x4, {strikerScore.sixes}x6 • SR: {strikerScore.strikeRate.toFixed(1)}
                          </span>
                        </div>
                      </div>
                    )}
                    {nonStriker && (
                      <div className="py-2.5 flex items-center justify-between">
                        <div>
                          <span className="font-bold text-slate-900">{nonStriker.fullName}</span>
                          <span className="text-[11px] text-slate-500 block">Non-Striker</span>
                        </div>
                        <div className="text-right">
                          <span className="font-black text-slate-900 text-sm">
                            {nonStrikerScore.runs}* ({nonStrikerScore.balls}b)
                          </span>
                          <span className="text-[11px] text-slate-500 block">
                            {nonStrikerScore.fours}x4, {nonStrikerScore.sixes}x6 • SR: {nonStrikerScore.strikeRate.toFixed(1)}
                          </span>
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                <div className="p-5 rounded-2xl bg-white border border-slate-200 shadow-xs space-y-3">
                  <h4 className="text-xs font-black uppercase tracking-wider text-slate-400">
                    Active Bowler
                  </h4>
                  {bowler ? (
                    <div className="flex items-center justify-between text-xs py-2">
                      <div>
                        <span className="font-bold text-slate-900 text-sm block">{bowler.fullName}</span>
                        <span className="text-[11px] text-slate-500 capitalize">{bowler.bowlingStyle.replace(/_/g, ' ')}</span>
                      </div>
                      <div className="text-right">
                        <span className="font-black text-slate-900 text-sm">
                          {bowlerScore.oversStr}-{bowlerScore.maidens}-{bowlerScore.runsConceded}-{bowlerScore.wickets}
                        </span>
                        <span className="text-[10px] text-slate-500 block">Econ: {bowlerScore.economy.toFixed(2)}</span>
                      </div>
                    </div>
                  ) : (
                    <p className="text-xs text-slate-400 py-4">Waiting for bowler selection...</p>
                  )}
                </div>
              </div>

              {/* Recent Deliveries Strip */}
              <div className="p-4 rounded-2xl bg-white border border-slate-200 shadow-xs space-y-2">
                <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Latest Balls (This Over)</span>
                <div className="flex items-center gap-2 overflow-x-auto py-1">
                  {matchDeliveries.slice(-10).map((d) => (
                    <div
                      key={d.id}
                      className={`w-9 h-9 rounded-full flex items-center justify-center font-black text-xs shrink-0 border ${
                        d.runsBatter === 4
                          ? 'bg-blue-600 text-white border-blue-700'
                          : d.runsBatter === 6
                          ? 'bg-purple-600 text-white border-purple-700'
                          : d.isWicket
                          ? 'bg-rose-600 text-white border-rose-700'
                          : 'bg-slate-100 text-slate-800 border-slate-200'
                      }`}
                    >
                      {d.isWicket ? 'W' : d.runsBatter}
                    </div>
                  ))}
                </div>
              </div>
            </>
          ) : isCompleted ? (
            <div className="p-6 rounded-3xl bg-white border border-slate-200 shadow-sm space-y-5">
              <div className="flex items-center justify-between pb-4 border-b border-slate-100">
                <div className="flex items-center gap-2 text-emerald-700 font-black text-base">
                  <Trophy size={20} className="text-amber-500" />
                  <span>{state.teams.find((t) => t.id === match.winnerId)?.name} won by {match.winMargin}</span>
                </div>
                <button
                  onClick={() => setActiveTab('scorecard')}
                  className="px-4 py-2 rounded-xl bg-cricket-50 hover:bg-cricket-100 text-cricket-700 font-bold text-xs transition"
                >
                  View Full Scorecard →
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {inn1 && (
                  <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200 space-y-2">
                    <span className="text-[10px] font-bold text-slate-400 uppercase">1st Innings</span>
                    <div className="text-xl font-black text-slate-900">
                      {inn1BatTeam?.name}: {inn1.totalRuns}/{inn1.wickets} <span className="text-xs text-slate-500 font-normal">({inn1.oversStr} ov)</span>
                    </div>
                    <p className="text-xs text-slate-600">Top Batter: Subham Dey 68 (42b) • Top Bowler: Tanmoy Das 3/28</p>
                  </div>
                )}

                {inn2 && (
                  <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200 space-y-2">
                    <span className="text-[10px] font-bold text-slate-400 uppercase">2nd Innings (Target {inn2.targetRuns})</span>
                    <div className="text-xl font-black text-slate-900">
                      {inn2BatTeam?.name}: {inn2.totalRuns}/{inn2.wickets} <span className="text-xs text-slate-500 font-normal">({inn2.oversStr} ov)</span>
                    </div>
                    <p className="text-xs text-slate-600">Top Batter: Manoj Tiwary 52 (36b) • Top Bowler: Akash Deep 2/32</p>
                  </div>
                )}
              </div>
            </div>
          ) : (
            <div className="p-12 text-center bg-white rounded-3xl border border-slate-200 shadow-sm space-y-4">
              <Calendar size={36} className="text-slate-400 mx-auto" />
              <div>
                <h3 className="text-lg font-black text-slate-900">Match Scheduled</h3>
                <p className="text-xs text-slate-500 mt-1">
                  Scheduled fixture between {teamA?.name} and {teamB?.name} at {match.venue}.
                </p>
              </div>
              <Link
                href={`/scorer?matchId=${match.id}`}
                className="inline-flex items-center gap-2 px-6 py-3 rounded-2xl bg-cricket-600 hover:bg-cricket-500 text-white font-bold text-xs uppercase tracking-wider shadow-md transition"
              >
                <Coins size={14} />
                <span>Conduct Coin Toss &amp; Start Scoring</span>
              </Link>
            </div>
          )}
        </div>
      )}

      {/* TAB 2: FULL SCORECARD */}
      {activeTab === 'scorecard' && (
        <div className="space-y-8">
          {/* INNINGS 1 SCORECARD */}
          {inn1 && (
            <div className="space-y-4">
              <div className="flex items-center justify-between pb-2 border-b-2 border-cricket-600">
                <h3 className="text-lg font-black text-slate-900">
                  {inn1BatTeam?.name} Innings (1st Innings)
                </h3>
                <span className="text-base font-black text-cricket-700">
                  {inn1.totalRuns}/{inn1.wickets} ({inn1.oversStr} Ov)
                </span>
              </div>

              {/* Batting Table */}
              <div className="bg-white rounded-3xl border border-slate-200 shadow-xs overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-50/80 text-slate-500 font-black uppercase tracking-wider border-b border-slate-200">
                      <tr>
                        <th className="px-6 py-3.5">Batter</th>
                        <th className="px-4 py-3.5">Dismissal</th>
                        <th className="px-3 py-3.5 text-right">R</th>
                        <th className="px-3 py-3.5 text-right">B</th>
                        <th className="px-3 py-3.5 text-right">4s</th>
                        <th className="px-3 py-3.5 text-right">6s</th>
                        <th className="px-6 py-3.5 text-right">SR</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 font-medium">
                      {battingCards
                        .filter((b) => b.inningsId === inn1.id)
                        .map((b) => (
                          <tr key={b.id} className="hover:bg-slate-50/60">
                            <td className="px-6 py-3.5 font-bold text-slate-900">{b.playerName}</td>
                            <td className="px-4 py-3.5 text-slate-500 text-[11px]">{b.dismissalText}</td>
                            <td className="px-3 py-3.5 text-right font-black text-slate-900">{b.runs}</td>
                            <td className="px-3 py-3.5 text-right text-slate-600">{b.balls}</td>
                            <td className="px-3 py-3.5 text-right text-slate-600">{b.fours}</td>
                            <td className="px-3 py-3.5 text-right text-slate-600">{b.sixes}</td>
                            <td className="px-6 py-3.5 text-right font-mono text-slate-700">{b.strikeRate.toFixed(1)}</td>
                          </tr>
                        ))}
                    </tbody>
                  </table>
                </div>

                {/* Extras & Total Footer */}
                <div className="p-4 bg-slate-50 border-t border-slate-200 flex flex-wrap items-center justify-between text-xs text-slate-600">
                  <div>
                    Extras: <strong className="text-slate-900">{inn1.totalExtras}</strong> (w {inn1.extrasWides}, nb {inn1.extrasNoBalls}, b {inn1.extrasByes}, lb {inn1.extrasLegByes})
                  </div>
                  <div>
                    Total: <strong className="text-slate-900 text-sm">{inn1.totalRuns}/{inn1.wickets}</strong> ({inn1.oversStr} Ov, RR: {(inn1.totalRuns / (inn1.legalBalls / 6 || 1)).toFixed(2)})
                  </div>
                </div>
              </div>

              {/* Bowling Table */}
              <div className="bg-white rounded-3xl border border-slate-200 shadow-xs overflow-hidden">
                <div className="px-6 py-3 bg-slate-50 border-b border-slate-200 font-bold text-slate-700 text-xs uppercase tracking-wider">
                  {inn1BowlTeam?.name} Bowling Figures
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-50/50 text-slate-500 font-bold uppercase tracking-wider border-b border-slate-100">
                      <tr>
                        <th className="px-6 py-3">Bowler</th>
                        <th className="px-3 py-3 text-right">O</th>
                        <th className="px-3 py-3 text-right">M</th>
                        <th className="px-3 py-3 text-right">R</th>
                        <th className="px-3 py-3 text-right">W</th>
                        <th className="px-3 py-3 text-right">Dots</th>
                        <th className="px-6 py-3 text-right">Econ</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 font-medium">
                      {bowlingCards
                        .filter((bowl) => bowl.inningsId === inn1.id)
                        .map((bowl) => (
                          <tr key={bowl.id} className="hover:bg-slate-50/50">
                            <td className="px-6 py-3.5 font-bold text-slate-900">{bowl.playerName}</td>
                            <td className="px-3 py-3.5 text-right font-mono text-slate-700">{bowl.oversStr}</td>
                            <td className="px-3 py-3.5 text-right text-slate-600">{bowl.maidens}</td>
                            <td className="px-3 py-3.5 text-right font-bold text-slate-900">{bowl.runsConceded}</td>
                            <td className="px-3 py-3.5 text-right font-black text-cricket-600">{bowl.wickets}</td>
                            <td className="px-3 py-3.5 text-right text-slate-600">{bowl.dots}</td>
                            <td className="px-6 py-3.5 text-right font-mono text-slate-700">{bowl.economy.toFixed(2)}</td>
                          </tr>
                        ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* INNINGS 2 SCORECARD (IF STARTED OR COMPLETED) */}
          {inn2 && (
            <div className="space-y-4 pt-6 border-t border-slate-200">
              <div className="flex items-center justify-between pb-2 border-b-2 border-amber-500">
                <h3 className="text-lg font-black text-slate-900">
                  {inn2BatTeam?.name} Innings (2nd Innings • Target: {inn2.targetRuns})
                </h3>
                <span className="text-base font-black text-amber-600">
                  {inn2.totalRuns}/{inn2.wickets} ({inn2.oversStr} Ov)
                </span>
              </div>

              {/* Batting Table */}
              <div className="bg-white rounded-3xl border border-slate-200 shadow-xs overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-50/80 text-slate-500 font-black uppercase tracking-wider border-b border-slate-200">
                      <tr>
                        <th className="px-6 py-3.5">Batter</th>
                        <th className="px-4 py-3.5">Dismissal</th>
                        <th className="px-3 py-3.5 text-right">R</th>
                        <th className="px-3 py-3.5 text-right">B</th>
                        <th className="px-3 py-3.5 text-right">4s</th>
                        <th className="px-3 py-3.5 text-right">6s</th>
                        <th className="px-6 py-3.5 text-right">SR</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 font-medium">
                      {battingCards
                        .filter((b) => b.inningsId === inn2.id)
                        .map((b) => (
                          <tr key={b.id} className="hover:bg-slate-50/60">
                            <td className="px-6 py-3.5 font-bold text-slate-900">{b.playerName}</td>
                            <td className="px-4 py-3.5 text-slate-500 text-[11px]">{b.dismissalText}</td>
                            <td className="px-3 py-3.5 text-right font-black text-slate-900">{b.runs}</td>
                            <td className="px-3 py-3.5 text-right text-slate-600">{b.balls}</td>
                            <td className="px-3 py-3.5 text-right text-slate-600">{b.fours}</td>
                            <td className="px-3 py-3.5 text-right text-slate-600">{b.sixes}</td>
                            <td className="px-6 py-3.5 text-right font-mono text-slate-700">{b.strikeRate.toFixed(1)}</td>
                          </tr>
                        ))}
                    </tbody>
                  </table>
                </div>

                {/* Extras & Total Footer */}
                <div className="p-4 bg-slate-50 border-t border-slate-200 flex flex-wrap items-center justify-between text-xs text-slate-600">
                  <div>
                    Extras: <strong className="text-slate-900">{inn2.totalExtras}</strong> (w {inn2.extrasWides}, nb {inn2.extrasNoBalls}, b {inn2.extrasByes}, lb {inn2.extrasLegByes})
                  </div>
                  <div>
                    Total: <strong className="text-slate-900 text-sm">{inn2.totalRuns}/{inn2.wickets}</strong> ({inn2.oversStr} Ov, Target: {inn2.targetRuns})
                  </div>
                </div>
              </div>

              {/* Bowling Table */}
              <div className="bg-white rounded-3xl border border-slate-200 shadow-xs overflow-hidden">
                <div className="px-6 py-3 bg-slate-50 border-b border-slate-200 font-bold text-slate-700 text-xs uppercase tracking-wider">
                  {inn2BowlTeam?.name} Bowling Figures
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-50/50 text-slate-500 font-bold uppercase tracking-wider border-b border-slate-100">
                      <tr>
                        <th className="px-6 py-3">Bowler</th>
                        <th className="px-3 py-3 text-right">O</th>
                        <th className="px-3 py-3 text-right">M</th>
                        <th className="px-3 py-3 text-right">R</th>
                        <th className="px-3 py-3 text-right">W</th>
                        <th className="px-3 py-3 text-right">Dots</th>
                        <th className="px-6 py-3 text-right">Econ</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 font-medium">
                      {bowlingCards
                        .filter((bowl) => bowl.inningsId === inn2.id)
                        .map((bowl) => (
                          <tr key={bowl.id} className="hover:bg-slate-50/50">
                            <td className="px-6 py-3.5 font-bold text-slate-900">{bowl.playerName}</td>
                            <td className="px-3 py-3.5 text-right font-mono text-slate-700">{bowl.oversStr}</td>
                            <td className="px-3 py-3.5 text-right text-slate-600">{bowl.maidens}</td>
                            <td className="px-3 py-3.5 text-right font-bold text-slate-900">{bowl.runsConceded}</td>
                            <td className="px-3 py-3.5 text-right font-black text-cricket-600">{bowl.wickets}</td>
                            <td className="px-3 py-3.5 text-right text-slate-600">{bowl.dots}</td>
                            <td className="px-6 py-3.5 text-right font-mono text-slate-700">{bowl.economy.toFixed(2)}</td>
                          </tr>
                        ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* TAB 3: BALL-BY-BALL COMMENTARY */}
      {activeTab === 'commentary' && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-xs p-6 space-y-4">
          <h3 className="text-base font-bold text-slate-900 border-b border-slate-100 pb-3">
            Ball-by-Ball Live Feed
          </h3>

          <div className="space-y-3">
            {matchDeliveries.length > 0 ? (
              matchDeliveries.slice().reverse().map((del, idx) => (
                <div key={del.id || idx} className="p-3.5 rounded-2xl bg-slate-50 border border-slate-100 flex items-start gap-3">
                  <span className={`w-8 h-8 rounded-full font-black text-xs flex items-center justify-center shrink-0 border ${
                    del.isWicket ? 'bg-rose-600 text-white border-rose-700' :
                    del.runsBatter === 4 ? 'bg-blue-600 text-white' :
                    del.runsBatter === 6 ? 'bg-purple-600 text-white' : 'bg-slate-200 text-slate-800'
                  }`}>
                    {del.isWicket ? 'W' : del.runsBatter}
                  </span>
                  <div className="flex-1 text-xs">
                    <div className="flex items-center justify-between text-slate-400 font-mono text-[10px] mb-1">
                      <span>Over {del.overNumber}.{del.ballInOver}</span>
                      <span>{new Date(del.timestamp).toLocaleTimeString()}</span>
                    </div>
                    <p className="text-slate-800 font-medium leading-relaxed">
                      {del.commentaryText}
                    </p>
                  </div>
                </div>
              ))
            ) : (
              <p className="text-xs text-slate-400 py-4 text-center">No commentary logged yet.</p>
            )}
          </div>
        </div>
      )}

      {/* TAB 4: PLAYING XIS */}
      {activeTab === 'squads' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="p-6 rounded-3xl bg-white border border-slate-200 shadow-xs space-y-3">
            <h3 className="font-bold text-slate-900 text-base">{teamA?.name} Playing Squad</h3>
            <div className="divide-y divide-slate-100 text-xs">
              {safeTeamAPlayers.map((p) => (
                <div key={p.id} className="py-2.5 flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <div className="w-7 h-7 rounded-lg overflow-hidden bg-slate-100 border border-slate-200 shrink-0">
                      <img src={p.photoUrl} alt={p.fullName} className="w-full h-full object-cover object-top" />
                    </div>
                    <span className="font-bold text-slate-800">{p.fullName}</span>
                  </div>
                  <span className="text-slate-500 capitalize">{p.role.replace(/_/g, ' ')}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="p-6 rounded-3xl bg-white border border-slate-200 shadow-xs space-y-3">
            <h3 className="font-bold text-slate-900 text-base">{teamB?.name} Playing Squad</h3>
            <div className="divide-y divide-slate-100 text-xs">
              {safeTeamBPlayers.map((p) => (
                <div key={p.id} className="py-2.5 flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <div className="w-7 h-7 rounded-lg overflow-hidden bg-slate-100 border border-slate-200 shrink-0">
                      <img src={p.photoUrl} alt={p.fullName} className="w-full h-full object-cover object-top" />
                    </div>
                    <span className="font-bold text-slate-800">{p.fullName}</span>
                  </div>
                  <span className="text-slate-500 capitalize">{p.role.replace(/_/g, ' ')}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* TAB 5: MATCH INFO */}
      {activeTab === 'info' && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-xs p-6 space-y-4 text-xs">
          <h3 className="text-base font-bold text-slate-900 border-b border-slate-100 pb-3">Match Details</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div><span className="text-slate-400 block font-bold uppercase">Series</span><span className="font-bold text-slate-900 text-sm">{tournament?.name}</span></div>
            <div><span className="text-slate-400 block font-bold uppercase">Match</span><span className="font-bold text-slate-900 text-sm">{match.stage}</span></div>
            <div><span className="text-slate-400 block font-bold uppercase">Venue</span><span className="font-bold text-slate-900 text-sm">{match.venue}</span></div>
            <div><span className="text-slate-400 block font-bold uppercase">Format</span><span className="font-bold text-slate-900 text-sm">{match.overs} Overs T20</span></div>
            <div><span className="text-slate-400 block font-bold uppercase">Scorer</span><span className="font-bold text-slate-900 text-sm">Pritam Saha (BCCI Certified)</span></div>
            <div><span className="text-slate-400 block font-bold uppercase">Umpires</span><span className="font-bold text-slate-900 text-sm">K. Ananthapadmanabhan, Nitin Menon</span></div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function MatchDetailPage() {
  return (
    <Suspense fallback={<div className="p-12 text-center text-slate-500">Loading Match Scoreboard...</div>}>
      <MatchDetailContent />
    </Suspense>
  );
}
