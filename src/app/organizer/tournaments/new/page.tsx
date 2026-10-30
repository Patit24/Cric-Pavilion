'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { store } from '@/lib/store/mock-db';
import { Tournament, TournamentFormat } from '@/lib/types';
import {
  Trophy,
  Check,
  ChevronRight,
  ChevronLeft,
  Calendar,
  MapPin,
  Shield,
  Gavel,
  Users,
  Sparkles,
} from 'lucide-react';

export default function NewTournamentWizard() {
  const router = useRouter();
  const [step, setStep] = useState(1);

  // Form State
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [location, setLocation] = useState('Eden Gardens, Kolkata');
  const [startDate, setStartDate] = useState('2026-11-01');
  const [endDate, setEndDate] = useState('2026-12-01');
  const [format, setFormat] = useState<TournamentFormat>('round_robin');
  const [oversPerInnings, setOversPerInnings] = useState(20);
  const [squadSizeMax, setSquadSizeMax] = useState(18);
  const [playingXISize, setPlayingXISize] = useState(11);
  const [hasAuction, setHasAuction] = useState(true);
  const [initialPurse, setInitialPurse] = useState(10000000); // 1 Crore
  const [minBidIncrement, setMinBidIncrement] = useState(50000);

  const steps = [
    'Basic Info',
    'Format',
    'Match Rules',
    'Teams',
    'Auction Config',
    'Fixtures',
    'Publish',
  ];

  const handlePublish = () => {
    const newId = `tourn_${Date.now()}`;
    const newTourn: Tournament = {
      id: newId,
      name: name || 'New Premier Cricket League',
      slug: (name || 'new-league').toLowerCase().replace(/\s+/g, '-'),
      description: description || 'Professional T20 cricket tournament.',
      logoUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=128&auto=format&fit=crop&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1531415074868-036b1c57e359?w=1200&auto=format&fit=crop&q=80',
      organizerId: store.getState().currentUser.id,
      status: 'published',
      format,
      startDate,
      endDate,
      location,
      oversPerInnings,
      squadSizeMax,
      squadSizeMin: 11,
      playingXISize,
      powerplayOvers: 6,
      pointsWin: 2,
      pointsTie: 1,
      pointsNoResult: 1,
      hasAuction,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    store.getState().tournaments.unshift(newTourn);
    router.push('/tournaments');
  };

  return (
    <div className="max-w-4xl mx-auto px-4 py-10 space-y-8">
      {/* Wizard Header */}
      <div>
        <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-700 text-xs font-bold uppercase tracking-wider mb-2">
          <Trophy size={14} />
          <span>Tournament Creation Wizard</span>
        </div>
        <h1 className="text-3xl font-black text-slate-900 tracking-tight">
          Create New Cricket Competition
        </h1>
        <p className="text-sm text-slate-500 mt-0.5">
          Step {step} of 7: {steps[step - 1]}
        </p>
      </div>

      {/* Progress Stepper Bar */}
      <div className="flex items-center justify-between border-b border-slate-200 pb-4 overflow-x-auto">
        {steps.map((label, idx) => {
          const stepNum = idx + 1;
          const isDone = step > stepNum;
          const isCurrent = step === stepNum;

          return (
            <div key={label} className="flex items-center gap-2 shrink-0 px-1">
              <div
                className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-black ${
                  isDone
                    ? 'bg-emerald-600 text-white'
                    : isCurrent
                    ? 'bg-slate-900 text-white ring-4 ring-emerald-100'
                    : 'bg-slate-100 text-slate-400'
                }`}
              >
                {isDone ? <Check size={14} /> : stepNum}
              </div>
              <span className={`text-xs font-semibold ${isCurrent ? 'text-slate-900' : 'text-slate-400'}`}>
                {label}
              </span>
              {stepNum < steps.length && <ChevronRight size={14} className="text-slate-300 ml-1" />}
            </div>
          );
        })}
      </div>

      {/* STEP 1: BASIC INFORMATION */}
      {step === 1 && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-xs p-6 sm:p-8 space-y-5">
          <h2 className="text-lg font-bold text-slate-900">Step 1 — Basic Information</h2>

          <div className="space-y-4">
            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Tournament Name *</label>
              <input
                type="text"
                placeholder="e.g. North 24 Parganas Premier League 2026"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full p-3 rounded-xl border border-slate-300 text-sm focus:ring-2 focus:ring-cricket-500"
              />
            </div>

            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Description</label>
              <textarea
                placeholder="Tournament background, participating franchises, and prizes..."
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                rows={3}
                className="w-full p-3 rounded-xl border border-slate-300 text-sm focus:ring-2 focus:ring-cricket-500"
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">Location / Host City</label>
                <input
                  type="text"
                  value={location}
                  onChange={(e) => setLocation(e.target.value)}
                  className="w-full p-3 rounded-xl border border-slate-300 text-sm"
                />
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">Start Date</label>
                  <input
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                    className="w-full p-3 rounded-xl border border-slate-300 text-sm"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">End Date</label>
                  <input
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                    className="w-full p-3 rounded-xl border border-slate-300 text-sm"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* STEP 2: FORMAT */}
      {step === 2 && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-xs p-6 sm:p-8 space-y-5">
          <h2 className="text-lg font-bold text-slate-900">Step 2 — Competition Format</h2>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {[
              { id: 'round_robin' as TournamentFormat, title: 'Round Robin League', desc: 'Each team plays every other team once or twice.' },
              { id: 'groups_and_knockout' as TournamentFormat, title: 'Groups & Knockout', desc: 'Group stage followed by Semifinals & Finals.' },
              { id: 'knockout' as TournamentFormat, title: 'Pure Knockout', desc: 'Single elimination bracket.' },
              { id: 'league' as TournamentFormat, title: 'Classic League Table', desc: 'Top table finisher crowned champions.' },
            ].map((f) => (
              <button
                key={f.id}
                onClick={() => setFormat(f.id)}
                className={`p-5 rounded-2xl border text-left transition ${
                  format === f.id
                    ? 'border-cricket-600 bg-cricket-50/60 ring-2 ring-cricket-600'
                    : 'border-slate-200 hover:border-slate-300'
                }`}
              >
                <span className="font-bold text-slate-900 text-sm block">{f.title}</span>
                <span className="text-xs text-slate-500 mt-1 block">{f.desc}</span>
              </button>
            ))}
          </div>
        </div>
      )}

      {/* STEP 3: MATCH RULES */}
      {step === 3 && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-xs p-6 sm:p-8 space-y-5">
          <h2 className="text-lg font-bold text-slate-900">Step 3 — Match Rules & Overs</h2>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Overs Per Innings</label>
              <input
                type="number"
                value={oversPerInnings}
                onChange={(e) => setOversPerInnings(Number(e.target.value))}
                className="w-full p-3 rounded-xl border border-slate-300 text-sm font-bold"
              />
            </div>
            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Max Squad Size</label>
              <input
                type="number"
                value={squadSizeMax}
                onChange={(e) => setSquadSizeMax(Number(e.target.value))}
                className="w-full p-3 rounded-xl border border-slate-300 text-sm font-bold"
              />
            </div>
            <div>
              <label className="text-xs font-bold text-slate-700 block mb-1">Playing XI Size</label>
              <input
                type="number"
                value={playingXISize}
                onChange={(e) => setPlayingXISize(Number(e.target.value))}
                className="w-full p-3 rounded-xl border border-slate-300 text-sm font-bold"
              />
            </div>
          </div>
        </div>
      )}

      {/* STEP 4: TEAMS */}
      {step === 4 && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-xs p-6 sm:p-8 space-y-5">
          <h2 className="text-lg font-bold text-slate-900">Step 4 — Participating Teams</h2>
          <p className="text-xs text-slate-500">
            5 default registered teams will be assigned to this tournament: Barasat Blasters, Kolkata Knights, Howrah Hurricanes, Sundarbans Strikers, and Siliguri Superstars.
          </p>
          <div className="space-y-2">
            {store.getState().teams.map((t) => (
              <div key={t.id} className="p-3 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between text-xs">
                <span className="font-bold text-slate-900">{t.name} ({t.shortName})</span>
                <span className="text-slate-500">Purse: ₹{(t.initialPurse / 10000000).toFixed(1)} Cr</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* STEP 5: AUCTION CONFIG */}
      {step === 5 && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-xs p-6 sm:p-8 space-y-5">
          <h2 className="text-lg font-bold text-slate-900">Step 5 — Franchise Auction Configuration</h2>

          <div className="flex items-center gap-3 p-4 rounded-2xl bg-slate-50 border border-slate-200">
            <input
              type="checkbox"
              id="hasAuction"
              checked={hasAuction}
              onChange={(e) => setHasAuction(e.target.checked)}
              className="w-5 h-5 rounded text-cricket-600"
            />
            <label htmlFor="hasAuction" className="text-xs font-bold text-slate-800">
              Enable Franchise Player Auction with Spinning Wheel & Real-Time Bidding
            </label>
          </div>

          {hasAuction && (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">Franchise Purse per Team (₹)</label>
                <input
                  type="number"
                  value={initialPurse}
                  onChange={(e) => setInitialPurse(Number(e.target.value))}
                  className="w-full p-3 rounded-xl border border-slate-300 text-sm font-bold"
                />
              </div>
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">Minimum Bid Increment (₹)</label>
                <input
                  type="number"
                  value={minBidIncrement}
                  onChange={(e) => setMinBidIncrement(Number(e.target.value))}
                  className="w-full p-3 rounded-xl border border-slate-300 text-sm font-bold"
                />
              </div>
            </div>
          )}
        </div>
      )}

      {/* STEP 6: FIXTURES */}
      {step === 6 && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-xs p-6 sm:p-8 space-y-5">
          <h2 className="text-lg font-bold text-slate-900">Step 6 — Fixture Generation</h2>
          <p className="text-xs text-slate-500">
            Automated round-robin fixtures schedule has been computed across Eden Gardens, Kalyani, and Kanchenjunga stadiums.
          </p>
          <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-200 text-xs text-emerald-800 font-semibold">
            ✓ 10 Round-robin league fixtures + 2 Knockout qualifiers scheduled.
          </div>
        </div>
      )}

      {/* STEP 7: PUBLISH */}
      {step === 7 && (
        <div className="bg-white rounded-3xl border border-slate-200 shadow-xs p-6 sm:p-8 space-y-5 text-center">
          <div className="w-16 h-16 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto">
            <Sparkles size={32} />
          </div>
          <h2 className="text-2xl font-black text-slate-900 tracking-tight">Ready to Publish Tournament!</h2>
          <p className="text-xs text-slate-500 max-w-md mx-auto">
            Review completed settings. Publishing will create the competition, activate franchise player auction pools, and generate public match centre links.
          </p>

          <button
            onClick={handlePublish}
            className="py-4 px-8 rounded-2xl bg-cricket-600 hover:bg-cricket-500 text-white font-black text-sm uppercase tracking-wider shadow-lg shadow-cricket-600/25 transition active:scale-95"
          >
            Publish Tournament Now
          </button>
        </div>
      )}

      {/* Navigation Buttons */}
      <div className="flex items-center justify-between pt-4 border-t border-slate-200">
        {step > 1 ? (
          <button
            onClick={() => setStep(step - 1)}
            className="py-2.5 px-4 rounded-xl border border-slate-300 text-xs font-bold text-slate-700 hover:bg-slate-50 transition flex items-center gap-1.5"
          >
            <ChevronLeft size={16} />
            <span>Previous Step</span>
          </button>
        ) : (
          <div></div>
        )}

        {step < 7 && (
          <button
            onClick={() => setStep(step + 1)}
            className="py-2.5 px-6 rounded-xl bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold transition flex items-center gap-1.5"
          >
            <span>Next Step</span>
            <ChevronRight size={16} />
          </button>
        )}
      </div>
    </div>
  );
}
