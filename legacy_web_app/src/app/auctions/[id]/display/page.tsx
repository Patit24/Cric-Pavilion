'use client';

import React, { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { store } from '@/lib/store/mock-db';
import SpinningWheel from '@/components/auction/SpinningWheel';
import PlayerRevealCard from '@/components/auction/PlayerRevealCard';
import SoldAnimation from '@/components/auction/SoldAnimation';
import { Gavel, Trophy, Clock, Maximize2 } from 'lucide-react';

export default function AuctionDisplayModePage() {
  const params = useParams();
  const auctionId = (params?.id as string) || 'auc_bpl_2026';

  const [state, setState] = useState(() => store.getState());
  const [celebrationLot, setCelebrationLot] = useState<any | null>(null);

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  const auction = state.auctions.find((a) => a.id === auctionId) || state.auctions[0];
  const tournament = state.tournaments.find((t) => t.id === auction?.tournamentId);
  const currentPoolItem = state.auctionPlayerPool.find((p) => p.id === auction?.currentPoolId);
  const currentLotWithPlayer = currentPoolItem
    ? {
        ...currentPoolItem,
        player: state.players.find((p) => p.id === currentPoolItem.playerId),
      }
    : null;

  const eligibleLots = state.auctionPlayerPool
    .filter((p) => p.auctionId === auction?.id && (p.status === 'pending' || p.status === 'passed'))
    .map((p) => ({
      ...p,
      player: state.players.find((pl) => pl.id === p.playerId),
    }));

  const highestBidderTeam = store
    .getState()
    .teams.find((t) => t.id === currentPoolItem?.highestBidderTeamId);

  const toggleFullScreen = () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
    } else {
      document.exitFullscreen().catch(() => {});
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-white p-6 sm:p-10 flex flex-col justify-between overflow-hidden relative">
      {/* Background Stadium Glows */}
      <div className="absolute top-0 left-1/4 w-[600px] h-[600px] bg-emerald-500/10 rounded-full blur-[140px] pointer-events-none"></div>
      <div className="absolute bottom-0 right-1/4 w-[600px] h-[600px] bg-amber-500/10 rounded-full blur-[140px] pointer-events-none"></div>

      {/* Broadcast Header */}
      <div className="flex items-center justify-between pb-6 border-b border-slate-800/80 relative z-10">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-amber-500 to-amber-300 flex items-center justify-center text-slate-950 font-black shadow-lg shadow-amber-500/20">
            <Gavel size={26} />
          </div>
          <div>
            <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-white uppercase">
              {auction.title}
            </h1>
            <span className="text-xs text-amber-400 font-bold uppercase tracking-widest">
              Official Auction Stage • {tournament?.name}
            </span>
          </div>
        </div>

        <button
          onClick={toggleFullScreen}
          className="p-3 rounded-xl bg-slate-900 hover:bg-slate-800 text-slate-300 hover:text-white transition border border-slate-700 flex items-center gap-2 text-xs font-bold"
        >
          <Maximize2 size={16} />
          <span className="hidden sm:inline">Full-Screen Mode</span>
        </button>
      </div>

      {/* Main Stage Grid: Wheel & Player Card */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center my-auto py-8 relative z-10">
        {/* Left Side: Large Wheel */}
        <div className="lg:col-span-5 flex flex-col items-center">
          <SpinningWheel
            eligibleLots={eligibleLots}
            isSpinning={false}
            canSpin={false}
          />
        </div>

        {/* Right Side: Large Player Card + Giant Current Bid */}
        <div className="lg:col-span-7 space-y-6">
          <PlayerRevealCard lot={currentLotWithPlayer} />

          {currentPoolItem && (
            <div className="p-6 rounded-3xl bg-slate-900/90 border border-slate-800 shadow-2xl flex flex-col sm:flex-row items-center justify-between gap-4">
              <div>
                <span className="text-xs font-bold text-slate-400 uppercase tracking-widest block">
                  Current Highest Bid
                </span>
                <div className="text-4xl sm:text-5xl font-black text-amber-400 mt-1">
                  {currentPoolItem.currentBid ? `₹${currentPoolItem.currentBid.toLocaleString('en-IN')}` : 'No Bids Placed'}
                </div>
              </div>

              {highestBidderTeam && (
                <div className="flex items-center gap-3 p-3 rounded-2xl bg-slate-950 border border-slate-800">
                  <div
                    className="w-12 h-12 rounded-xl flex items-center justify-center font-black text-white text-sm shadow-md"
                    style={{ backgroundColor: highestBidderTeam.primaryColor }}
                  >
                    {highestBidderTeam.shortName}
                  </div>
                  <div>
                    <span className="text-[10px] text-slate-400 uppercase tracking-wider block">Leading Franchise</span>
                    <span className="text-base font-bold text-white">{highestBidderTeam.name}</span>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Bottom Franchise Purse Marquee */}
      <div className="pt-6 border-t border-slate-800/80 relative z-10">
        <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
          {state.teams.map((t) => (
            <div
              key={t.id}
              className="p-3 rounded-xl bg-slate-900/60 border border-slate-800/80 flex items-center gap-2.5"
            >
              <div
                className="w-7 h-7 rounded-lg flex items-center justify-center font-black text-white text-[10px] shrink-0"
                style={{ backgroundColor: t.primaryColor }}
              >
                {t.shortName}
              </div>
              <div className="min-w-0">
                <span className="text-xs font-bold text-slate-200 block truncate">{t.shortName}</span>
                <span className="text-[11px] font-black text-emerald-400">
                  ₹{(t.remainingPurse / 100000).toFixed(1)}L
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Celebration Modal if Sold */}
      {celebrationLot && (
        <SoldAnimation
          lot={celebrationLot}
          winningTeam={celebrationLot.winningTeam}
          onDismiss={() => setCelebrationLot(null)}
        />
      )}
    </div>
  );
}
