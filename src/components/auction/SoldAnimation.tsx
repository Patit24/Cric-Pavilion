'use client';

import React, { useEffect } from 'react';
import confetti from 'canvas-confetti';
import { AuctionPlayerPoolItem, Team } from '@/lib/types';
import { auctionSound } from '@/lib/auction-engine/sound';
import { Award, CheckCircle, XCircle } from 'lucide-react';

interface SoldAnimationProps {
  lot: AuctionPlayerPoolItem;
  winningTeam?: Team | null;
  onDismiss: () => void;
}

export default function SoldAnimation({ lot, winningTeam, onDismiss }: SoldAnimationProps) {
  const isSold = lot.status === 'sold';

  useEffect(() => {
    if (isSold) {
      auctionSound.playSoldFanfare();

      // Trigger high-end celebration confetti burst
      try {
        confetti({
          particleCount: 80,
          spread: 70,
          origin: { y: 0.6 },
          colors: ['#10b981', '#f59e0b', '#6366f1', '#ffffff'],
        });
      } catch {}
    } else {
      auctionSound.playUnsoldSound();
    }
  }, [isSold]);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/85 backdrop-blur-xl animate-in fade-in duration-200">
      <div className="relative w-full max-w-lg rounded-3xl bg-gradient-to-b from-slate-900 via-slate-900 to-slate-950 border border-slate-700/80 p-8 shadow-2xl text-center overflow-hidden">
        {/* Glow behind modal */}
        <div className={`absolute -top-20 left-1/2 -translate-x-1/2 w-64 h-64 rounded-full blur-3xl pointer-events-none opacity-40 ${
          isSold ? 'bg-amber-500' : 'bg-rose-500'
        }`}></div>

        {/* SOLD / UNSOLD Stamp Banner */}
        <div className="my-2 flex justify-center">
          <div
            className={`px-8 py-2 rounded-2xl text-3xl sm:text-4xl font-black uppercase tracking-widest shadow-2xl transform -rotate-2 border-2 ${
              isSold
                ? 'bg-gradient-to-r from-amber-500 to-amber-300 text-slate-950 border-amber-200 shadow-amber-500/50'
                : 'bg-rose-600 text-white border-rose-400 shadow-rose-600/50'
            }`}
          >
            {isSold ? 'HAMMER DOWN: SOLD!' : 'UNSOLD'}
          </div>
        </div>

        {/* Player Photo */}
        <div className="my-6 flex justify-center">
          <div className="relative w-28 h-28 sm:w-32 sm:h-32 rounded-2xl overflow-hidden border-2 border-slate-600 shadow-xl bg-slate-800">
            {lot.player?.photoUrl && (
              <img
                src={lot.player.photoUrl}
                alt={lot.player?.fullName || 'Player'}
                className="w-full h-full object-cover object-top"
              />
            )}
          </div>
        </div>

        <h3 className="text-2xl font-black text-white">{lot.player?.fullName}</h3>
        <p className="text-xs text-slate-400 capitalize mt-0.5">
          {lot.player?.role.replace(/_/g, ' ')} • Base: ₹{lot.basePrice.toLocaleString('en-IN')}
        </p>

        {isSold && winningTeam && (
          <div className="mt-6 p-4 rounded-2xl bg-slate-800/80 border border-slate-700 space-y-2">
            <span className="text-[11px] font-bold text-slate-400 uppercase tracking-widest block">
              Sold To
            </span>
            <div className="flex items-center justify-center gap-3">
              <div
                className="w-8 h-8 rounded-lg flex items-center justify-center font-black text-white text-xs shadow-md"
                style={{ backgroundColor: winningTeam.primaryColor }}
              >
                {winningTeam.shortName}
              </div>
              <span className="text-lg font-bold text-white">{winningTeam.name}</span>
            </div>

            <div className="pt-2 border-t border-slate-700/60">
              <span className="text-[10px] text-slate-400 uppercase block">Final Purchase Price</span>
              <span className="text-2xl font-black text-emerald-400">
                ₹{lot.soldPrice?.toLocaleString('en-IN')}
              </span>
            </div>
          </div>
        )}

        <div className="mt-6">
          <button
            onClick={onDismiss}
            className="w-full py-3 px-6 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-bold text-sm transition border border-slate-600"
          >
            Continue to Next Lot
          </button>
        </div>
      </div>
    </div>
  );
}
