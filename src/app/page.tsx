'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { store } from '@/lib/store/mock-db';
import {
  Trophy,
  Radio,
  Gavel,
  Shield,
  ArrowRight,
  TrendingUp,
  Activity,
  Users,
  Clock,
  Sparkles,
  Award,
  CheckCircle2,
  Calendar,
  Coins,
  ChevronRight,
  PlayCircle,
  FileText,
} from 'lucide-react';

export default function HomePage() {
  const [state, setState] = useState(() => store.getState());
  const [scorecardTab, setScorecardTab] = useState<'live' | 'past' | 'upcoming'>('live');

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  const tournament = state.tournaments[0];
  const liveMatch = state.matches.find((m) => m.status === 'live');
  const pastMatches = state.matches.filter((m) => m.status === 'completed');
  const upcomingMatches = state.matches.filter((m) => m.status === 'scheduled' || m.status === 'toss');

  const liveAuction = state.auctions.find((a) => a.status === 'live');
  const activePoolLot = state.auctionPlayerPool.find((p) => p.id === liveAuction?.currentPoolId);
  const activeLotPlayer = state.players.find((p) => p.id === activePoolLot?.playerId);

  const liveInnings = state.innings.find((i) => i.matchId === liveMatch?.id);
  const liveTeamA = state.teams.find((t) => t.id === liveMatch?.teamAId);
  const liveTeamB = state.teams.find((t) => t.id === liveMatch?.teamBId);

  // Live Crease details
  const liveStriker = state.players.find((p) => p.id === liveInnings?.currentStrikerId);
  const liveNonStriker = state.players.find((p) => p.id === liveInnings?.currentNonStrikerId);
  const liveBowler = state.players.find((p) => p.id === liveInnings?.currentBowlerId);

  const strikerScorecard = state.battingScorecards.find(
    (b) => b.inningsId === liveInnings?.id && b.playerId === liveStriker?.id
  ) || { runs: 62, balls: 38, fours: 6, sixes: 2, strikeRate: 163.2 };

  const nonStrikerScorecard = state.battingScorecards.find(
    (b) => b.inningsId === liveInnings?.id && b.playerId === liveNonStriker?.id
  ) || { runs: 45, balls: 31, fours: 4, sixes: 1, strikeRate: 145.2 };

  const bowlerScorecard = state.bowlingScorecards.find(
    (b) => b.inningsId === liveInnings?.id && b.playerId === liveBowler?.id
  ) || { oversStr: '2.4', maidens: 0, runsConceded: 24, wickets: 1, economy: 9.0 };

  const recentDeliveries = state.deliveries.filter((d) => d.matchId === liveMatch?.id && !d.isUndone);

  return (
    <div className="space-y-12 pb-16">
      {/* HERO SECTION */}
      <section className="relative overflow-hidden bg-gradient-to-br from-slate-950 via-slate-900 to-cricket-950 text-white py-16 sm:py-20 border-b border-slate-800">
        <div className="absolute inset-0 pointer-events-none opacity-20">
          <div className="absolute top-0 right-1/4 w-96 h-96 rounded-full bg-emerald-500 blur-3xl"></div>
          <div className="absolute bottom-0 left-1/3 w-80 h-80 rounded-full bg-amber-500 blur-3xl"></div>
        </div>

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className="max-w-3xl space-y-5">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-bold uppercase tracking-wider">
              <Sparkles size={14} />
              <span>Full-Stack Cricket Tournament & Auction Platform</span>
            </div>

            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-black tracking-tight leading-tight">
              From Player Auction to the <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 to-teal-200">Championship Trophy.</span>
            </h1>

            <p className="text-base sm:text-lg text-slate-300 font-normal leading-relaxed">
              Experience professional cricket tournament operations: spin the player selection wheel, bid in real-time franchise auctions with auto squad assignment, and record matches ball-by-ball with CricHeroes & Cricbuzz level precision.
            </p>

            <div className="flex flex-wrap items-center gap-3 pt-2">
              <Link
                href="/auctions/auc_bpl_2026"
                className="px-6 py-3.5 rounded-2xl bg-gradient-to-r from-amber-500 to-amber-400 hover:from-amber-400 hover:to-amber-300 text-slate-950 font-black text-sm uppercase tracking-wider shadow-lg shadow-amber-500/20 transition flex items-center gap-2 active:scale-95"
              >
                <Gavel size={18} />
                <span>Live Player Auction Stage</span>
              </Link>

              <Link
                href="/matches/match_1"
                className="px-6 py-3.5 rounded-2xl bg-cricket-600 hover:bg-cricket-500 text-white font-black text-sm uppercase tracking-wider shadow-lg shadow-cricket-600/20 transition flex items-center gap-2 active:scale-95"
              >
                <Radio size={18} className="animate-pulse" />
                <span>Live Match Centre</span>
              </Link>

              <Link
                href="/scorer"
                className="px-5 py-3.5 rounded-2xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold text-sm transition border border-slate-700 flex items-center gap-2"
              >
                <span>Scorer Console</span>
                <ArrowRight size={16} />
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* TOP LIVE ACTION CARDS (MATCH + AUCTION) */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 -mt-8 relative z-20">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* LIVE MATCH CARD */}
          {liveMatch && liveInnings && liveTeamA && liveTeamB && (
            <div className="rounded-3xl bg-white border border-slate-200/90 shadow-xl p-6 sm:p-7 flex flex-col justify-between relative overflow-hidden group hover:border-cricket-300 transition">
              <div className="flex items-center justify-between pb-4 border-b border-slate-100">
                <div className="flex items-center gap-2">
                  <span className="flex h-2.5 w-2.5 relative">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-rose-500"></span>
                  </span>
                  <span className="text-xs font-black text-rose-500 uppercase tracking-widest">
                    LIVE MATCH • {liveMatch.stage}
                  </span>
                </div>
                <span className="text-xs text-slate-400 font-medium">{liveMatch.venue}</span>
              </div>

              {/* Team Scores */}
              <div className="py-6 space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center font-black text-white text-xs shadow-md"
                      style={{ backgroundColor: liveTeamA.primaryColor }}
                    >
                      {liveTeamA.shortName}
                    </div>
                    <div>
                      <h3 className="font-bold text-slate-900 text-base">{liveTeamA.name}</h3>
                      <span className="text-xs text-slate-500">Batting 1st</span>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-2xl font-black text-slate-900">
                      {liveInnings.totalRuns}
                      <span className="text-cricket-600">/{liveInnings.wickets}</span>
                    </div>
                    <span className="text-xs font-mono text-slate-500">({liveInnings.oversStr} ov)</span>
                  </div>
                </div>

                <div className="flex items-center justify-between opacity-70">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center font-black text-white text-xs shadow-md"
                      style={{ backgroundColor: liveTeamB.primaryColor }}
                    >
                      {liveTeamB.shortName}
                    </div>
                    <div>
                      <h3 className="font-bold text-slate-900 text-base">{liveTeamB.name}</h3>
                      <span className="text-xs text-slate-500">Yet to bat</span>
                    </div>
                  </div>
                  <span className="text-xs font-semibold text-slate-400">Opted to bowl</span>
                </div>
              </div>

              {/* Footer action */}
              <div className="pt-4 border-t border-slate-100 flex items-center justify-between">
                <span className="text-xs text-slate-500">
                  Current Run Rate: <strong className="text-slate-900">{(liveInnings.totalRuns / (liveInnings.legalBalls / 6 || 1)).toFixed(2)}</strong>
                </span>
                <Link
                  href={`/matches/${liveMatch.id}`}
                  className="px-4 py-2 rounded-xl bg-cricket-50 hover:bg-cricket-100 text-cricket-700 font-bold text-xs transition flex items-center gap-1.5"
                >
                  <span>Ball-by-Ball Scorecard</span>
                  <ArrowRight size={14} />
                </Link>
              </div>
            </div>
          )}

          {/* LIVE AUCTION HIGHLIGHT CARD */}
          {liveAuction && activePoolLot && activeLotPlayer && (
            <div className="rounded-3xl bg-slate-950 text-white border border-slate-800 shadow-xl p-6 sm:p-7 flex flex-col justify-between relative overflow-hidden group">
              <div className="absolute top-0 right-0 w-64 h-64 bg-amber-500/10 rounded-full blur-3xl pointer-events-none"></div>

              <div className="flex items-center justify-between pb-4 border-b border-slate-800 relative z-10">
                <div className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-amber-400 animate-pulse"></span>
                  <span className="text-xs font-black text-amber-400 uppercase tracking-widest">
                    LIVE AUCTION • LOT #{activePoolLot.lotNumber}
                  </span>
                </div>
                <span className="text-xs text-slate-400 capitalize">{activePoolLot.category} Category</span>
              </div>

              {/* Active Player in Auction */}
              <div className="py-5 flex items-center gap-5 relative z-10">
                <div className="w-20 h-20 rounded-2xl overflow-hidden border-2 border-slate-700 bg-slate-800 shrink-0 shadow-lg">
                  <img
                    src={activeLotPlayer.photoUrl}
                    alt={activeLotPlayer.fullName}
                    className="w-full h-full object-cover object-top"
                  />
                </div>
                <div>
                  <h3 className="text-xl font-black text-white">{activeLotPlayer.fullName}</h3>
                  <p className="text-xs text-slate-400 capitalize mt-0.5">
                    {activeLotPlayer.role.replace(/_/g, ' ')} • Base: ₹{activePoolLot.basePrice.toLocaleString('en-IN')}
                  </p>
                  <div className="mt-2 text-sm font-black text-amber-400">
                    Current Bid: {activePoolLot.currentBid ? `₹${activePoolLot.currentBid.toLocaleString('en-IN')}` : 'No Bids Yet'}
                  </div>
                </div>
              </div>

              {/* Footer action */}
              <div className="pt-4 border-t border-slate-800/80 flex items-center justify-between relative z-10">
                <span className="text-xs text-slate-400">
                  {state.auctionPlayerPool.filter((p) => p.status === 'pending').length} lots remaining
                </span>
                <Link
                  href={`/auctions/${liveAuction.id}`}
                  className="px-4 py-2 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-black text-xs uppercase tracking-wider transition flex items-center gap-1.5"
                >
                  <span>Enter Auction Stage</span>
                  <ArrowRight size={14} />
                </Link>
              </div>
            </div>
          )}
        </div>
      </section>

      {/* ============================================================== */}
      {/* COMPREHENSIVE SCORECARD HUB (LIVE, PAST & UPCOMING MATCHES)    */}
      {/* ============================================================== */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-white rounded-3xl border border-slate-200/90 shadow-md overflow-hidden">
          {/* Header & Tabs */}
          <div className="p-6 sm:p-8 bg-gradient-to-r from-slate-900 via-slate-950 to-cricket-950 text-white flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/20 text-emerald-400 text-xs font-bold uppercase tracking-wider mb-2">
                <Activity size={14} />
                <span>Match Scorecard Centre</span>
              </div>
              <h2 className="text-2xl sm:text-3xl font-black tracking-tight text-white">
                Tournament Scorecards & Scoring
              </h2>
              <p className="text-xs sm:text-sm text-slate-400 mt-1">
                Real-time batsman & bowler performance, certified match results, and upcoming tournament fixtures.
              </p>
            </div>

            {/* Scorecard Navigation Tabs */}
            <div className="flex items-center gap-1 bg-slate-900/90 p-1.5 rounded-2xl border border-slate-800 self-start md:self-auto">
              <button
                onClick={() => setScorecardTab('live')}
                className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition ${
                  scorecardTab === 'live'
                    ? 'bg-rose-600 text-white shadow-sm'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                <span className="w-2 h-2 rounded-full bg-rose-300 animate-ping"></span>
                <span>Live Scoring ({liveMatch ? 1 : 0})</span>
              </button>

              <button
                onClick={() => setScorecardTab('past')}
                className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition ${
                  scorecardTab === 'past'
                    ? 'bg-emerald-600 text-white shadow-sm'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                <CheckCircle2 size={13} />
                <span>Past Matches ({pastMatches.length})</span>
              </button>

              <button
                onClick={() => setScorecardTab('upcoming')}
                className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition ${
                  scorecardTab === 'upcoming'
                    ? 'bg-cricket-600 text-white shadow-sm'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                <Calendar size={13} />
                <span>Upcoming ({upcomingMatches.length})</span>
              </button>
            </div>
          </div>

          {/* TAB 1: LIVE SCORING VIEW */}
          {scorecardTab === 'live' && (
            <div className="p-6 sm:p-8 space-y-6">
              {liveMatch && liveInnings && liveTeamA && liveTeamB ? (
                <div className="space-y-6">
                  {/* Live Match Info Bar */}
                  <div className="flex flex-wrap items-center justify-between gap-3 pb-4 border-b border-slate-100 text-xs text-slate-500">
                    <div className="flex items-center gap-2">
                      <span className="px-2.5 py-0.5 rounded-full bg-rose-100 text-rose-700 font-black text-[10px] uppercase tracking-wider">
                        LIVE
                      </span>
                      <span className="font-bold text-slate-800">{liveMatch.stage}</span>
                      <span>•</span>
                      <span>{liveMatch.venue}</span>
                    </div>
                    <div className="text-slate-600 font-semibold">
                      Max {liveMatch.overs} Overs (4 ov per bowler max)
                    </div>
                  </div>

                  {/* High Level Match Scores */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {/* Batting Team */}
                    <div className="p-5 rounded-2xl bg-slate-50 border border-slate-200 flex items-center justify-between">
                      <div className="flex items-center gap-3.5">
                        <div
                          className="w-12 h-12 rounded-2xl flex items-center justify-center font-black text-white text-sm shadow-md"
                          style={{ backgroundColor: liveTeamA.primaryColor }}
                        >
                          {liveTeamA.shortName}
                        </div>
                        <div>
                          <h4 className="font-bold text-slate-900 text-base">{liveTeamA.name}</h4>
                          <span className="text-xs text-slate-500">1st Innings Batting</span>
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-3xl font-black text-slate-900">
                          {liveInnings.totalRuns}
                          <span className="text-cricket-600">/{liveInnings.wickets}</span>
                        </div>
                        <span className="text-xs font-mono text-slate-500">({liveInnings.oversStr} ov)</span>
                      </div>
                    </div>

                    {/* Bowling Team */}
                    <div className="p-5 rounded-2xl bg-slate-50 border border-slate-200 flex items-center justify-between opacity-85">
                      <div className="flex items-center gap-3.5">
                        <div
                          className="w-12 h-12 rounded-2xl flex items-center justify-center font-black text-white text-sm shadow-md"
                          style={{ backgroundColor: liveTeamB.primaryColor }}
                        >
                          {liveTeamB.shortName}
                        </div>
                        <div>
                          <h4 className="font-bold text-slate-900 text-base">{liveTeamB.name}</h4>
                          <span className="text-xs text-slate-500">Fielding (Yet to bat)</span>
                        </div>
                      </div>
                      <div className="text-right">
                        <span className="text-xs font-bold text-slate-400 block">CRR</span>
                        <span className="text-xl font-black text-cricket-700">
                          {(liveInnings.totalRuns / (liveInnings.legalBalls / 6 || 1)).toFixed(2)}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Real-time Batsmen & Bowler Crease HUD */}
                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    {/* Batters at Crease Table */}
                    <div className="p-5 rounded-2xl bg-slate-950 text-white border border-slate-800 shadow-sm space-y-3">
                      <div className="flex items-center justify-between pb-2 border-b border-slate-800">
                        <span className="text-xs font-black uppercase tracking-wider text-emerald-400">
                          Batters at Crease
                        </span>
                        <span className="text-[11px] text-slate-400 font-mono">
                          Partnership: {liveInnings.totalRuns}r ({liveInnings.legalBalls}b)
                        </span>
                      </div>

                      <div className="overflow-x-auto">
                        <table className="w-full text-left text-xs">
                          <thead className="text-slate-400 uppercase text-[10px] font-black border-b border-slate-800">
                            <tr>
                              <th className="pb-2">Batter</th>
                              <th className="pb-2 text-right">R (B)</th>
                              <th className="pb-2 text-right">4s</th>
                              <th className="pb-2 text-right">6s</th>
                              <th className="pb-2 text-right">SR</th>
                            </tr>
                          </thead>
                          <tbody className="divide-y divide-slate-800/60 font-semibold">
                            {/* Striker */}
                            <tr className="text-amber-300">
                              <td className="py-2.5 flex items-center gap-1.5 font-bold">
                                <span>★</span>
                                <span className="text-white">{liveStriker?.displayName || 'Striker'}</span>
                                <span className="text-[9px] px-1 rounded bg-amber-400/20 text-amber-300 font-mono uppercase">
                                  Strike
                                </span>
                              </td>
                              <td className="py-2.5 text-right font-black">
                                {strikerScorecard.runs} <span className="text-slate-400 font-normal">({strikerScorecard.balls})</span>
                              </td>
                              <td className="py-2.5 text-right font-mono text-slate-300">{strikerScorecard.fours}</td>
                              <td className="py-2.5 text-right font-mono text-slate-300">{strikerScorecard.sixes}</td>
                              <td className="py-2.5 text-right font-mono text-emerald-400">{strikerScorecard.strikeRate.toFixed(1)}</td>
                            </tr>
                            {/* Non-Striker */}
                            <tr className="text-slate-300">
                              <td className="py-2.5 flex items-center gap-1.5">
                                <span className="text-slate-600">•</span>
                                <span className="text-slate-200">{liveNonStriker?.displayName || 'Non-Striker'}</span>
                              </td>
                              <td className="py-2.5 text-right font-bold text-white">
                                {nonStrikerScorecard.runs} <span className="text-slate-400 font-normal">({nonStrikerScorecard.balls})</span>
                              </td>
                              <td className="py-2.5 text-right font-mono text-slate-400">{nonStrikerScorecard.fours}</td>
                              <td className="py-2.5 text-right font-mono text-slate-400">{nonStrikerScorecard.sixes}</td>
                              <td className="py-2.5 text-right font-mono text-slate-400">{nonStrikerScorecard.strikeRate.toFixed(1)}</td>
                            </tr>
                          </tbody>
                        </table>
                      </div>
                    </div>

                    {/* Active Bowler Table */}
                    <div className="p-5 rounded-2xl bg-slate-950 text-white border border-slate-800 shadow-sm space-y-3">
                      <div className="flex items-center justify-between pb-2 border-b border-slate-800">
                        <span className="text-xs font-black uppercase tracking-wider text-emerald-400">
                          Active Bowler
                        </span>
                        <span className="text-[11px] text-slate-400">
                          {liveBowler?.bowlingStyle.replace(/_/g, ' ') || 'Right Arm Medium'}
                        </span>
                      </div>

                      <div className="overflow-x-auto">
                        <table className="w-full text-left text-xs">
                          <thead className="text-slate-400 uppercase text-[10px] font-black border-b border-slate-800">
                            <tr>
                              <th className="pb-2">Bowler</th>
                              <th className="pb-2 text-right">O</th>
                              <th className="pb-2 text-right">M</th>
                              <th className="pb-2 text-right">R</th>
                              <th className="pb-2 text-right">W</th>
                              <th className="pb-2 text-right">ECON</th>
                            </tr>
                          </thead>
                          <tbody className="divide-y divide-slate-800/60 font-semibold">
                            <tr className="text-white">
                              <td className="py-2.5 font-bold">
                                {liveBowler?.displayName || 'Active Bowler'}
                              </td>
                              <td className="py-2.5 text-right font-mono">{bowlerScorecard.oversStr}</td>
                              <td className="py-2.5 text-right font-mono text-slate-300">{bowlerScorecard.maidens}</td>
                              <td className="py-2.5 text-right font-mono font-black text-amber-300">{bowlerScorecard.runsConceded}</td>
                              <td className="py-2.5 text-right font-mono font-black text-emerald-400">{bowlerScorecard.wickets}</td>
                              <td className="py-2.5 text-right font-mono text-slate-300">{bowlerScorecard.economy.toFixed(2)}</td>
                            </tr>
                          </tbody>
                        </table>
                      </div>

                      {/* Recent Deliveries */}
                      <div className="pt-2 border-t border-slate-800 flex items-center justify-between text-xs">
                        <span className="text-slate-400 text-[11px]">This Over:</span>
                        <div className="flex items-center gap-1.5">
                          {recentDeliveries.slice(-6).map((d) => (
                            <span
                              key={d.id}
                              className={`w-6 h-6 rounded-full flex items-center justify-center font-mono font-black text-[10px] ${
                                d.isWicket
                                  ? 'bg-rose-600 text-white'
                                  : d.runsBatter === 4
                                  ? 'bg-blue-600 text-white'
                                  : d.runsBatter === 6
                                  ? 'bg-purple-600 text-white'
                                  : 'bg-slate-800 text-slate-200'
                              }`}
                            >
                              {d.isWicket ? 'W' : d.runsBatter}
                            </span>
                          ))}
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Live Actions */}
                  <div className="flex flex-wrap items-center justify-between gap-4 pt-4 border-t border-slate-100">
                    <span className="text-xs text-slate-500">
                      Scoring in progress • Certified under ICC Law 17 &amp; 20-over limitation.
                    </span>

                    <div className="flex items-center gap-3">
                      <Link
                        href={`/matches/${liveMatch.id}`}
                        className="px-5 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 font-bold text-xs transition flex items-center gap-1.5"
                      >
                        <FileText size={14} />
                        <span>Detailed Match Scorecard</span>
                      </Link>

                      <Link
                        href={`/scorer?matchId=${liveMatch.id}`}
                        className="px-5 py-2.5 rounded-xl bg-cricket-600 hover:bg-cricket-500 text-white font-black text-xs uppercase tracking-wider transition flex items-center gap-1.5 shadow-sm active:scale-95"
                      >
                        <PlayCircle size={15} />
                        <span>Open Ball-by-Ball Scorer Console</span>
                      </Link>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="py-12 text-center text-slate-500 text-sm">
                  No live match currently in progress. Start scoring an upcoming match below!
                </div>
              )}
            </div>
          )}

          {/* TAB 2: PAST MATCH SCORING (COMPLETED RESULTS) */}
          {scorecardTab === 'past' && (
            <div className="p-6 sm:p-8 space-y-6">
              {pastMatches.map((pm) => {
                const teamA = state.teams.find((t) => t.id === pm.teamAId);
                const teamB = state.teams.find((t) => t.id === pm.teamBId);
                const inn1 = state.innings.find((i) => i.matchId === pm.id && i.inningsNumber === 1);
                const inn2 = state.innings.find((i) => i.matchId === pm.id && i.inningsNumber === 2);
                const winnerTeam = state.teams.find((t) => t.id === pm.winnerId);

                return (
                  <div key={pm.id} className="p-6 rounded-3xl bg-slate-50 border border-slate-200 space-y-5">
                    {/* Header Banner */}
                    <div className="flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-slate-200 text-xs">
                      <div className="flex items-center gap-2">
                        <span className="px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800 font-black text-[10px] uppercase">
                          COMPLETED
                        </span>
                        <span className="font-bold text-slate-800">{pm.stage}</span>
                        <span>•</span>
                        <span className="text-slate-500">{pm.venue}</span>
                      </div>
                      <div className="text-emerald-700 font-black text-sm flex items-center gap-1.5">
                        <Trophy size={16} className="text-amber-500" />
                        <span>{winnerTeam?.name} won by {pm.winMargin}</span>
                      </div>
                    </div>

                    {/* Innings 1 and 2 Side-by-Side Summary */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {/* Innings 1 */}
                      <div className="p-4 rounded-2xl bg-white border border-slate-200 shadow-xs space-y-3">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2.5">
                            <div
                              className="w-8 h-8 rounded-lg flex items-center justify-center font-black text-white text-xs"
                              style={{ backgroundColor: teamA?.primaryColor }}
                            >
                              {teamA?.shortName}
                            </div>
                            <div>
                              <h4 className="font-bold text-slate-900 text-sm">{teamA?.name}</h4>
                              <span className="text-[10px] text-slate-400">1st Innings</span>
                            </div>
                          </div>
                          <div className="text-right">
                            <div className="text-xl font-black text-slate-900">
                              {inn1?.totalRuns}/{inn1?.wickets}
                            </div>
                            <span className="text-xs text-slate-500 font-mono">({inn1?.oversStr} ov)</span>
                          </div>
                        </div>

                        <div className="pt-2 border-t border-slate-100 grid grid-cols-2 gap-2 text-xs text-slate-600">
                          <div>
                            <span className="text-[10px] text-slate-400 block font-bold">Top Batter</span>
                            <span className="font-bold text-slate-900">Rahul Das</span>
                            <span className="text-slate-500 block text-[11px]">68 (42b, 7x4, 3x6)</span>
                          </div>
                          <div>
                            <span className="text-[10px] text-slate-400 block font-bold">Top Bowler</span>
                            <span className="font-bold text-slate-900">Akash Deep</span>
                            <span className="text-slate-500 block text-[11px]">2/32 (4.0 ov)</span>
                          </div>
                        </div>
                      </div>

                      {/* Innings 2 */}
                      <div className="p-4 rounded-2xl bg-white border border-slate-200 shadow-xs space-y-3">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2.5">
                            <div
                              className="w-8 h-8 rounded-lg flex items-center justify-center font-black text-white text-xs"
                              style={{ backgroundColor: teamB?.primaryColor }}
                            >
                              {teamB?.shortName}
                            </div>
                            <div>
                              <h4 className="font-bold text-slate-900 text-sm">{teamB?.name}</h4>
                              <span className="text-[10px] text-slate-400">2nd Innings (Chased {inn2?.targetRuns})</span>
                            </div>
                          </div>
                          <div className="text-right">
                            <div className="text-xl font-black text-slate-900">
                              {inn2?.totalRuns}/{inn2?.wickets}
                            </div>
                            <span className="text-xs text-slate-500 font-mono">({inn2?.oversStr} ov)</span>
                          </div>
                        </div>

                        <div className="pt-2 border-t border-slate-100 grid grid-cols-2 gap-2 text-xs text-slate-600">
                          <div>
                            <span className="text-[10px] text-slate-400 block font-bold">Top Batter</span>
                            <span className="font-bold text-slate-900">Manoj Tiwary</span>
                            <span className="text-slate-500 block text-[11px]">52 (36b, 5x4, 2x6)</span>
                          </div>
                          <div>
                            <span className="text-[10px] text-slate-400 block font-bold">Top Bowler</span>
                            <span className="font-bold text-slate-900">Tanmoy Das</span>
                            <span className="text-slate-500 block text-[11px]">3/28 (4.0 ov)</span>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Footer Actions */}
                    <div className="pt-2 flex items-center justify-between">
                      <span className="text-xs text-slate-500">Player of the Match: <strong>Rahul Das (BBL)</strong></span>
                      <Link
                        href={`/matches/${pm.id}?tab=scorecard`}
                        className="px-4 py-2 rounded-xl bg-cricket-600 hover:bg-cricket-500 text-white font-bold text-xs transition flex items-center gap-1.5 shadow-xs"
                      >
                        <span>View Certified Full Scorecard</span>
                        <ArrowRight size={13} />
                      </Link>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* TAB 3: UPCOMING MATCH SCORING (FIXTURES & TOSS LAUNCHER) */}
          {scorecardTab === 'upcoming' && (
            <div className="p-6 sm:p-8 space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                {upcomingMatches.map((m) => {
                  const teamA = state.teams.find((t) => t.id === m.teamAId);
                  const teamB = state.teams.find((t) => t.id === m.teamBId);

                  return (
                    <div
                      key={m.id}
                      className="p-6 rounded-3xl bg-slate-50 border border-slate-200 hover:border-cricket-300 shadow-xs hover:shadow-md transition space-y-4 flex flex-col justify-between"
                    >
                      <div>
                        <div className="flex items-center justify-between pb-3 border-b border-slate-200 text-xs">
                          <span className="font-bold text-slate-700 uppercase tracking-wider">{m.stage}</span>
                          <span className="px-2.5 py-0.5 rounded-full bg-slate-200 text-slate-700 font-bold text-[10px] uppercase">
                            SCHEDULED
                          </span>
                        </div>

                        {/* Competing Teams */}
                        <div className="py-4 space-y-3">
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
                            <span className="text-xs text-slate-400 font-medium">Ready</span>
                          </div>

                          <div className="flex items-center justify-center text-xs text-slate-400 font-black tracking-widest uppercase">
                            VS
                          </div>

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
                            <span className="text-xs text-slate-400 font-medium">Ready</span>
                          </div>
                        </div>

                        <div className="text-xs text-slate-500 space-y-1 pt-1">
                          <div>📍 <strong>Venue:</strong> {m.venue}</div>
                          <div>⏱️ <strong>Format:</strong> {m.overs} Overs T20</div>
                        </div>
                      </div>

                      {/* Conduct Toss & Score Action Button */}
                      <div className="pt-4 border-t border-slate-200 flex items-center gap-2">
                        <Link
                          href={`/matches/${m.id}?tab=squads`}
                          className="flex-1 py-2.5 rounded-xl bg-white hover:bg-slate-100 text-slate-700 border border-slate-200 font-bold text-xs text-center transition"
                        >
                          View Squads
                        </Link>

                        <Link
                          href={`/scorer?matchId=${m.id}`}
                          className="flex-1 py-2.5 rounded-xl bg-cricket-600 hover:bg-cricket-500 text-white font-black text-xs text-center uppercase tracking-wider transition shadow-sm flex items-center justify-center gap-1.5 active:scale-95"
                        >
                          <Coins size={14} />
                          <span>Conduct Toss &amp; Score</span>
                        </Link>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      </section>

      {/* TOURNAMENT OVERVIEW & POINTS TABLE */}
      {tournament && (
        <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col sm:flex-row sm:items-end justify-between mb-6">
            <div>
              <span className="text-xs font-bold text-cricket-600 uppercase tracking-widest block">
                Featured Competition
              </span>
              <h2 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight mt-0.5">
                {tournament.name}
              </h2>
            </div>
            <Link
              href={`/tournaments/${tournament.id}/standings`}
              className="text-xs font-bold text-cricket-600 hover:text-cricket-700 flex items-center gap-1 mt-2 sm:mt-0"
            >
              <span>View Full Points Table & Net Run Rate</span>
              <ArrowRight size={14} />
            </Link>
          </div>

          {/* Points Table Snapshot */}
          <div className="bg-white rounded-3xl border border-slate-200 shadow-xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 text-slate-500 font-bold uppercase tracking-wider border-b border-slate-100">
                  <tr>
                    <th className="px-6 py-3.5">Rank & Team</th>
                    <th className="px-4 py-3.5 text-center">Played</th>
                    <th className="px-4 py-3.5 text-center">Won</th>
                    <th className="px-4 py-3.5 text-center">Lost</th>
                    <th className="px-4 py-3.5 text-center">Pts</th>
                    <th className="px-6 py-3.5 text-right">Net Run Rate</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {state.tournamentStandings.slice(0, 5).map((row, idx) => (
                    <tr key={row.teamId} className="hover:bg-slate-50/80 transition">
                      <td className="px-6 py-4 flex items-center gap-3">
                        <span className="font-bold text-slate-400 w-4">{idx + 1}</span>
                        <div className="w-7 h-7 rounded-lg overflow-hidden bg-slate-100 border border-slate-200 shrink-0">
                          <img src={row.teamLogoUrl} alt={row.teamName} className="w-full h-full object-cover" />
                        </div>
                        <div>
                          <span className="font-bold text-slate-900 block">{row.teamName}</span>
                          <span className="text-[10px] text-slate-400 uppercase font-mono">{row.teamShortName}</span>
                        </div>
                      </td>
                      <td className="px-4 py-4 text-center text-slate-600">{row.matchesPlayed}</td>
                      <td className="px-4 py-4 text-center font-bold text-emerald-600">{row.won}</td>
                      <td className="px-4 py-4 text-center text-slate-500">{row.lost}</td>
                      <td className="px-4 py-4 text-center font-black text-slate-900 text-sm">{row.points}</td>
                      <td className={`px-6 py-4 text-right font-mono font-bold ${
                        row.netRunRate >= 0 ? 'text-emerald-600' : 'text-rose-600'
                      }`}>
                        {row.netRunRate > 0 ? `+${row.netRunRate.toFixed(3)}` : row.netRunRate.toFixed(3)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </section>
      )}

      {/* TOP PERFORMERS & SQUADS HIGHLIGHT */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <h2 className="text-xl font-black text-slate-900 tracking-tight mb-4 flex items-center gap-2">
          <Award size={20} className="text-amber-500" />
          <span>Tournament Top Performers</span>
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {state.players.slice(0, 4).map((player) => (
            <Link
              key={player.id}
              href={`/players/${player.id}`}
              className="p-4 rounded-2xl bg-white border border-slate-200 hover:border-cricket-300 shadow-xs hover:shadow-md transition flex items-center gap-3.5 group"
            >
              <div className="w-14 h-14 rounded-xl overflow-hidden border border-slate-200 shrink-0 bg-slate-100">
                <img src={player.photoUrl} alt={player.fullName} className="w-full h-full object-cover object-top group-hover:scale-105 transition" />
              </div>
              <div className="flex-1 min-w-0">
                <h4 className="font-bold text-slate-900 text-sm truncate group-hover:text-cricket-600 transition">
                  {player.fullName}
                </h4>
                <span className="text-[11px] text-slate-500 capitalize block">{player.role.replace(/_/g, ' ')}</span>
                <div className="flex items-center gap-3 mt-1 text-xs">
                  <span className="text-slate-600 font-semibold">{player.runs} Runs</span>
                  <span className="text-slate-400">•</span>
                  <span className="text-emerald-600 font-semibold">{player.wickets} Wkts</span>
                </div>
              </div>
            </Link>
          ))}
        </div>
      </section>
    </div>
  );
}
