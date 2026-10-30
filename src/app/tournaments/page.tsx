'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { store } from '@/lib/store/mock-db';
import { Trophy, Calendar, MapPin, Users, ArrowRight, Plus } from 'lucide-react';

export default function TournamentsPage() {
  const [state, setState] = useState(() => store.getState());

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-slate-200">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-700 text-xs font-bold uppercase tracking-wider mb-2">
            <Trophy size={14} />
            <span>Cricket Competitions</span>
          </div>
          <h1 className="text-3xl sm:text-4xl font-black text-slate-900 tracking-tight">
            Tournaments Directory
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Browse active leagues, knockout championships, points tables, and team standings.
          </p>
        </div>

        <Link
          href="/organizer/tournaments/new"
          className="px-5 py-3 rounded-2xl bg-cricket-600 hover:bg-cricket-500 text-white font-bold text-xs uppercase tracking-wider shadow-md shadow-cricket-600/20 transition flex items-center gap-2 self-start sm:self-auto"
        >
          <Plus size={16} />
          <span>Create Tournament</span>
        </Link>
      </div>

      {/* Tournaments Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {state.tournaments.map((t) => {
          const teamsCount = state.teams.filter((team) => team.tournamentId === t.id).length;
          const matchesCount = state.matches.filter((m) => m.tournamentId === t.id).length;

          return (
            <div
              key={t.id}
              className="rounded-3xl bg-white border border-slate-200 shadow-xs hover:shadow-md transition overflow-hidden flex flex-col justify-between"
            >
              <div className="h-40 relative bg-slate-900 overflow-hidden">
                {t.bannerUrl && (
                  <img
                    src={t.bannerUrl}
                    alt={t.name}
                    className="w-full h-full object-cover opacity-80"
                  />
                )}
                <div className="absolute top-4 left-4">
                  <span className="px-3 py-1 rounded-full bg-emerald-500 text-slate-950 text-xs font-black uppercase tracking-wider shadow-sm">
                    {t.status.replace(/_/g, ' ')}
                  </span>
                </div>
              </div>

              <div className="p-6 space-y-4 flex-1 flex flex-col justify-between">
                <div>
                  <h3 className="text-xl font-black text-slate-900 tracking-tight">{t.name}</h3>
                  <p className="text-xs text-slate-500 mt-1 line-clamp-2">{t.description}</p>
                </div>

                <div className="space-y-2 pt-2 border-t border-slate-100 text-xs text-slate-600">
                  <div className="flex items-center gap-2">
                    <MapPin size={14} className="text-slate-400 shrink-0" />
                    <span>{t.location}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Calendar size={14} className="text-slate-400 shrink-0" />
                    <span>{t.startDate} to {t.endDate}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Users size={14} className="text-slate-400 shrink-0" />
                    <span>{teamsCount} Teams • {matchesCount} Matches • {t.oversPerInnings} Overs</span>
                  </div>
                </div>

                <div className="pt-4 border-t border-slate-100 flex items-center justify-between">
                  <Link
                    href={`/tournaments/${t.id}/standings`}
                    className="text-xs font-bold text-cricket-600 hover:text-cricket-700 flex items-center gap-1"
                  >
                    <span>Points Table & NRR</span>
                    <ArrowRight size={13} />
                  </Link>

                  <Link
                    href={`/auctions/auc_bpl_2026`}
                    className="text-xs font-bold text-amber-600 hover:text-amber-700 flex items-center gap-1"
                  >
                    <span>Auction</span>
                    <ArrowRight size={13} />
                  </Link>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
