'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { store } from '@/lib/store/mock-db';
import { ArrowLeft, DollarSign, Users, Trophy, Calendar, MapPin, ArrowRight } from 'lucide-react';

export default function TeamDetailPage() {
  const params = useParams();
  const teamId = (params?.id as string) || 'team_barasat';

  const [state, setState] = useState(() => store.getState());

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  const team = state.teams.find((t) => t.id === teamId) || state.teams[0];
  const squad = state.tournamentPlayers
    .filter((tp) => tp.teamId === team.id && tp.status === 'sold')
    .map((tp) => ({
      ...tp,
      player: state.players.find((p) => p.id === tp.playerId),
    }));

  const teamMatches = state.matches.filter((m) => m.teamAId === team.id || m.teamBId === team.id);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-8">
      {/* Back button */}
      <div>
        <Link
          href="/teams"
          className="inline-flex items-center gap-1.5 text-xs font-bold text-slate-500 hover:text-slate-800 transition"
        >
          <ArrowLeft size={14} />
          <span>Back to Teams Directory</span>
        </Link>
      </div>

      {/* Team Profile Banner */}
      <div className="rounded-3xl bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 text-white p-6 sm:p-8 shadow-xl border border-slate-800">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="flex items-center gap-4">
            <div
              className="w-16 h-16 rounded-2xl flex items-center justify-center font-black text-white text-xl shadow-lg"
              style={{ backgroundColor: team.primaryColor }}
            >
              {team.shortName}
            </div>
            <div>
              <h1 className="text-2xl sm:text-3xl font-black text-white tracking-tight">{team.name}</h1>
              <span className="text-xs text-slate-400">Franchise Owner: <strong className="text-white">{team.ownerName}</strong></span>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-4 text-xs">
            <div className="p-3 rounded-2xl bg-slate-900 border border-slate-800">
              <span className="text-[10px] text-slate-400 uppercase tracking-wider block font-bold">Remaining Purse</span>
              <span className="text-lg font-black text-emerald-400">
                ₹{team.remainingPurse.toLocaleString('en-IN')}
              </span>
            </div>
            <div className="p-3 rounded-2xl bg-slate-900 border border-slate-800">
              <span className="text-[10px] text-slate-400 uppercase tracking-wider block font-bold">Squad Size</span>
              <span className="text-lg font-black text-white">{squad.length} / 18 Players</span>
            </div>
          </div>
        </div>
      </div>

      {/* Squad Roster */}
      <div className="space-y-4">
        <h2 className="text-xl font-black text-slate-900 tracking-tight flex items-center gap-2">
          <Users size={20} className="text-cricket-600" />
          <span>Squad Roster & Auction Purchases</span>
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {squad.map((item) => (
            <div
              key={item.id}
              className="p-4 rounded-2xl bg-white border border-slate-200 shadow-xs flex items-center gap-3.5"
            >
              <div className="w-14 h-14 rounded-xl overflow-hidden bg-slate-100 border border-slate-200 shrink-0">
                {item.player?.photoUrl && (
                  <img
                    src={item.player.photoUrl}
                    alt={item.player.fullName}
                    className="w-full h-full object-cover object-top"
                  />
                )}
              </div>
              <div className="flex-1 min-w-0">
                <Link
                  href={`/players/${item.playerId}`}
                  className="font-bold text-slate-900 text-sm truncate hover:text-cricket-600 block transition"
                >
                  {item.player?.fullName}
                </Link>
                <span className="text-[11px] text-slate-500 capitalize block">
                  {item.player?.role.replace(/_/g, ' ')}
                </span>
                <span className="text-xs font-black text-emerald-600 mt-0.5 block">
                  Acquired for ₹{item.finalPrice?.toLocaleString('en-IN')}
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Team Fixtures & Results */}
      <div className="space-y-4">
        <h2 className="text-xl font-black text-slate-900 tracking-tight flex items-center gap-2">
          <Calendar size={20} className="text-slate-700" />
          <span>Team Fixtures & Match History</span>
        </h2>

        <div className="space-y-3">
          {teamMatches.map((m) => {
            const oppTeam = state.teams.find((t) => t.id === (m.teamAId === team.id ? m.teamBId : m.teamAId));
            return (
              <div
                key={m.id}
                className="p-4 rounded-2xl bg-white border border-slate-200 shadow-xs flex items-center justify-between text-xs"
              >
                <div>
                  <span className="font-bold text-slate-900 text-sm block">vs {oppTeam?.name}</span>
                  <span className="text-slate-500">{m.stage} • {m.venue}</span>
                </div>
                <div className="flex items-center gap-3">
                  <span
                    className={`px-2.5 py-1 rounded-full font-bold uppercase text-[10px] ${
                      m.status === 'live'
                        ? 'bg-rose-500 text-white'
                        : m.status === 'completed'
                        ? 'bg-emerald-100 text-emerald-800'
                        : 'bg-slate-100 text-slate-700'
                    }`}
                  >
                    {m.status}
                  </span>
                  <Link
                    href={`/matches/${m.id}`}
                    className="p-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 transition"
                  >
                    <ArrowRight size={14} />
                  </Link>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
