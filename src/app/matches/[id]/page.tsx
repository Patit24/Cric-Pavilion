'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
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
} from 'lucide-react';

export default function MatchDetailPage() {
  const params = useParams();
  const matchId = (params?.id as string) || 'match_1';

  const [state, setState] = useState(() => store.getState());
  const [activeTab, setActiveTab] = useState<'live' | 'scorecard' | 'commentary' | 'squads' | 'info'>('live');

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  const match = state.matches.find((m) => m.id === matchId) || state.matches[0];
  const tournament = state.tournaments.find((t) => t.id === match?.tournamentId);
  const teamA = state.teams.find((t) => t.id === match?.teamAId);
  const teamB = state.teams.find((t) => t.id === match?.teamBId);
  const currentInnings = state.innings.find((i) => i.matchId === match?.id);

  const battingCards = state.battingScorecards.filter((b) => b.matchId === match?.id);
  const bowlingCards = state.bowlingScorecards.filter((b) => b.matchId === match?.id);
  const matchDeliveries = state.deliveries.filter((d) => d.matchId === match?.id && !d.isUndone);

  // Batters on crease
  const striker = state.players.find((p) => p.id === currentInnings?.currentStrikerId);
  const nonStriker = state.players.find((p) => p.id === currentInnings?.currentNonStrikerId);
  const bowler = state.players.find((p) => p.id === currentInnings?.currentBowlerId);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
      {/* Match Header Banner */}
      <div className="rounded-3xl bg-gradient-to-br from-slate-950 via-slate-900 to-cricket-950 text-white p-6 sm:p-8 shadow-xl border border-slate-800">
        <div className="flex flex-wrap items-center justify-between gap-4 pb-4 border-b border-slate-800 text-xs">
          <div className="flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-rose-500 animate-pulse"></span>
            <span className="font-bold text-rose-400 uppercase tracking-widest">
              {match.status === 'live' ? 'LIVE NOW' : match.status.toUpperCase()}
            </span>
            <span className="text-slate-500">•</span>
            <span className="text-slate-300 font-semibold">{tournament?.name}</span>
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
                <span className="text-xs text-slate-400">1st Innings</span>
              </div>
            </div>
            {currentInnings && (
              <div className="text-right">
                <div className="text-3xl font-black text-white">
                  {currentInnings.totalRuns}
                  <span className="text-cricket-400">/{currentInnings.wickets}</span>
                </div>
                <span className="text-xs font-mono text-slate-400">({currentInnings.oversStr} ov)</span>
              </div>
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
                <span className="text-xs text-slate-400">Yet to bat</span>
              </div>
            </div>
            <span className="text-xs text-slate-400 font-medium">Opted to field</span>
          </div>
        </div>

        {/* Live Toss Status */}
        <div className="pt-4 border-t border-slate-800/80 flex flex-wrap items-center justify-between text-xs text-slate-400">
          <div>
            Toss: <strong className="text-white">{teamB?.name}</strong> won the toss and elected to field
          </div>
          {currentInnings && (
            <div>
              CRR: <strong className="text-cricket-400">{(currentInnings.totalRuns / (currentInnings.legalBalls / 6)).toFixed(2)}</strong>
            </div>
          )}
        </div>
      </div>

      {/* MATCH TABS */}
      <div className="border-b border-slate-200">
        <nav className="flex space-x-6 overflow-x-auto text-sm font-bold">
          {[
            { id: 'live', label: 'Live Scoreboard' },
            { id: 'scorecard', label: 'Full Scorecard' },
            { id: 'commentary', label: 'Ball-by-Ball Commentary' },
            { id: 'squads', label: 'Playing XIs' },
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

      {/* TAB 1: LIVE SCOREBOARD */}
      {activeTab === 'live' && (
        <div className="space-y-6">
          {/* Batters & Bowler at Crease */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="p-5 rounded-2xl bg-white border border-slate-200 shadow-xs space-y-3">
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400">Batters at Crease</h4>
              <div className="divide-y divide-slate-100 text-xs">
                {striker && (
                  <div className="py-2.5 flex items-center justify-between">
                    <div>
                      <span className="font-bold text-slate-900 flex items-center gap-1">
                        <span className="text-amber-500">★</span> {striker.fullName}
                      </span>
                      <span className="text-[11px] text-slate-500">Striker</span>
                    </div>
                    <span className="font-black text-slate-900 text-sm">34* (22b, 4x4, 1x6)</span>
                  </div>
                )}
                {nonStriker && (
                  <div className="py-2.5 flex items-center justify-between">
                    <div>
                      <span className="font-bold text-slate-900">{nonStriker.fullName}</span>
                      <span className="text-[11px] text-slate-500 block">Non-Striker</span>
                    </div>
                    <span className="font-black text-slate-900 text-sm">28* (18b, 3x4)</span>
                  </div>
                )}
              </div>
            </div>

            <div className="p-5 rounded-2xl bg-white border border-slate-200 shadow-xs space-y-3">
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400">Current Bowler</h4>
              {bowler ? (
                <div className="flex items-center justify-between text-xs py-2">
                  <div>
                    <span className="font-bold text-slate-900 text-sm block">{bowler.fullName}</span>
                    <span className="text-[11px] text-slate-500 capitalize">{bowler.bowlingStyle.replace(/_/g, ' ')}</span>
                  </div>
                  <div className="text-right">
                    <span className="font-black text-slate-900 text-sm">2.3-0-18-1</span>
                    <span className="text-[10px] text-slate-500 block">Econ: 7.20</span>
                  </div>
                </div>
              ) : (
                <p className="text-xs text-slate-400 py-4">Waiting for bowler selection...</p>
              )}
            </div>
          </div>

          {/* Recent Deliveries Carousel */}
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
        </div>
      )}

      {/* TAB 2: FULL SCORECARD */}
      {activeTab === 'scorecard' && (
        <div className="space-y-6">
          {/* Batting Card */}
          <div className="bg-white rounded-3xl border border-slate-200 shadow-xs overflow-hidden">
            <div className="px-6 py-4 bg-slate-50 border-b border-slate-200 font-bold text-slate-900 text-sm flex items-center justify-between">
              <span>{teamA?.name} — 1st Innings Batting</span>
              <span className="font-black text-cricket-700">{currentInnings?.totalRuns}/{currentInnings?.wickets} ({currentInnings?.oversStr} Ov)</span>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50/50 text-slate-500 font-bold uppercase tracking-wider border-b border-slate-100">
                  <tr>
                    <th className="px-6 py-3">Batter</th>
                    <th className="px-4 py-3">Dismissal</th>
                    <th className="px-3 py-3 text-right">R</th>
                    <th className="px-3 py-3 text-right">B</th>
                    <th className="px-3 py-3 text-right">4s</th>
                    <th className="px-3 py-3 text-right">6s</th>
                    <th className="px-6 py-3 text-right">SR</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {battingCards.map((b) => (
                    <tr key={b.id} className="hover:bg-slate-50/50">
                      <td className="px-6 py-3.5 font-bold text-slate-900">{b.playerName}</td>
                      <td className="px-4 py-3.5 text-slate-500">{b.dismissalText}</td>
                      <td className="px-3 py-3.5 text-right font-black text-slate-900">{b.runs}</td>
                      <td className="px-3 py-3.5 text-right text-slate-600">{b.balls}</td>
                      <td className="px-3 py-3.5 text-right text-slate-600">{b.fours}</td>
                      <td className="px-3 py-3.5 text-right text-slate-600">{b.sixes}</td>
                      <td className="px-6 py-3.5 text-right font-mono text-slate-700">{b.strikeRate.toFixed(2)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Bowling Card */}
          <div className="bg-white rounded-3xl border border-slate-200 shadow-xs overflow-hidden">
            <div className="px-6 py-4 bg-slate-50 border-b border-slate-200 font-bold text-slate-900 text-sm">
              <span>{teamB?.name} — Bowling Figures</span>
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
                  {bowlingCards.map((bowl) => (
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

      {/* TAB 3: BALL-BY-BALL COMMENTARY */}
      {activeTab === 'commentary' && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-xs p-6 space-y-4">
          <h3 className="text-base font-bold text-slate-900 border-b border-slate-100 pb-3">
            Ball-by-Ball Live Feed
          </h3>

          <div className="space-y-3">
            {matchDeliveries.slice().reverse().map((del, idx) => (
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
            ))}
          </div>
        </div>
      )}

      {/* TAB 4: PLAYING XIS */}
      {activeTab === 'squads' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="p-6 rounded-3xl bg-white border border-slate-200 shadow-xs space-y-3">
            <h3 className="font-bold text-slate-900 text-base">{teamA?.name} Squad</h3>
            <div className="divide-y divide-slate-100 text-xs">
              {state.players.slice(0, 5).map((p) => (
                <div key={p.id} className="py-2.5 flex items-center justify-between">
                  <span className="font-bold text-slate-800">{p.fullName}</span>
                  <span className="text-slate-500 capitalize">{p.role.replace(/_/g, ' ')}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="p-6 rounded-3xl bg-white border border-slate-200 shadow-xs space-y-3">
            <h3 className="font-bold text-slate-900 text-base">{teamB?.name} Squad</h3>
            <div className="divide-y divide-slate-100 text-xs">
              {state.players.slice(5, 10).map((p) => (
                <div key={p.id} className="py-2.5 flex items-center justify-between">
                  <span className="font-bold text-slate-800">{p.fullName}</span>
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
