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
} from 'lucide-react';

export default function HomePage() {
  const [state, setState] = useState(() => store.getState());

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  const tournament = state.tournaments[0];
  const liveMatch = state.matches.find((m) => m.status === 'live');
  const liveAuction = state.auctions.find((a) => a.status === 'live');
  const activePoolLot = state.auctionPlayerPool.find((p) => p.id === liveAuction?.currentPoolId);
  const activeLotPlayer = state.players.find((p) => p.id === activePoolLot?.playerId);
  const innings = state.innings.find((i) => i.matchId === liveMatch?.id);
  const teamA = state.teams.find((t) => t.id === liveMatch?.teamAId);
  const teamB = state.teams.find((t) => t.id === liveMatch?.teamBId);

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
          {liveMatch && innings && teamA && teamB && (
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
                      style={{ backgroundColor: teamA.primaryColor }}
                    >
                      {teamA.shortName}
                    </div>
                    <div>
                      <h3 className="font-bold text-slate-900 text-base">{teamA.name}</h3>
                      <span className="text-xs text-slate-500">Batting 1st</span>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-2xl font-black text-slate-900">
                      {innings.totalRuns}
                      <span className="text-cricket-600">/{innings.wickets}</span>
                    </div>
                    <span className="text-xs font-mono text-slate-500">({innings.oversStr} ov)</span>
                  </div>
                </div>

                <div className="flex items-center justify-between opacity-70">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center font-black text-white text-xs shadow-md"
                      style={{ backgroundColor: teamB.primaryColor }}
                    >
                      {teamB.shortName}
                    </div>
                    <div>
                      <h3 className="font-bold text-slate-900 text-base">{teamB.name}</h3>
                      <span className="text-xs text-slate-500">Yet to bat</span>
                    </div>
                  </div>
                  <span className="text-xs font-semibold text-slate-400">Opted to bowl</span>
                </div>
              </div>

              {/* Footer action */}
              <div className="pt-4 border-t border-slate-100 flex items-center justify-between">
                <span className="text-xs text-slate-500">
                  Current Run Rate: <strong className="text-slate-900">{(innings.totalRuns / (innings.legalBalls / 6)).toFixed(2)}</strong>
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
