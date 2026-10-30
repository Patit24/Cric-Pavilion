'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { store } from '@/lib/store/mock-db';
import { Trophy, Gavel, Radio, Plus, Settings, Users, ArrowRight, Shield } from 'lucide-react';

export default function OrganizerDashboardPage() {
  const [state, setState] = useState(() => store.getState());

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  const tournament = state.tournaments[0];
  const auction = state.auctions[0];
  const liveMatch = state.matches.find((m) => m.status === 'live');

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-slate-200">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-50 border border-amber-200 text-amber-700 text-xs font-bold uppercase tracking-wider mb-2">
            <Trophy size={14} />
            <span>Tournament Director</span>
          </div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tight">
            Organizer Command Hub
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Manage competitions, live player auction stages, fixtures, and scorer assignments.
          </p>
        </div>

        <Link
          href="/organizer/tournaments/new"
          className="px-5 py-3 rounded-2xl bg-cricket-600 hover:bg-cricket-500 text-white font-bold text-xs uppercase tracking-wider shadow-md shadow-cricket-600/20 transition flex items-center gap-2 self-start sm:self-auto"
        >
          <Plus size={16} />
          <span>New Tournament</span>
        </Link>
      </div>

      {/* Quick Action Bento Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Auction Card */}
        <div className="p-6 rounded-3xl bg-slate-950 text-white border border-slate-800 shadow-xl flex flex-col justify-between space-y-4">
          <div>
            <div className="w-10 h-10 rounded-xl bg-amber-500 flex items-center justify-center text-slate-950 mb-3 font-bold">
              <Gavel size={20} />
            </div>
            <h3 className="text-lg font-bold text-white">Player Auction Controls</h3>
            <p className="text-xs text-slate-400 mt-1">
              Spin the player selection wheel, oversee live franchise bidding, confirm sales, and manage team purses.
            </p>
          </div>
          <Link
            href={`/auctions/${auction?.id || 'auc_bpl_2026'}/control`}
            className="py-2.5 px-4 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-black text-xs uppercase tracking-wider transition flex items-center justify-center gap-2"
          >
            <span>Open Control Room</span>
            <ArrowRight size={14} />
          </Link>
        </div>

        {/* Live Match Card */}
        <div className="p-6 rounded-3xl bg-white border border-slate-200 shadow-xs flex flex-col justify-between space-y-4">
          <div>
            <div className="w-10 h-10 rounded-xl bg-rose-100 text-rose-600 flex items-center justify-center mb-3 font-bold">
              <Radio size={20} />
            </div>
            <h3 className="text-lg font-bold text-slate-900">Live Match Monitoring</h3>
            <p className="text-xs text-slate-500 mt-1">
              Monitor active ball-by-ball scoring, review umpire decisions, and verify match results.
            </p>
          </div>
          <Link
            href="/scorer"
            className="py-2.5 px-4 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs uppercase tracking-wider transition flex items-center justify-center gap-2"
          >
            <span>Scorer Console</span>
            <ArrowRight size={14} />
          </Link>
        </div>

        {/* Teams & Squads Card */}
        <div className="p-6 rounded-3xl bg-white border border-slate-200 shadow-xs flex flex-col justify-between space-y-4">
          <div>
            <div className="w-10 h-10 rounded-xl bg-emerald-100 text-cricket-600 flex items-center justify-center mb-3 font-bold">
              <Users size={20} />
            </div>
            <h3 className="text-lg font-bold text-slate-900">Franchise Teams & Roster</h3>
            <p className="text-xs text-slate-500 mt-1">
              5 registered teams, {state.players.length} registered players in pool, purse allocations.
            </p>
          </div>
          <Link
            href="/teams"
            className="py-2.5 px-4 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 font-bold text-xs uppercase tracking-wider transition flex items-center justify-center gap-2"
          >
            <span>Manage Teams</span>
            <ArrowRight size={14} />
          </Link>
        </div>
      </div>
    </div>
  );
}
