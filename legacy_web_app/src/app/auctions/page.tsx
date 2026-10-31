'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { store } from '@/lib/store/mock-db';
import { Gavel, Trophy, DollarSign, Users, ArrowRight, Shield, Monitor, Sparkles } from 'lucide-react';

export default function AuctionsPage() {
  const [state, setState] = useState(() => store.getState());

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  const auction = state.auctions[0];
  const tournament = state.tournaments[0];
  const activePoolItem = state.auctionPlayerPool.find((p) => p.id === auction?.currentPoolId);
  const activePlayer = state.players.find((p) => p.id === activePoolItem?.playerId);
  const soldCount = state.auctionPlayerPool.filter((p) => p.status === 'sold').length;
  const pendingCount = state.auctionPlayerPool.filter((p) => p.status === 'pending').length;

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-8">
      {/* Page Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-6 border-b border-slate-200">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-50 border border-amber-200 text-amber-700 text-xs font-bold uppercase tracking-wider mb-2">
            <Gavel size={14} />
            <span>Franchise Player Auctions</span>
          </div>
          <h1 className="text-3xl sm:text-4xl font-black text-slate-900 tracking-tight">
            Live Player Auctions
          </h1>
          <p className="text-sm text-slate-500 mt-1 max-w-xl">
            Real-time franchise player auctions with spinning-wheel lot selection, live bidding, automatic squad assignments, and purse management.
          </p>
        </div>

        {auction && (
          <div className="flex items-center gap-2">
            <Link
              href={`/auctions/${auction.id}/control`}
              className="px-4 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs uppercase tracking-wider transition"
            >
              Control Room
            </Link>
            <Link
              href={`/auctions/${auction.id}/display`}
              className="px-4 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs uppercase tracking-wider transition flex items-center gap-1.5"
            >
              <Monitor size={14} />
              <span>Projector Display</span>
            </Link>
          </div>
        )}
      </div>

      {/* Featured Live Auction Card */}
      {auction && (
        <div className="rounded-3xl bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 text-white border border-slate-800 shadow-2xl p-6 sm:p-8 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-96 h-96 bg-amber-500/10 rounded-full blur-3xl pointer-events-none"></div>

          <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6 relative z-10">
            <div className="space-y-4 max-w-xl">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-amber-400 animate-pulse"></span>
                <span className="text-xs font-black text-amber-400 uppercase tracking-widest">
                  STATUS: {auction.status.toUpperCase()}
                </span>
                <span className="text-slate-500">•</span>
                <span className="text-xs text-slate-400">{tournament?.name}</span>
              </div>

              <h2 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
                {auction.title}
              </h2>

              <p className="text-xs sm:text-sm text-slate-300 leading-relaxed">
                5 participating franchises competing for top cricket talent. Min bid increment: ₹{auction.minBidIncrement.toLocaleString('en-IN')}, 20-second dynamic countdown.
              </p>

              <div className="flex flex-wrap items-center gap-4 pt-2">
                <div className="px-3.5 py-2 rounded-xl bg-slate-800/80 border border-slate-700 text-xs">
                  <span className="text-slate-400 block text-[10px] uppercase font-bold">Sold Players</span>
                  <span className="text-base font-black text-emerald-400">{soldCount} Players</span>
                </div>
                <div className="px-3.5 py-2 rounded-xl bg-slate-800/80 border border-slate-700 text-xs">
                  <span className="text-slate-400 block text-[10px] uppercase font-bold">Remaining in Pool</span>
                  <span className="text-base font-black text-amber-400">{pendingCount} Lots</span>
                </div>
                <div className="px-3.5 py-2 rounded-xl bg-slate-800/80 border border-slate-700 text-xs">
                  <span className="text-slate-400 block text-[10px] uppercase font-bold">Franchise Teams</span>
                  <span className="text-base font-black text-white">5 Teams</span>
                </div>
              </div>
            </div>

            {/* Current Lot Card or Enter CTA */}
            <div className="lg:w-80 p-5 rounded-2xl bg-slate-900/90 border border-slate-700/80 space-y-4">
              {activePoolItem && activePlayer ? (
                <>
                  <span className="text-[10px] uppercase font-black text-amber-400 tracking-widest block">
                    CURRENT ACTIVE LOT #{activePoolItem.lotNumber}
                  </span>
                  <div className="flex items-center gap-3">
                    <img
                      src={activePlayer.photoUrl}
                      alt={activePlayer.fullName}
                      className="w-14 h-14 rounded-xl object-cover object-top border border-slate-600"
                    />
                    <div>
                      <h4 className="font-bold text-white text-sm">{activePlayer.fullName}</h4>
                      <span className="text-xs text-slate-400 capitalize">{activePlayer.role.replace(/_/g, ' ')}</span>
                      <div className="text-xs font-black text-amber-400 mt-1">
                        Current: {activePoolItem.currentBid ? `₹${activePoolItem.currentBid.toLocaleString('en-IN')}` : 'Base Price'}
                      </div>
                    </div>
                  </div>
                </>
              ) : (
                <div className="text-center py-4">
                  <Sparkles size={24} className="text-amber-400 mx-auto mb-2" />
                  <span className="text-xs text-slate-400 block">Ready to spin next lot</span>
                </div>
              )}

              <Link
                href={`/auctions/${auction.id}`}
                className="w-full py-3 px-4 rounded-xl bg-gradient-to-r from-amber-500 to-amber-400 hover:from-amber-400 hover:to-amber-300 text-slate-950 font-black text-xs uppercase tracking-wider transition flex items-center justify-center gap-2 shadow-lg shadow-amber-500/20"
              >
                <span>Enter Live Auction Stage</span>
                <ArrowRight size={15} />
              </Link>
            </div>
          </div>
        </div>
      )}

      {/* Team Purses Overview */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-black text-slate-900 tracking-tight flex items-center gap-2">
            <DollarSign size={18} className="text-emerald-600" />
            <span>Participating Team Purses & Squad Status</span>
          </h3>
          {auction && (
            <Link
              href={`/auctions/${auction.id}/purse`}
              className="text-xs font-bold text-cricket-600 hover:underline flex items-center gap-1"
            >
              <span>Detailed Purse Breakdown</span>
              <ArrowRight size={14} />
            </Link>
          )}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {state.teams.map((team) => {
            const spent = team.initialPurse - team.remainingPurse;
            const pctSpent = Math.round((spent / team.initialPurse) * 100);

            return (
              <div
                key={team.id}
                className="p-5 rounded-2xl bg-white border border-slate-200 shadow-xs space-y-3"
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <div
                      className="w-8 h-8 rounded-lg flex items-center justify-center font-black text-white text-xs shadow-xs"
                      style={{ backgroundColor: team.primaryColor }}
                    >
                      {team.shortName}
                    </div>
                    <div>
                      <h4 className="font-bold text-slate-900 text-sm">{team.name}</h4>
                      <span className="text-[11px] text-slate-500">{team.ownerName}</span>
                    </div>
                  </div>
                  <span className="text-xs font-bold text-slate-700">{team.squadCount || 0} / 18</span>
                </div>

                <div>
                  <div className="flex items-baseline justify-between text-xs mb-1">
                    <span className="text-slate-500">Remaining Purse</span>
                    <span className="font-black text-emerald-600 text-sm">
                      ₹{team.remainingPurse.toLocaleString('en-IN')}
                    </span>
                  </div>
                  <div className="w-full h-2 rounded-full bg-slate-100 overflow-hidden">
                    <div
                      className="h-full bg-emerald-500 rounded-full transition-all duration-300"
                      style={{ width: `${Math.max(5, 100 - pctSpent)}%` }}
                    ></div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
