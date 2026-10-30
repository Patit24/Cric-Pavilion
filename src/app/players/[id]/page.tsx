'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { store } from '@/lib/store/mock-db';
import { ArrowLeft, Award, Activity, Shield, Trophy, CheckCircle2 } from 'lucide-react';

export default function PlayerProfilePage() {
  const params = useParams();
  const playerId = (params?.id as string) || 'pl_1';

  const [state, setState] = useState(() => store.getState());

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  const player = state.players.find((p) => p.id === playerId) || state.players[0];
  const tp = state.tournamentPlayers.find((t) => t.playerId === player.id);
  const team = tp?.teamId ? state.teams.find((t) => t.id === tp.teamId) : null;

  return (
    <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-8">
      {/* Back button */}
      <div>
        <Link
          href="/players"
          className="inline-flex items-center gap-1.5 text-xs font-bold text-slate-500 hover:text-slate-800 transition"
        >
          <ArrowLeft size={14} />
          <span>Back to Players Directory</span>
        </Link>
      </div>

      {/* Main Profile Header Card */}
      <div className="rounded-3xl bg-gradient-to-br from-slate-950 via-slate-900 to-cricket-950 text-white p-6 sm:p-8 shadow-xl border border-slate-800">
        <div className="flex flex-col sm:flex-row items-center sm:items-start gap-6">
          <div className="w-32 h-32 sm:w-40 sm:h-40 rounded-2xl overflow-hidden border-2 border-slate-600 bg-slate-800 shrink-0 shadow-lg">
            <img
              src={player.photoUrl}
              alt={player.fullName}
              className="w-full h-full object-cover object-top"
            />
          </div>

          <div className="space-y-3 text-center sm:text-left flex-1">
            <div className="flex flex-wrap items-center justify-center sm:justify-start gap-2">
              <span className="px-3 py-1 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 text-xs font-bold uppercase tracking-wider">
                {player.role.replace(/_/g, ' ')}
              </span>
              {team && (
                <span className="px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider text-white" style={{ backgroundColor: team.primaryColor }}>
                  {team.name}
                </span>
              )}
            </div>

            <h1 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
              {player.fullName}
            </h1>

            <div className="text-xs text-slate-300 font-medium space-x-3">
              <span>Batting: <strong className="text-white capitalize">{player.battingStyle.replace(/_/g, ' ')}</strong></span>
              <span>•</span>
              <span>Bowling: <strong className="text-white capitalize">{player.bowlingStyle.replace(/_/g, ' ')}</strong></span>
              {player.city && (
                <>
                  <span>•</span>
                  <span>Origin: <strong className="text-white">{player.city}</strong></span>
                </>
              )}
            </div>

            {tp && (
              <div className="p-3 rounded-xl bg-slate-900/80 border border-slate-800 text-xs flex flex-wrap items-center justify-between gap-3 mt-4">
                <div>
                  <span className="text-slate-400 text-[10px] uppercase block font-bold">Base Price</span>
                  <span className="text-sm font-black text-white">₹{tp.basePrice.toLocaleString('en-IN')}</span>
                </div>
                {tp.finalPrice && (
                  <div>
                    <span className="text-slate-400 text-[10px] uppercase block font-bold">Auction Purchase Price</span>
                    <span className="text-sm font-black text-emerald-400">₹{tp.finalPrice.toLocaleString('en-IN')}</span>
                  </div>
                )}
                <div>
                  <span className="text-slate-400 text-[10px] uppercase block font-bold">Status</span>
                  <span className="text-xs font-black uppercase text-amber-400">{tp.status}</span>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Official Verified Statistics */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Batting Statistics */}
        <div className="p-6 rounded-3xl bg-white border border-slate-200 shadow-xs space-y-4">
          <h3 className="text-base font-bold text-slate-900 border-b border-slate-100 pb-3 flex items-center justify-between">
            <span>Career Batting Statistics</span>
            <span className="text-xs text-emerald-600 font-normal">Verified Match Records</span>
          </h3>

          <div className="grid grid-cols-3 gap-3 text-center text-xs">
            <div className="p-3 rounded-xl bg-slate-50"><span className="text-slate-400 block text-[10px] uppercase font-bold">Matches</span><span className="text-lg font-black text-slate-900">{player.matches}</span></div>
            <div className="p-3 rounded-xl bg-slate-50"><span className="text-slate-400 block text-[10px] uppercase font-bold">Runs</span><span className="text-lg font-black text-emerald-600">{player.runs}</span></div>
            <div className="p-3 rounded-xl bg-slate-50"><span className="text-slate-400 block text-[10px] uppercase font-bold">Highest Score</span><span className="text-lg font-black text-slate-900">{player.highestScore}</span></div>
            <div className="p-3 rounded-xl bg-slate-50"><span className="text-slate-400 block text-[10px] uppercase font-bold">Average</span><span className="text-lg font-black text-slate-900">{player.battingAverage}</span></div>
            <div className="p-3 rounded-xl bg-slate-50"><span className="text-slate-400 block text-[10px] uppercase font-bold">Strike Rate</span><span className="text-lg font-black text-emerald-600">{player.strikeRate}</span></div>
            <div className="p-3 rounded-xl bg-slate-50"><span className="text-slate-400 block text-[10px] uppercase font-bold">50s / 100s</span><span className="text-lg font-black text-slate-900">8 / 1</span></div>
          </div>
        </div>

        {/* Bowling Statistics */}
        <div className="p-6 rounded-3xl bg-white border border-slate-200 shadow-xs space-y-4">
          <h3 className="text-base font-bold text-slate-900 border-b border-slate-100 pb-3 flex items-center justify-between">
            <span>Career Bowling Statistics</span>
            <span className="text-xs text-emerald-600 font-normal">Verified Match Records</span>
          </h3>

          <div className="grid grid-cols-3 gap-3 text-center text-xs">
            <div className="p-3 rounded-xl bg-slate-50"><span className="text-slate-400 block text-[10px] uppercase font-bold">Wickets</span><span className="text-lg font-black text-amber-500">{player.wickets}</span></div>
            <div className="p-3 rounded-xl bg-slate-50"><span className="text-slate-400 block text-[10px] uppercase font-bold">Economy</span><span className="text-lg font-black text-slate-900">{player.economy}</span></div>
            <div className="p-3 rounded-xl bg-slate-50"><span className="text-slate-400 block text-[10px] uppercase font-bold">Best Bowling</span><span className="text-lg font-black text-slate-900">{player.bestBowling || '0/0'}</span></div>
            <div className="p-3 rounded-xl bg-slate-50"><span className="text-slate-400 block text-[10px] uppercase font-bold">Catches</span><span className="text-lg font-black text-slate-900">18</span></div>
            <div className="p-3 rounded-xl bg-slate-50"><span className="text-slate-400 block text-[10px] uppercase font-bold">Run Outs</span><span className="text-lg font-black text-slate-900">4</span></div>
            <div className="p-3 rounded-xl bg-slate-50"><span className="text-slate-400 block text-[10px] uppercase font-bold">Dot %</span><span className="text-lg font-black text-slate-900">48.2%</span></div>
          </div>
        </div>
      </div>
    </div>
  );
}
