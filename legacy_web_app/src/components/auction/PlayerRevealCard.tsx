'use client';

import React from 'react';
import Image from 'next/image';
import { AuctionPlayerPoolItem } from '@/lib/types';
import { Shield, Zap, Target, Award, User, Activity } from 'lucide-react';

interface PlayerRevealCardProps {
  lot: AuctionPlayerPoolItem | null;
}

export default function PlayerRevealCard({ lot }: PlayerRevealCardProps) {
  if (!lot || !lot.player) {
    return (
      <div className="w-full h-full min-h-[360px] rounded-3xl bg-slate-900/60 border border-slate-800 flex flex-col items-center justify-center p-8 text-center backdrop-blur-md">
        <div className="w-16 h-16 rounded-full bg-slate-800 flex items-center justify-center text-slate-500 mb-3 border border-slate-700">
          <User size={32} />
        </div>
        <h3 className="text-lg font-bold text-slate-300">Ready for Next Lot</h3>
        <p className="text-xs text-slate-500 max-w-xs mt-1">
          Organizer will spin the player selection wheel or open bidding on the next lot.
        </p>
      </div>
    );
  }

  const { player } = lot;

  const roleLabels: Record<string, { label: string; color: string }> = {
    batter: { label: 'Top-Order Batter', color: 'bg-blue-500/20 text-blue-400 border-blue-500/30' },
    bowler: { label: 'Strike Bowler', color: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30' },
    all_rounder: { label: 'All-Rounder', color: 'bg-amber-500/20 text-amber-400 border-amber-500/30' },
    wicket_keeper: { label: 'Wicket-Keeper Batter', color: 'bg-purple-500/20 text-purple-400 border-purple-500/30' },
  };

  const roleMeta = roleLabels[player.role] || { label: player.role, color: 'bg-slate-700 text-slate-300' };

  return (
    <div className="relative w-full rounded-3xl bg-gradient-to-b from-slate-900 via-slate-900/95 to-slate-950 border border-slate-700/80 p-6 sm:p-8 shadow-2xl backdrop-blur-xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
      {/* Background Spotlight Glow */}
      <div className="absolute top-0 right-0 w-72 h-72 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none"></div>

      {/* Lot Header & Status */}
      <div className="flex items-center justify-between border-b border-slate-800 pb-4 mb-6">
        <div className="flex items-center gap-2">
          <span className="px-3 py-1 rounded-full text-xs font-black bg-amber-400 text-slate-950 shadow-xs tracking-wider uppercase">
            LOT #{lot.lotNumber}
          </span>
          <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold border ${roleMeta.color}`}>
            {roleMeta.label}
          </span>
        </div>
        <div className="text-right">
          <span className="text-[10px] text-slate-400 uppercase tracking-widest block">Base Price</span>
          <span className="text-sm font-extrabold text-emerald-400">
            ₹{lot.basePrice.toLocaleString('en-IN')}
          </span>
        </div>
      </div>

      {/* Main Player Profile Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-12 gap-6 items-center">
        {/* Player Image with Spotlight Frame */}
        <div className="sm:col-span-5 flex justify-center">
          <div className="relative group">
            <div className="absolute -inset-1 rounded-2xl bg-gradient-to-r from-emerald-500 to-amber-500 opacity-60 blur-sm group-hover:opacity-100 transition duration-300"></div>
            <div className="relative w-36 h-36 sm:w-44 sm:h-44 rounded-2xl overflow-hidden border-2 border-slate-600 bg-slate-800 shadow-xl">
              <img
                src={player.photoUrl}
                alt={player.fullName}
                className="w-full h-full object-cover object-top"
              />
            </div>
          </div>
        </div>

        {/* Player Details & Career Stats */}
        <div className="sm:col-span-7 space-y-4">
          <div>
            <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
              {player.fullName}
            </h2>
            <div className="flex flex-wrap items-center gap-x-4 gap-y-1 mt-1 text-xs text-slate-400 font-medium">
              <span>Batting: <strong className="text-slate-200 capitalize">{player.battingStyle.replace(/_/g, ' ')}</strong></span>
              <span>•</span>
              <span>Bowling: <strong className="text-slate-200 capitalize">{player.bowlingStyle.replace(/_/g, ' ')}</strong></span>
              {player.city && (
                <>
                  <span>•</span>
                  <span>Origin: <strong className="text-slate-200">{player.city}</strong></span>
                </>
              )}
            </div>
          </div>

          {/* Official Verified Stats Grid */}
          <div className="grid grid-cols-3 gap-2.5 pt-2">
            <div className="p-2.5 rounded-xl bg-slate-800/80 border border-slate-700/60 text-center">
              <span className="text-[10px] uppercase font-bold text-slate-400 block tracking-wider">Matches</span>
              <span className="text-lg font-black text-white">{player.matches}</span>
            </div>
            <div className="p-2.5 rounded-xl bg-slate-800/80 border border-slate-700/60 text-center">
              <span className="text-[10px] uppercase font-bold text-slate-400 block tracking-wider">Runs</span>
              <span className="text-lg font-black text-emerald-400">{player.runs}</span>
              <span className="text-[10px] text-slate-500 block">Avg: {player.battingAverage}</span>
            </div>
            <div className="p-2.5 rounded-xl bg-slate-800/80 border border-slate-700/60 text-center">
              <span className="text-[10px] uppercase font-bold text-slate-400 block tracking-wider">Wickets</span>
              <span className="text-lg font-black text-amber-400">{player.wickets}</span>
              <span className="text-[10px] text-slate-500 block">Econ: {player.economy}</span>
            </div>
          </div>

          <div className="flex items-center gap-2 text-[11px] text-slate-400 bg-slate-900/90 px-3 py-1.5 rounded-lg border border-slate-800">
            <Activity size={13} className="text-emerald-400" />
            <span>Strike Rate: <strong className="text-emerald-400">{player.strikeRate}</strong></span>
            <span className="mx-1">•</span>
            <span>Best Figures: <strong className="text-amber-400">{player.bestBowling || 'N/A'}</strong></span>
          </div>
        </div>
      </div>
    </div>
  );
}
