'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { store } from '@/lib/store/mock-db';
import { Users, DollarSign, ArrowRight, Shield } from 'lucide-react';

export default function TeamsPage() {
  const [state, setState] = useState(() => store.getState());

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-8">
      {/* Header */}
      <div className="pb-6 border-b border-slate-200">
        <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-700 text-xs font-bold uppercase tracking-wider mb-2">
          <Users size={14} />
          <span>Cricket Franchises</span>
        </div>
        <h1 className="text-3xl sm:text-4xl font-black text-slate-900 tracking-tight">
          Participating Teams & Squads
        </h1>
        <p className="text-sm text-slate-500 mt-1">
          Explore team rosters, auction purchases, remaining purse allowances, and match performances.
        </p>
      </div>

      {/* Teams Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {state.teams.map((team) => {
          const squad = state.tournamentPlayers
            .filter((tp) => tp.teamId === team.id && tp.status === 'sold')
            .map((tp) => ({
              ...tp,
              player: state.players.find((p) => p.id === tp.playerId),
            }));

          return (
            <Link
              key={team.id}
              href={`/teams/${team.id}`}
              className="p-6 rounded-3xl bg-white border border-slate-200 hover:border-cricket-300 shadow-xs hover:shadow-md transition space-y-4 flex flex-col justify-between group"
            >
              <div>
                <div className="flex items-center justify-between pb-4 border-b border-slate-100">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-12 h-12 rounded-2xl flex items-center justify-center font-black text-white text-sm shadow-md"
                      style={{ backgroundColor: team.primaryColor }}
                    >
                      {team.shortName}
                    </div>
                    <div>
                      <h3 className="font-bold text-slate-900 text-base group-hover:text-cricket-600 transition">
                        {team.name}
                      </h3>
                      <span className="text-xs text-slate-500">Owner: {team.ownerName}</span>
                    </div>
                  </div>
                  <span className="text-xs font-bold text-slate-700">{squad.length} / 18</span>
                </div>

                <div className="py-4 space-y-2">
                  <div className="flex items-baseline justify-between text-xs">
                    <span className="text-slate-500">Remaining Purse</span>
                    <span className="font-black text-emerald-600 text-sm">
                      ₹{team.remainingPurse.toLocaleString('en-IN')}
                    </span>
                  </div>

                  <div className="w-full h-2 rounded-full bg-slate-100 overflow-hidden">
                    <div
                      className="h-full bg-emerald-500 rounded-full"
                      style={{
                        width: `${Math.max(
                          5,
                          Math.round((team.remainingPurse / team.initialPurse) * 100)
                        )}%`,
                      }}
                    ></div>
                  </div>
                </div>

                {/* Key Players preview */}
                <div className="space-y-1.5 pt-2">
                  <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest block">
                    Squad Players
                  </span>
                  {squad.slice(0, 3).map((item) => (
                    <div
                      key={item.id}
                      className="flex items-center justify-between text-xs text-slate-700 py-0.5"
                    >
                      <span>{item.player?.fullName}</span>
                      <span className="text-slate-400 capitalize text-[11px]">{item.player?.role.replace(/_/g, ' ')}</span>
                    </div>
                  ))}
                  {squad.length > 3 && (
                    <span className="text-[11px] text-cricket-600 font-semibold block">
                      +{squad.length - 3} more players
                    </span>
                  )}
                </div>
              </div>

              <div className="pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-cricket-600 font-bold">
                <span>View Full Team Roster</span>
                <ArrowRight size={14} />
              </div>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
