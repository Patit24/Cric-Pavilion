'use client';

import React, { useState } from 'react';
import { Match, Team, Player, TossDecision } from '@/lib/types';
import { store } from '@/lib/store/mock-db';
import {
  Trophy,
  Shield,
  Coins,
  ArrowRight,
  UserPlus,
  CheckCircle2,
  Calendar,
  MapPin,
  Clock,
  Sparkles,
} from 'lucide-react';

interface TossWizardProps {
  match: Match;
  teamA: Team;
  teamB: Team;
  teamAPlayers: Player[];
  teamBPlayers: Player[];
  onMatchStarted: () => void;
}

export default function TossWizard({
  match,
  teamA,
  teamB,
  teamAPlayers,
  teamBPlayers,
  onMatchStarted,
}: TossWizardProps) {
  const [currentStep, setCurrentStep] = useState<1 | 2 | 3>(1);

  // Quick player add state
  const [showAddPlayerModal, setShowAddPlayerModal] = useState(false);
  const [newPlayerTeamId, setNewPlayerTeamId] = useState<string>(teamA.id);
  const [newPlayerName, setNewPlayerName] = useState<string>('');
  const [newPlayerRole, setNewPlayerRole] = useState<Player['role']>('batter');

  // Toss state
  const [tossWinnerId, setTossWinnerId] = useState<string>(teamA.id);
  const [tossDecision, setTossDecision] = useState<TossDecision>('bat');

  // Opening crease state
  const tossLoserId = tossWinnerId === teamA.id ? teamB.id : teamA.id;
  const battingFirstTeamId = tossDecision === 'bat' ? tossWinnerId : tossLoserId;
  const bowlingFirstTeamId = battingFirstTeamId === teamA.id ? teamB.id : teamA.id;

  const battingRoster = battingFirstTeamId === teamA.id ? teamAPlayers : teamBPlayers;
  const bowlingRoster = bowlingFirstTeamId === teamA.id ? teamAPlayers : teamBPlayers;

  const [strikerId, setStrikerId] = useState<string>(battingRoster[0]?.id || '');
  const [nonStrikerId, setNonStrikerId] = useState<string>(battingRoster[1]?.id || '');
  const [openingBowlerId, setOpeningBowlerId] = useState<string>(
    bowlingRoster[bowlingRoster.length - 1]?.id || ''
  );

  const handleAddPlayer = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPlayerName.trim()) return;

    store.addPlayerToTeam({
      teamId: newPlayerTeamId,
      tournamentId: match.tournamentId,
      fullName: newPlayerName.trim(),
      role: newPlayerRole,
      battingStyle: 'right_hand_bat',
      bowlingStyle: newPlayerRole === 'bowler' ? 'right_arm_fast' : 'none',
    });

    setNewPlayerName('');
    setShowAddPlayerModal(false);
  };

  const handleStartMatch = () => {
    if (!strikerId || !nonStrikerId || !openingBowlerId) {
      alert('Please select Striker, Non-Striker, and Opening Bowler.');
      return;
    }
    if (strikerId === nonStrikerId) {
      alert('Striker and Non-Striker cannot be the same batsman.');
      return;
    }

    const res = store.startMatchWithToss({
      matchId: match.id,
      tossWinnerId,
      tossDecision,
      strikerId,
      nonStrikerId,
      bowlerId: openingBowlerId,
    });

    if (res.success) {
      onMatchStarted();
    } else {
      alert(res.error || 'Failed to start match.');
    }
  };

  const tossWinnerTeam = tossWinnerId === teamA.id ? teamA : teamB;
  const battingFirstTeam = battingFirstTeamId === teamA.id ? teamA : teamB;
  const bowlingFirstTeam = bowlingFirstTeamId === teamA.id ? teamA : teamB;

  return (
    <div className="w-full max-w-2xl mx-auto space-y-6">
      {/* Top Pre-Match Banner */}
      <div className="p-6 rounded-3xl bg-gradient-to-br from-slate-900 via-slate-950 to-cricket-950 text-white shadow-xl border border-slate-800">
        <div className="flex items-center justify-between text-xs text-slate-400 font-semibold mb-3">
          <span className="flex items-center gap-1.5 text-amber-400">
            <Coins size={14} className="animate-spin" />
            <span>Pre-Match Toss &amp; Lineup Ceremony</span>
          </span>
          <span>{match.overs} Overs Match</span>
        </div>

        <div className="grid grid-cols-5 items-center gap-2 text-center py-2">
          {/* Team A */}
          <div className="col-span-2 flex flex-col items-center gap-2">
            <div className="w-14 h-14 rounded-2xl overflow-hidden bg-white/10 p-1 border border-white/20 shadow-md">
              <img src={teamA.logoUrl} alt={teamA.name} className="w-full h-full object-cover rounded-xl" />
            </div>
            <span className="font-black text-sm text-white truncate max-w-[140px]">{teamA.name}</span>
            <span className="text-[10px] text-slate-400 font-bold">{teamAPlayers.length} Players Registered</span>
          </div>

          {/* VS */}
          <div className="col-span-1 flex flex-col items-center">
            <span className="w-8 h-8 rounded-full bg-slate-800 text-amber-400 font-black text-xs flex items-center justify-center border border-slate-700 shadow-inner">
              VS
            </span>
          </div>

          {/* Team B */}
          <div className="col-span-2 flex flex-col items-center gap-2">
            <div className="w-14 h-14 rounded-2xl overflow-hidden bg-white/10 p-1 border border-white/20 shadow-md">
              <img src={teamB.logoUrl} alt={teamB.name} className="w-full h-full object-cover rounded-xl" />
            </div>
            <span className="font-black text-sm text-white truncate max-w-[140px]">{teamB.name}</span>
            <span className="text-[10px] text-slate-400 font-bold">{teamBPlayers.length} Players Registered</span>
          </div>
        </div>

        <div className="mt-4 pt-3 border-t border-slate-800 flex items-center justify-between text-xs text-slate-400">
          <span className="flex items-center gap-1"><MapPin size={12} /> {match.venue}</span>
          <span className="flex items-center gap-1"><Clock size={12} /> {match.stage}</span>
        </div>
      </div>

      {/* Stepper Tabs */}
      <div className="grid grid-cols-3 gap-2">
        {[
          { num: 1 as const, title: '1. Squad Rosters' },
          { num: 2 as const, title: '2. Coin Toss' },
          { num: 3 as const, title: '3. Opening Crease' },
        ].map((s) => (
          <button
            key={s.num}
            onClick={() => setCurrentStep(s.num)}
            className={`py-2.5 px-3 rounded-2xl text-xs font-black transition border ${
              currentStep === s.num
                ? 'bg-cricket-600 text-white border-cricket-500 shadow-md shadow-cricket-600/20'
                : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-50'
            }`}
          >
            {s.title}
          </button>
        ))}
      </div>

      {/* ============================================================== */}
      {/* STEP 1: SQUADS & ADD PLAYER                                    */}
      {/* ============================================================== */}
      {currentStep === 1 && (
        <div className="bg-white rounded-3xl p-6 border border-slate-200 shadow-xs space-y-5">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <div>
              <h3 className="font-black text-base text-slate-900">Confirm Participating Rosters</h3>
              <p className="text-xs text-slate-500">Ensure playing squads are confirmed before the coin toss.</p>
            </div>
            <button
              onClick={() => setShowAddPlayerModal(true)}
              className="py-1.5 px-3 rounded-xl bg-cricket-50 hover:bg-cricket-100 text-cricket-700 text-xs font-bold transition flex items-center gap-1.5 border border-cricket-200"
            >
              <UserPlus size={13} />
              <span>Add Player</span>
            </button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {/* Team A List */}
            <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200 space-y-2">
              <span className="font-black text-xs text-slate-900 block">{teamA.name} ({teamAPlayers.length})</span>
              <div className="space-y-1.5 max-h-48 overflow-y-auto pr-1">
                {teamAPlayers.map((p) => (
                  <div key={p.id} className="p-2 rounded-xl bg-white border border-slate-200 text-xs flex items-center justify-between">
                    <span className="font-bold text-slate-800">{p.fullName}</span>
                    <span className="text-[10px] text-slate-400 capitalize">{p.role.replace(/_/g, ' ')}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Team B List */}
            <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200 space-y-2">
              <span className="font-black text-xs text-slate-900 block">{teamB.name} ({teamBPlayers.length})</span>
              <div className="space-y-1.5 max-h-48 overflow-y-auto pr-1">
                {teamBPlayers.map((p) => (
                  <div key={p.id} className="p-2 rounded-xl bg-white border border-slate-200 text-xs flex items-center justify-between">
                    <span className="font-bold text-slate-800">{p.fullName}</span>
                    <span className="text-[10px] text-slate-400 capitalize">{p.role.replace(/_/g, ' ')}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <button
            onClick={() => setCurrentStep(2)}
            className="w-full py-3.5 rounded-2xl bg-slate-900 hover:bg-slate-800 text-white font-black text-xs uppercase tracking-wider flex items-center justify-center gap-2 shadow-md"
          >
            <span>Proceed to Coin Toss</span>
            <ArrowRight size={14} />
          </button>
        </div>
      )}

      {/* ============================================================== */}
      {/* STEP 2: COIN TOSS                                              */}
      {/* ============================================================== */}
      {currentStep === 2 && (
        <div className="bg-white rounded-3xl p-6 border border-slate-200 shadow-xs space-y-5">
          <div className="text-center space-y-1 pb-3 border-b border-slate-100">
            <span className="text-2xl">🪙</span>
            <h3 className="font-black text-lg text-slate-900">Conduct the Official Toss</h3>
            <p className="text-xs text-slate-500">Select the toss winner and their elected decision.</p>
          </div>

          {/* Toss Winner Selector */}
          <div>
            <span className="text-xs font-bold text-slate-700 block mb-2 uppercase tracking-wider">
              1. Who Won the Toss?
            </span>
            <div className="grid grid-cols-2 gap-3">
              {[teamA, teamB].map((t) => (
                <button
                  key={t.id}
                  onClick={() => {
                    setTossWinnerId(t.id);
                  }}
                  className={`p-4 rounded-2xl border flex flex-col items-center gap-2 transition ${
                    tossWinnerId === t.id
                      ? 'bg-amber-50 border-amber-500 ring-2 ring-amber-500 shadow-md'
                      : 'bg-slate-50 border-slate-200 hover:bg-slate-100'
                  }`}
                >
                  <img src={t.logoUrl} alt={t.name} className="w-12 h-12 object-cover rounded-xl" />
                  <span className="font-black text-xs text-slate-900">{t.name}</span>
                  {tossWinnerId === t.id && (
                    <span className="px-2 py-0.5 rounded-full bg-amber-500 text-slate-950 font-black text-[10px]">
                      Toss Winner
                    </span>
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Toss Decision */}
          <div>
            <span className="text-xs font-bold text-slate-700 block mb-2 uppercase tracking-wider">
              2. Elected To?
            </span>
            <div className="grid grid-cols-2 gap-3">
              <button
                onClick={() => setTossDecision('bat')}
                className={`py-4 rounded-2xl border font-black text-sm uppercase tracking-wider flex items-center justify-center gap-2 transition ${
                  tossDecision === 'bat'
                    ? 'bg-cricket-600 text-white border-cricket-500 shadow-md shadow-cricket-600/20'
                    : 'bg-slate-50 text-slate-700 border-slate-200 hover:bg-slate-100'
                }`}
              >
                <span>🏏 Bat First</span>
              </button>
              <button
                onClick={() => setTossDecision('bowl')}
                className={`py-4 rounded-2xl border font-black text-sm uppercase tracking-wider flex items-center justify-center gap-2 transition ${
                  tossDecision === 'bowl'
                    ? 'bg-cricket-600 text-white border-cricket-500 shadow-md shadow-cricket-600/20'
                    : 'bg-slate-50 text-slate-700 border-slate-200 hover:bg-slate-100'
                }`}
              >
                <span>⚾ Bowl First</span>
              </button>
            </div>
          </div>

          {/* Toss Outcome Banner */}
          <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-200 text-center space-y-1">
            <span className="text-xs font-bold text-emerald-800 flex items-center justify-center gap-1.5">
              <Sparkles size={14} className="text-emerald-600" />
              <strong>{tossWinnerTeam.name}</strong> won the toss and elected to{' '}
              <strong className="uppercase">{tossDecision}</strong> first.
            </span>
            <p className="text-[11px] text-emerald-700">
              Innings 1: <strong>{battingFirstTeam.name}</strong> will bat. <strong>{bowlingFirstTeam.name}</strong> will bowl.
            </p>
          </div>

          <button
            onClick={() => {
              // Update defaults for crease
              if (battingRoster.length >= 2) {
                setStrikerId(battingRoster[0].id);
                setNonStrikerId(battingRoster[1].id);
              }
              if (bowlingRoster.length > 0) {
                setOpeningBowlerId(bowlingRoster[bowlingRoster.length - 1].id);
              }
              setCurrentStep(3);
            }}
            className="w-full py-3.5 rounded-2xl bg-slate-900 hover:bg-slate-800 text-white font-black text-xs uppercase tracking-wider flex items-center justify-center gap-2 shadow-md"
          >
            <span>Proceed to Opening Crease Lineup</span>
            <ArrowRight size={14} />
          </button>
        </div>
      )}

      {/* ============================================================== */}
      {/* STEP 3: OPENING CREASE LINEUP & START MATCH                    */}
      {/* ============================================================== */}
      {currentStep === 3 && (
        <div className="bg-white rounded-3xl p-6 border border-slate-200 shadow-xs space-y-5">
          <div className="pb-3 border-b border-slate-100">
            <h3 className="font-black text-base text-slate-900">Select Opening Batters &amp; Bowler</h3>
            <p className="text-xs text-slate-500">
              Set the opening batsman on strike, non-striker, and the bowler to deliver Over 1.
            </p>
          </div>

          <div className="space-y-4">
            {/* Opening Striker */}
            <div>
              <label className="text-xs font-bold text-slate-800 block mb-1">
                Opening Striker ({battingFirstTeam.name})
              </label>
              <select
                value={strikerId}
                onChange={(e) => setStrikerId(e.target.value)}
                className="w-full p-3 rounded-xl border border-slate-300 text-xs font-bold bg-white"
              >
                {battingRoster.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.fullName} ({p.role.replace(/_/g, ' ')})
                  </option>
                ))}
              </select>
            </div>

            {/* Opening Non-Striker */}
            <div>
              <label className="text-xs font-bold text-slate-800 block mb-1">
                Opening Non-Striker ({battingFirstTeam.name})
              </label>
              <select
                value={nonStrikerId}
                onChange={(e) => setNonStrikerId(e.target.value)}
                className="w-full p-3 rounded-xl border border-slate-300 text-xs font-bold bg-white"
              >
                {battingRoster.map((p) => (
                  <option key={p.id} value={p.id} disabled={p.id === strikerId}>
                    {p.fullName} {p.id === strikerId ? '(Already on Strike)' : `(${p.role.replace(/_/g, ' ')})`}
                  </option>
                ))}
              </select>
            </div>

            {/* Opening Bowler */}
            <div>
              <label className="text-xs font-bold text-slate-800 block mb-1">
                Opening Bowler ({bowlingFirstTeam.name})
              </label>
              <select
                value={openingBowlerId}
                onChange={(e) => setOpeningBowlerId(e.target.value)}
                className="w-full p-3 rounded-xl border border-slate-300 text-xs font-bold bg-white"
              >
                {bowlingRoster.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.fullName} ({p.role.replace(/_/g, ' ')} • {p.bowlingStyle.replace(/_/g, ' ')})
                  </option>
                ))}
              </select>
            </div>
          </div>

          <button
            onClick={handleStartMatch}
            className="w-full py-4 rounded-2xl bg-cricket-600 hover:bg-cricket-500 text-white font-black text-sm uppercase tracking-wider flex items-center justify-center gap-2 shadow-xl shadow-cricket-600/30 transition active:scale-95"
          >
            <span>Start Match &amp; Begin Live Scoring (Over 0.1)</span>
            <ArrowRight size={16} />
          </button>
        </div>
      )}

      {/* Quick Add Player Modal */}
      {showAddPlayerModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm animate-in fade-in">
          <form onSubmit={handleAddPlayer} className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 space-y-4">
            <h3 className="text-base font-black text-slate-900">Add Player to Team Squad</h3>

            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Team</label>
              <select
                value={newPlayerTeamId}
                onChange={(e) => setNewPlayerTeamId(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-300 text-xs font-semibold bg-white"
              >
                <option value={teamA.id}>{teamA.name}</option>
                <option value={teamB.id}>{teamB.name}</option>
              </select>
            </div>

            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Player Full Name</label>
              <input
                type="text"
                required
                placeholder="e.g. Sourav Ganguly"
                value={newPlayerName}
                onChange={(e) => setNewPlayerName(e.target.value)}
                className="w-full p-2.5 rounded-xl border border-slate-300 text-xs font-semibold"
              />
            </div>

            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Role</label>
              <select
                value={newPlayerRole}
                onChange={(e) => setNewPlayerRole(e.target.value as Player['role'])}
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
                Save Player
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
