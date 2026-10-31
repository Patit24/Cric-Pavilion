'use client';

import React, { useState, useEffect } from 'react';
import { Auction, AuctionBid, AuctionPlayerPoolItem, Team, UserProfile } from '@/lib/types';
import { store } from '@/lib/store/mock-db';
import { auctionSound } from '@/lib/auction-engine/sound';
import { calculateNextValidBid } from '@/lib/auction-engine/bidding';
import { DollarSign, Clock, Shield, AlertTriangle, ArrowUpRight, CheckCircle2 } from 'lucide-react';

interface BiddingConsoleProps {
  auction: Auction;
  poolItem: AuctionPlayerPoolItem;
  bids: AuctionBid[];
  currentTeam: Team | null;
  currentUser: UserProfile;
}

export default function BiddingConsole({
  auction,
  poolItem,
  bids,
  currentTeam,
  currentUser,
}: BiddingConsoleProps) {
  const [timeLeft, setTimeLeft] = useState(auction.countdownSeconds);
  const [biddingError, setBiddingError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Sync and tick server countdown
  useEffect(() => {
    setTimeLeft(auction.countdownSeconds);
    const interval = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [auction.timerStartedAt, poolItem.currentBid]);

  const nextBid = calculateNextValidBid(
    poolItem.currentBid,
    poolItem.basePrice,
    auction.minBidIncrement
  );

  const highestBidderTeam = store
    .getState()
    .teams.find((t) => t.id === poolItem.highestBidderTeamId);

  const isLeading = currentTeam && poolItem.highestBidderTeamId === currentTeam.id;

  const handlePlaceBid = (customAmount?: number) => {
    if (!currentTeam) {
      setBiddingError('You are currently not logged in as a participating Team Owner. Switch role using the top-right role switcher!');
      return;
    }

    setSubmitting(true);
    setBiddingError(null);

    const bidToPlace = customAmount || nextBid;

    const res = store.placeBid({
      auctionId: auction.id,
      teamId: currentTeam.id,
      userId: currentUser.id,
      amount: bidToPlace,
    });

    setSubmitting(false);

    if (!res.success) {
      setBiddingError(res.error || 'Bid rejected by server');
    } else {
      auctionSound.playBidChime();
    }
  };

  return (
    <div className="w-full rounded-3xl bg-slate-900 border border-slate-800 p-6 shadow-2xl backdrop-blur-xl">
      {/* Current Bid & Countdown Banner */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pb-6 border-b border-slate-800">
        {/* Highest Bid Stat */}
        <div className="p-4 rounded-2xl bg-slate-950/80 border border-slate-800/80 flex items-center justify-between">
          <div>
            <span className="text-[11px] font-bold text-slate-400 uppercase tracking-widest block">
              Current Highest Bid
            </span>
            <div className="text-3xl font-black text-amber-400 mt-0.5 tracking-tight">
              {poolItem.currentBid ? `₹${poolItem.currentBid.toLocaleString('en-IN')}` : 'No Bids Yet'}
            </div>
            {highestBidderTeam ? (
              <div className="flex items-center gap-2 mt-1">
                <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
                <span className="text-xs font-semibold text-slate-300">
                  Leading: <strong className="text-white">{highestBidderTeam.name}</strong> ({highestBidderTeam.shortName})
                </span>
              </div>
            ) : (
              <span className="text-xs text-slate-500 mt-1 block">Opening at base price</span>
            )}
          </div>
        </div>

        {/* Countdown Timer with Pulsing Alert */}
        <div className="p-4 rounded-2xl bg-slate-950/80 border border-slate-800/80 flex items-center justify-between">
          <div>
            <span className="text-[11px] font-bold text-slate-400 uppercase tracking-widest block">
              Timer Remaining
            </span>
            <div className={`text-3xl font-black mt-0.5 tracking-tight flex items-center gap-2 ${
              timeLeft <= 5 ? 'text-rose-500 animate-pulse' : 'text-emerald-400'
            }`}>
              <Clock size={26} className={timeLeft <= 5 ? 'animate-spin' : ''} />
              {timeLeft}s
            </div>
            <span className="text-xs text-slate-500 mt-1 block">
              {timeLeft === 0 ? 'Bidding pending final call' : 'Resets on valid bid'}
            </span>
          </div>

          <div className="relative w-14 h-14 flex items-center justify-center">
            <svg className="w-full h-full transform -rotate-90" viewBox="0 0 36 36">
              <path
                className="text-slate-800"
                strokeWidth="3.5"
                stroke="currentColor"
                fill="none"
                d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
              />
              <path
                className={timeLeft <= 5 ? 'text-rose-500' : 'text-emerald-500'}
                strokeDasharray={`${(timeLeft / 20) * 100}, 100`}
                strokeWidth="3.5"
                strokeLinecap="round"
                stroke="currentColor"
                fill="none"
                d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
              />
            </svg>
            <span className="absolute text-xs font-black text-white">{timeLeft}</span>
          </div>
        </div>
      </div>

      {/* Active Team Purse & Squad Bar */}
      {currentTeam ? (
        <div className="py-4 my-2 px-4 rounded-2xl bg-emerald-950/30 border border-emerald-800/40 flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <div
              className="w-9 h-9 rounded-xl flex items-center justify-center font-black text-white text-xs shadow-md"
              style={{ backgroundColor: currentTeam.primaryColor }}
            >
              {currentTeam.shortName}
            </div>
            <div>
              <span className="text-xs font-bold text-white block">{currentTeam.name}</span>
              <span className="text-[11px] text-emerald-400 font-medium">
                Remaining Purse: <strong>₹{currentTeam.remainingPurse.toLocaleString('en-IN')}</strong>
              </span>
            </div>
          </div>

          <div className="flex items-center gap-4 text-xs text-slate-300">
            <div>
              <span className="text-slate-400 text-[10px] uppercase block">Squad Count</span>
              <span className="font-bold text-white">{currentTeam.squadCount || 0} / 18 Players</span>
            </div>
            {isLeading && (
              <span className="px-2.5 py-1 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/40 text-xs font-bold flex items-center gap-1">
                <CheckCircle2 size={13} /> You hold highest bid
              </span>
            )}
          </div>
        </div>
      ) : (
        <div className="py-3 px-4 my-2 rounded-xl bg-amber-950/30 border border-amber-800/40 text-xs text-amber-300 flex items-center gap-2">
          <AlertTriangle size={15} className="shrink-0 text-amber-400" />
          <span>
            You are browsing as <strong>{currentUser.fullName} ({currentUser.role})</strong>. To place authoritative bids on behalf of a franchise, select a Team Owner identity in the top role switcher.
          </span>
        </div>
      )}

      {/* Error notification if any */}
      {biddingError && (
        <div className="my-3 p-3 rounded-xl bg-rose-950/50 border border-rose-800/60 text-xs text-rose-300 flex items-center gap-2 animate-in fade-in">
          <AlertTriangle size={15} className="shrink-0 text-rose-400" />
          <span>{biddingError}</span>
        </div>
      )}

      {/* Primary BID Controls */}
      <div className="mt-4 space-y-3">
        <button
          onClick={() => handlePlaceBid(nextBid)}
          disabled={submitting || isLeading || poolItem.status !== 'active'}
          className={`w-full py-4 px-6 rounded-2xl font-black text-base sm:text-lg uppercase tracking-wider flex items-center justify-center gap-3 shadow-xl transition transform active:scale-98 ${
            isLeading
              ? 'bg-emerald-600/50 text-white cursor-default border border-emerald-500/40'
              : poolItem.status !== 'active'
              ? 'bg-slate-800 text-slate-500 cursor-not-allowed'
              : 'bg-gradient-to-r from-emerald-500 via-emerald-600 to-teal-600 hover:from-emerald-400 hover:to-teal-500 text-white shadow-emerald-500/25 border-t border-emerald-300'
          }`}
        >
          {isLeading ? (
            <>
              <CheckCircle2 size={20} />
              <span>Highest Bidder (₹{poolItem.currentBid?.toLocaleString('en-IN')})</span>
            </>
          ) : (
            <>
              <ArrowUpRight size={22} className="stroke-[2.5]" />
              <span>BID ₹{nextBid.toLocaleString('en-IN')}</span>
            </>
          )}
        </button>

        {/* Quick Increment Buttons (+50k, +1L, +2.5L) */}
        {!isLeading && poolItem.status === 'active' && (
          <div className="grid grid-cols-3 gap-2 pt-1">
            <button
              onClick={() => handlePlaceBid(nextBid + 50000)}
              className="py-2 px-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold transition border border-slate-700"
            >
              + ₹50k Jump
            </button>
            <button
              onClick={() => handlePlaceBid(nextBid + 100000)}
              className="py-2 px-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold transition border border-slate-700"
            >
              + ₹1 Lakh Jump
            </button>
            <button
              onClick={() => handlePlaceBid(nextBid + 250000)}
              className="py-2 px-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold transition border border-slate-700"
            >
              + ₹2.5 Lakh Jump
            </button>
          </div>
        )}
      </div>

      {/* Live Bids Activity Stream */}
      <div className="mt-6 pt-4 border-t border-slate-800">
        <h4 className="text-xs font-bold uppercase tracking-widest text-slate-400 mb-3 flex items-center justify-between">
          <span>Live Bids Feed</span>
          <span className="text-[10px] font-normal text-slate-500">{bids.length} bids recorded</span>
        </h4>

        <div className="space-y-2 max-h-48 overflow-y-auto pr-1">
          {bids.length === 0 ? (
            <p className="text-xs text-slate-500 text-center py-4">Waiting for opening bid...</p>
          ) : (
            bids.map((b, idx) => (
              <div
                key={b.id || idx}
                className={`p-2.5 rounded-xl flex items-center justify-between text-xs transition ${
                  idx === 0
                    ? 'bg-emerald-950/40 border border-emerald-500/30 text-white'
                    : 'bg-slate-950/60 border border-slate-800 text-slate-400'
                }`}
              >
                <div className="flex items-center gap-2">
                  <span className="font-bold text-slate-200">{b.teamName}</span>
                  <span className="text-[10px] px-1.5 py-0.2 rounded-md bg-slate-800 text-slate-400 font-mono">
                    {b.teamShortName}
                  </span>
                </div>
                <div className="flex items-center gap-3">
                  <span className="font-black text-amber-400 text-sm">
                    ₹{b.amount.toLocaleString('en-IN')}
                  </span>
                  <span className="text-[10px] text-slate-500 font-mono">
                    {new Date(b.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
                  </span>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
