'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { store } from '@/lib/store/mock-db';
import { PlayerRole } from '@/lib/types';
import { Award, Search, ArrowRight, Shield, Activity } from 'lucide-react';

export default function PlayersPage() {
  const [state, setState] = useState(() => store.getState());
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('all');

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  const filteredPlayers = state.players.filter((p) => {
    const matchesSearch =
      p.fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (p.city && p.city.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesRole = roleFilter === 'all' || p.role === roleFilter;
    return matchesSearch && matchesRole;
  });

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-slate-200">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-700 text-xs font-bold uppercase tracking-wider mb-2">
            <Award size={14} />
            <span>Cricket Talent Database</span>
          </div>
          <h1 className="text-3xl sm:text-4xl font-black text-slate-900 tracking-tight">
            Verified Players Directory
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Browse registered players, batting & bowling career records, auction status, and team assignments.
          </p>
        </div>

        {/* Search & Filter */}
        <div className="flex flex-wrap items-center gap-2">
          <div className="relative">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Search by player name or city..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9 pr-3 py-2 rounded-xl border border-slate-300 text-xs bg-white w-56 sm:w-64"
            />
          </div>

          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="p-2 rounded-xl border border-slate-300 text-xs font-semibold bg-white"
          >
            <option value="all">All Roles</option>
            <option value="batter">Batters</option>
            <option value="bowler">Bowlers</option>
            <option value="all_rounder">All-Rounders</option>
            <option value="wicket_keeper">Wicket-Keepers</option>
          </select>
        </div>
      </div>

      {/* Players Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {filteredPlayers.map((player) => {
          const tp = state.tournamentPlayers.find((t) => t.playerId === player.id);
          const team = tp?.teamId ? state.teams.find((t) => t.id === tp.teamId) : null;

          return (
            <Link
              key={player.id}
              href={`/players/${player.id}`}
              className="p-5 rounded-3xl bg-white border border-slate-200 hover:border-cricket-300 shadow-xs hover:shadow-md transition flex flex-col justify-between group"
            >
              <div>
                <div className="relative w-full h-44 rounded-2xl overflow-hidden bg-slate-100 border border-slate-200 mb-4">
                  <img
                    src={player.photoUrl}
                    alt={player.fullName}
                    className="w-full h-full object-cover object-top group-hover:scale-105 transition"
                  />
                  {team && (
                    <div className="absolute top-2 right-2 px-2.5 py-1 rounded-full text-[10px] font-black uppercase text-white shadow-sm" style={{ backgroundColor: team.primaryColor }}>
                      {team.shortName}
                    </div>
                  )}
                </div>

                <h3 className="font-bold text-slate-900 text-base group-hover:text-cricket-600 transition truncate">
                  {player.fullName}
                </h3>
                <span className="text-xs text-slate-500 capitalize block mt-0.5">
                  {player.role.replace(/_/g, ' ')} • {player.city || 'Bengal'}
                </span>

                <div className="grid grid-cols-2 gap-2 mt-4 pt-3 border-t border-slate-100 text-center">
                  <div className="p-2 rounded-xl bg-slate-50">
                    <span className="text-[10px] uppercase font-bold text-slate-400 block">Runs</span>
                    <span className="font-black text-slate-900 text-sm">{player.runs}</span>
                    <span className="text-[10px] text-slate-500 block">SR: {player.strikeRate}</span>
                  </div>
                  <div className="p-2 rounded-xl bg-slate-50">
                    <span className="text-[10px] uppercase font-bold text-slate-400 block">Wickets</span>
                    <span className="font-black text-slate-900 text-sm">{player.wickets}</span>
                    <span className="text-[10px] text-slate-500 block">Econ: {player.economy}</span>
                  </div>
                </div>
              </div>

              <div className="pt-3 mt-3 border-t border-slate-100 flex items-center justify-between text-xs text-cricket-600 font-bold">
                <span>View Full Profile</span>
                <ArrowRight size={14} />
              </div>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
