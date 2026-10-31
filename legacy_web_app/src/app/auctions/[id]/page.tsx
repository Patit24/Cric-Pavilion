'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { store } from '@/lib/store/mock-db';
import SpinningWheel from '@/components/auction/SpinningWheel';
import PlayerRevealCard from '@/components/auction/PlayerRevealCard';
import BiddingConsole from '@/components/auction/BiddingConsole';
import SoldAnimation from '@/components/auction/SoldAnimation';
import {
  Gavel,
  Trophy,
  Shield,
  Monitor,
  Settings,
  DollarSign,
  Users,
  AlertCircle,
  Sparkles,
} from 'lucide-react';

export default function AuctionStagePage() {
  const params = useParams();
  const auctionId = (params?.id as string) || 'auc_bpl_2026';

  const [state, setState] = useState(() => store.getState());
  const [activeTab, setActiveTab] = useState<'stage' | 'control' | 'purse'>('stage');
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

  const activeBids = state.auctionBids.filter(
    (b) => b.auctionId === auction?.id && b.poolId === currentPoolItem?.id
  );

  // Active user's team if logged in as team_owner
  const currentTeam =
    state.teams.find((t) => t.ownerId === state.currentUser.id) ||
    (state.currentUser.role === 'organizer' ? state.teams[0] : null);

  const canSpin =
    state.currentUser.role === 'organizer' || state.currentUser.role === 'super_admin';

  const handleSpinRequest = () => {
    store.spinPlayerLot(auction.id);
  };

  const handleConfirmSold = () => {
    if (!currentPoolItem) return;
    const res = store.confirmSold(auction.id, currentPoolItem.id);
    if (res.success) {
      const winningTeam = state.teams.find((t) => t.id === currentPoolItem.highestBidderTeamId);
      setCelebrationLot({
        ...currentPoolItem,
        status: 'sold',
        winningTeam,
        player: state.players.find((p) => p.id === currentPoolItem.playerId),
      });
    }
  };

  const handleMarkUnsold = () => {
    if (!currentPoolItem) return;
    store.markUnsold(auction.id, currentPoolItem.id);
    setCelebrationLot({
      ...currentPoolItem,
      status: 'unsold',
      player: state.players.find((p) => p.id === currentPoolItem.playerId),
    });
  };

  return (
    <div className="min-h-screen bg-slate-950 text-white pb-16">
      {/* Top Auction Navigation Banner */}
      <div className="bg-slate-900/90 border-b border-slate-800 sticky top-16 z-30 backdrop-blur-md">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3 flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-amber-500 flex items-center justify-center text-slate-950 font-black">
              <Gavel size={18} />
            </div>
            <div>
              <h1 className="text-sm font-black tracking-tight text-white flex items-center gap-2">
                <span>{auction.title}</span>
                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-400 text-slate-950 uppercase">
                  {auction.status}
                </span>
              </h1>
              <span className="text-[11px] text-slate-400">{tournament?.name}</span>
            </div>
          </div>

          {/* Quick Screen Tabs */}
          <div className="flex items-center gap-2">
            <button
              onClick={() => setActiveTab('stage')}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 ${
                activeTab === 'stage'
                  ? 'bg-amber-500 text-slate-950'
                  : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
              }`}
            >
              <Sparkles size={13} />
              <span>Auction Stage</span>
            </button>

            <button
              onClick={() => setActiveTab('control')}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 ${
                activeTab === 'control'
                  ? 'bg-amber-500 text-slate-950'
                  : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
              }`}
            >
              <Settings size={13} />
              <span>Organizer Controls</span>
            </button>

            <button
              onClick={() => setActiveTab('purse')}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 ${
                activeTab === 'purse'
                  ? 'bg-amber-500 text-slate-950'
                  : 'bg-slate-800 text-slate-300 hover:bg-slate-700'
              }`}
            >
              <DollarSign size={13} />
              <span>Purse & Squads</span>
            </button>

            <Link
              href={`/auctions/${auction.id}/display`}
              target="_blank"
              className="px-3 py-1.5 rounded-xl text-xs font-bold bg-slate-800 text-slate-300 hover:bg-slate-700 transition flex items-center gap-1.5 border border-slate-700"
              title="Open full-screen TV / Projector Display"
            >
              <Monitor size={13} />
              <span className="hidden sm:inline">Projector Mode</span>
            </Link>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-8">
        {/* TAB 1: AUCTION STAGE & LIVE BIDDING */}
        {activeTab === 'stage' && (
          <div className="space-y-8">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
              {/* Left Column: Spinning Wheel */}
              <div className="lg:col-span-5 space-y-4">
                <SpinningWheel
                  eligibleLots={eligibleLots}
                  isSpinning={false}
                  onSpinRequest={handleSpinRequest}
                  canSpin={canSpin}
                />

                {!canSpin && (
                  <p className="text-[11px] text-slate-400 text-center italic">
                    Note: Only the Tournament Organizer can spin the wheel to pick the next player. Switch role to Organizer via top-right menu to test spinning!
                  </p>
                )}
              </div>

              {/* Right Column: Player Reveal Card + Bidding Console */}
              <div className="lg:col-span-7 space-y-6">
                <PlayerRevealCard lot={currentLotWithPlayer} />

                {currentLotWithPlayer && currentPoolItem?.status === 'active' && (
                  <BiddingConsole
                    auction={auction}
                    poolItem={currentPoolItem}
                    bids={activeBids}
                    currentTeam={currentTeam}
                    currentUser={state.currentUser}
                  />
                )}
              </div>
            </div>
          </div>
        )}

        {/* TAB 2: ORGANIZER CONTROL ROOM */}
        {activeTab === 'control' && (
          <div className="space-y-6">
            <div className="p-6 rounded-3xl bg-slate-900 border border-slate-800 space-y-4">
              <h2 className="text-xl font-black text-white flex items-center gap-2">
                <Settings size={20} className="text-amber-400" />
                <span>Organizer Live Auction Controls</span>
              </h2>
              <p className="text-xs text-slate-400">
                Authoritative actions for concluding bidding lots, confirming sales with automatic squad assignment, or marking players unsold.
              </p>

              {currentLotWithPlayer ? (
                <div className="p-5 rounded-2xl bg-slate-950 border border-slate-800 space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <span className="text-xs font-bold text-amber-400 uppercase">
                        Current Lot #{currentLotWithPlayer.lotNumber}: {currentLotWithPlayer.player?.fullName}
                      </span>
                      <div className="text-xl font-black text-white mt-0.5">
                        {currentPoolItem?.currentBid
                          ? `Highest Bid: ₹${currentPoolItem.currentBid.toLocaleString('en-IN')}`
                          : 'No bids placed yet'}
                      </div>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
                    <button
                      onClick={handleConfirmSold}
                      disabled={!currentPoolItem?.highestBidderTeamId}
                      className={`py-3.5 px-4 rounded-xl font-black text-xs uppercase tracking-wider transition ${
                        currentPoolItem?.highestBidderTeamId
                          ? 'bg-emerald-600 hover:bg-emerald-500 text-white shadow-lg shadow-emerald-600/30'
                          : 'bg-slate-800 text-slate-500 cursor-not-allowed'
                      }`}
                    >
                      Confirm Sold & Assign Squad
                    </button>

                    <button
                      onClick={handleMarkUnsold}
                      className="py-3.5 px-4 rounded-xl bg-rose-700 hover:bg-rose-600 font-black text-xs uppercase tracking-wider text-white transition shadow-lg shadow-rose-700/20"
                    >
                      Mark Player Unsold
                    </button>
                  </div>
                </div>
              ) : (
                <div className="p-6 rounded-2xl bg-slate-950 border border-slate-800 text-center">
                  <p className="text-xs text-slate-400 mb-3">No lot currently active. Spin the wheel on the Auction Stage tab to draw the next player!</p>
                  <button
                    onClick={() => {
                      setActiveTab('stage');
                      handleSpinRequest();
                    }}
                    className="py-2.5 px-5 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-black text-xs uppercase tracking-wider transition"
                  >
                    Go to Stage & Spin
                  </button>
                </div>
              )}
            </div>
          </div>
        )}

        {/* TAB 3: PURSE & SQUADS */}
        {activeTab === 'purse' && (
          <div className="space-y-6">
            <h2 className="text-xl font-black text-white flex items-center gap-2">
              <DollarSign size={20} className="text-emerald-400" />
              <span>Franchise Purse & Purchased Squads</span>
            </h2>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {state.teams.map((team) => {
                const purchasedPlayers = state.tournamentPlayers
                  .filter((tp) => tp.teamId === team.id && tp.status === 'sold')
                  .map((tp) => ({
                    ...tp,
                    player: state.players.find((pl) => pl.id === tp.playerId),
                  }));

                return (
                  <div key={team.id} className="p-6 rounded-3xl bg-slate-900 border border-slate-800 space-y-4">
                    <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                      <div className="flex items-center gap-3">
                        <div
                          className="w-9 h-9 rounded-xl flex items-center justify-center font-black text-white text-xs shadow-md"
                          style={{ backgroundColor: team.primaryColor }}
                        >
                          {team.shortName}
                        </div>
                        <div>
                          <h3 className="font-bold text-white text-sm">{team.name}</h3>
                          <span className="text-[11px] text-slate-400">{team.ownerName}</span>
                        </div>
                      </div>
                      <div className="text-right">
                        <span className="text-[10px] text-slate-400 uppercase block">Remaining Purse</span>
                        <span className="text-base font-black text-emerald-400">
                          ₹{team.remainingPurse.toLocaleString('en-IN')}
                        </span>
                      </div>
                    </div>

                    <div>
                      <span className="text-xs font-bold text-slate-400 uppercase tracking-widest block mb-2">
                        Squad Roster ({purchasedPlayers.length} / 18)
                      </span>
                      {purchasedPlayers.length === 0 ? (
                        <p className="text-xs text-slate-500 italic py-2">No players acquired yet.</p>
                      ) : (
                        <div className="space-y-2">
                          {purchasedPlayers.map((item) => (
                            <div
                              key={item.id}
                              className="p-2.5 rounded-xl bg-slate-950/70 border border-slate-800 flex items-center justify-between text-xs"
                            >
                              <div className="flex items-center gap-2.5">
                                <img
                                  src={item.player?.photoUrl}
                                  alt={item.player?.fullName}
                                  className="w-7 h-7 rounded-lg object-cover"
                                />
                                <div>
                                  <span className="font-bold text-slate-200 block">{item.player?.fullName}</span>
                                  <span className="text-[10px] text-slate-400 capitalize">{item.player?.role.replace(/_/g, ' ')}</span>
                                </div>
                              </div>
                              <span className="font-black text-emerald-400">
                                ₹{item.finalPrice?.toLocaleString('en-IN')}
                              </span>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>

      {/* SOLD / UNSOLD CELEBRATION MODAL */}
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
