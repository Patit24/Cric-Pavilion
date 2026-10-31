'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { store } from '@/lib/store/mock-db';
import {
  Trophy,
  Gavel,
  Radio,
  Plus,
  Settings,
  Users,
  ArrowRight,
  Shield,
  Calendar,
  MapPin,
  Coins,
  Play,
  RotateCcw,
  UserPlus,
} from 'lucide-react';

export default function OrganizerDashboardPage() {
  const [state, setState] = useState(() => store.getState());
  const [showScheduleModal, setShowScheduleModal] = useState(false);
  const [showAddPlayerModal, setShowAddPlayerModal] = useState(false);

  // Form states
  const [teamAId, setTeamAId] = useState(state.teams[0]?.id || '');
  const [teamBId, setTeamBId] = useState(state.teams[1]?.id || '');
  const [overs, setOvers] = useState(20);
  const [venue, setVenue] = useState('Eden Gardens, Kolkata');

  const [addPlayerTeamId, setAddPlayerTeamId] = useState(state.teams[0]?.id || '');
  const [addPlayerName, setAddPlayerName] = useState('');
  const [addPlayerRole, setAddPlayerRole] = useState<'batter' | 'bowler' | 'all_rounder' | 'wicket_keeper'>('batter');

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  const tournament = state.tournaments[0];
  const auction = state.auctions[0];

  const handleCreateFixture = (e: React.FormEvent) => {
    e.preventDefault();
    if (teamAId === teamBId) {
      alert('Please select two distinct teams.');
      return;
    }

    store.createMatch({
      tournamentId: tournament?.id || 'tourn_bpl_2026',
      teamAId,
      teamBId,
      venue,
      dateTime: new Date().toISOString(),
      overs,
      stage: `League Match ${state.matches.length + 1}`,
    });

    setShowScheduleModal(false);
  };

  const handleAddPlayer = (e: React.FormEvent) => {
    e.preventDefault();
    if (!addPlayerName.trim()) return;

    store.addPlayerToTeam({
      teamId: addPlayerTeamId,
      tournamentId: tournament?.id || 'tourn_bpl_2026',
      fullName: addPlayerName.trim(),
      role: addPlayerRole,
      battingStyle: 'right_hand_bat',
      bowlingStyle: addPlayerRole === 'bowler' ? 'right_arm_fast' : 'none',
    });

    setAddPlayerName('');
    setShowAddPlayerModal(false);
  };

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
            Complete tournament lifecycle: Register Teams → Manage Squads → Generate Fixtures → Conduct Toss → Live Scoring.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowScheduleModal(true)}
            className="px-4 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs uppercase tracking-wider transition flex items-center gap-1.5 shadow-sm"
          >
            <Calendar size={14} />
            <span>+ Schedule Fixture</span>
          </button>

          <Link
            href="/organizer/tournaments/new"
            className="px-4 py-2.5 rounded-xl bg-cricket-600 hover:bg-cricket-500 text-white font-bold text-xs uppercase tracking-wider shadow-md shadow-cricket-600/20 transition flex items-center gap-1.5"
          >
            <Plus size={16} />
            <span>New Tournament</span>
          </Link>
        </div>
      </div>

      {/* Tournament Lifecycle Banner */}
      <div className="p-6 rounded-3xl bg-gradient-to-r from-cricket-900 via-slate-900 to-slate-950 text-white shadow-xl border border-cricket-800 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <span className="text-[11px] font-bold text-cricket-400 uppercase tracking-widest block mb-1">
            Active Competition
          </span>
          <h2 className="text-2xl font-black text-white">{tournament?.name}</h2>
          <p className="text-xs text-slate-300 mt-1">
            {tournament?.format.toUpperCase()} • Max {tournament?.oversPerInnings} Overs/Match • {state.teams.length} Teams • {state.players.length} Players in Pool
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowAddPlayerModal(true)}
            className="py-2.5 px-4 rounded-xl bg-white/10 hover:bg-white/20 text-white text-xs font-bold transition flex items-center gap-1.5 border border-white/20"
          >
            <UserPlus size={14} />
            <span>Add Player</span>
          </button>
          <Link
            href="/auctions/auc_bpl_2026/control"
            className="py-2.5 px-4 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-black text-xs uppercase tracking-wider transition flex items-center gap-1.5 shadow-md shadow-amber-500/20"
          >
            <Gavel size={14} />
            <span>Auction Wheel</span>
          </Link>
        </div>
      </div>

      {/* Quick Action Bento Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Auction Card */}
        <div className="p-6 rounded-3xl bg-slate-950 text-white border border-slate-800 shadow-xl flex flex-col justify-between space-y-4">
          <div>
            <div className="w-10 h-10 rounded-xl bg-amber-500 flex items-center justify-center text-slate-950 mb-3 font-bold">
              <Gavel size={20} />
            </div>
            <h3 className="text-lg font-bold text-white">Player Auction Stage</h3>
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
            <h3 className="text-lg font-bold text-slate-900">Scorer &amp; Toss Room</h3>
            <p className="text-xs text-slate-500 mt-1">
              Conduct official coin toss, assign playing XIs, and record match deliveries ball by ball.
            </p>
          </div>
          <Link
            href="/scorer"
            className="py-2.5 px-4 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold text-xs uppercase tracking-wider transition flex items-center justify-center gap-2"
          >
            <span>Launch Scorer Console</span>
            <ArrowRight size={14} />
          </Link>
        </div>

        {/* Teams & Squads Card */}
        <div className="p-6 rounded-3xl bg-white border border-slate-200 shadow-xs flex flex-col justify-between space-y-4">
          <div>
            <div className="w-10 h-10 rounded-xl bg-emerald-100 text-cricket-600 flex items-center justify-center mb-3 font-bold">
              <Users size={20} />
            </div>
            <h3 className="text-lg font-bold text-slate-900">Franchise Teams &amp; Squads</h3>
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

      {/* Fixtures & Matches Management Section */}
      <div className="bg-white rounded-3xl p-6 border border-slate-200 shadow-xs space-y-5">
        <div className="flex items-center justify-between pb-4 border-b border-slate-100">
          <div>
            <h2 className="text-lg font-black text-slate-900">Tournament Fixtures &amp; Match Schedule</h2>
            <p className="text-xs text-slate-500">
              Schedule matches, conduct pre-match toss, and assign scorers for each fixture.
            </p>
          </div>
          <button
            onClick={() => setShowScheduleModal(true)}
            className="py-2 px-3 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition flex items-center gap-1.5"
          >
            <Calendar size={13} />
            <span>+ Add Match</span>
          </button>
        </div>

        <div className="divide-y divide-slate-100">
          {state.matches.map((m) => {
            const teamA = state.teams.find((t) => t.id === m.teamAId);
            const teamB = state.teams.find((t) => t.id === m.teamBId);
            const inn1 = state.innings.find((i) => i.matchId === m.id && i.inningsNumber === 1);
            const inn2 = state.innings.find((i) => i.matchId === m.id && i.inningsNumber === 2);

            return (
              <div key={m.id} className="py-4 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-slate-700 text-xs shrink-0">
                    #{m.matchNumber}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-black text-sm text-slate-900">{teamA?.name} vs {teamB?.name}</span>
                      <span
                        className={`text-[10px] font-black uppercase px-2 py-0.5 rounded-full ${
                          m.status === 'live'
                            ? 'bg-rose-500 text-white animate-pulse'
                            : m.status === 'completed'
                            ? 'bg-emerald-100 text-emerald-800'
                            : 'bg-slate-100 text-slate-600'
                        }`}
                      >
                        {m.status}
                      </span>
                    </div>
                    <div className="flex items-center gap-2 text-xs text-slate-400 mt-0.5">
                      <span>{m.stage}</span>
                      <span>•</span>
                      <span>{m.overs} Overs</span>
                      <span>•</span>
                      <span className="flex items-center gap-1"><MapPin size={11} /> {m.venue}</span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-2 self-end sm:self-auto">
                  {m.status === 'scheduled' || m.status === 'toss' ? (
                    <Link
                      href="/scorer"
                      className="py-2 px-3.5 rounded-xl bg-cricket-600 hover:bg-cricket-500 text-white text-xs font-bold transition flex items-center gap-1.5 shadow-xs"
                    >
                      <Coins size={13} />
                      <span>Conduct Toss &amp; Score →</span>
                    </Link>
                  ) : m.status === 'live' ? (
                    <Link
                      href="/scorer"
                      className="py-2 px-3.5 rounded-xl bg-rose-600 hover:bg-rose-500 text-white text-xs font-bold transition flex items-center gap-1.5 shadow-xs"
                    >
                      <Play size={13} />
                      <span>Score Live ({inn1?.oversStr} ov) →</span>
                    </Link>
                  ) : (
                    <Link
                      href={`/matches/${m.id}`}
                      className="py-2 px-3.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition"
                    >
                      Scorecard
                    </Link>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Schedule Fixture Modal */}
      {showScheduleModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm animate-in fade-in">
          <form
            onSubmit={handleCreateFixture}
            className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 space-y-4"
          >
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-base font-black text-slate-900">Schedule Tournament Fixture</h3>
              <button
                type="button"
                onClick={() => setShowScheduleModal(false)}
                className="text-slate-400 hover:text-slate-600 text-xs font-bold"
              >
                ✕
              </button>
            </div>

            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Team A</label>
              <select
                value={teamAId}
                onChange={(e) => setTeamAId(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-300 text-xs font-semibold bg-white"
              >
                {state.teams.map((t) => (
                  <option key={t.id} value={t.id}>{t.name}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Team B</label>
              <select
                value={teamBId}
                onChange={(e) => setTeamBId(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-300 text-xs font-semibold bg-white"
              >
                {state.teams.map((t) => (
                  <option key={t.id} value={t.id} disabled={t.id === teamAId}>
                    {t.name} {t.id === teamAId ? '(Already Team A)' : ''}
                  </option>
                ))}
              </select>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">Overs</label>
                <input
                  type="number"
                  min="2"
                  max="50"
                  value={overs}
                  onChange={(e) => setOvers(Number(e.target.value))}
                  className="w-full p-2.5 rounded-xl border border-slate-300 text-xs font-bold"
                />
              </div>

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">Venue</label>
                <input
                  type="text"
                  value={venue}
                  onChange={(e) => setVenue(e.target.value)}
                  className="w-full p-2.5 rounded-xl border border-slate-300 text-xs font-semibold"
                />
              </div>
            </div>

            <div className="flex gap-2 pt-2">
              <button
                type="button"
                onClick={() => setShowScheduleModal(false)}
                className="flex-1 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="flex-1 py-2.5 rounded-xl bg-cricket-600 hover:bg-cricket-500 text-white text-xs font-bold shadow-md shadow-cricket-600/20"
              >
                Create Fixture
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Add Player to Squad Modal */}
      {showAddPlayerModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm animate-in fade-in">
          <form
            onSubmit={handleAddPlayer}
            className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 space-y-4"
          >
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <h3 className="text-base font-black text-slate-900">Add Player to Team Squad</h3>
              <button
                type="button"
                onClick={() => setShowAddPlayerModal(false)}
                className="text-slate-400 hover:text-slate-600 text-xs font-bold"
              >
                ✕
              </button>
            </div>

            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Team</label>
              <select
                value={addPlayerTeamId}
                onChange={(e) => setAddPlayerTeamId(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-300 text-xs font-semibold bg-white"
              >
                {state.teams.map((t) => (
                  <option key={t.id} value={t.id}>{t.name}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Player Full Name</label>
              <input
                type="text"
                required
                placeholder="e.g. Sourav Ganguly"
                value={addPlayerName}
                onChange={(e) => setAddPlayerName(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-300 text-xs font-semibold"
              />
            </div>

            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Role</label>
              <select
                value={addPlayerRole}
                onChange={(e) => setAddPlayerRole(e.target.value as any)}
                className="w-full p-2.5 rounded-xl border border-slate-300 text-xs font-semibold bg-white"
              >
                <option value="batter">Batter</option>
                <option value="bowler">Bowler</option>
                <option value="all_rounder">All Rounder</option>
                <option value="wicket_keeper">Wicketkeeper</option>
              </select>
            </div>

            <div className="flex gap-2 pt-2">
              <button
                type="button"
                onClick={() => setShowAddPlayerModal(false)}
                className="flex-1 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="flex-1 py-2.5 rounded-xl bg-cricket-600 hover:bg-cricket-500 text-white text-xs font-bold"
              >
                Add to Squad
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
