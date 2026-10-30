'use client';

import React, { useState, useEffect } from 'react';
import { store } from '@/lib/store/mock-db';
import { UserProfile, UserRole } from '@/lib/types';
import { Shield, User, Trophy, DollarSign, Radio, CheckCircle, ChevronDown, RefreshCw } from 'lucide-react';

export default function RoleSwitcher() {
  const [currentUser, setCurrentUser] = useState<UserProfile>(store.getState().currentUser);
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    return store.subscribe(() => {
      setCurrentUser(store.getState().currentUser);
    });
  }, []);

  const roles = [
    {
      role: 'organizer' as UserRole,
      title: 'Tournament Organizer',
      desc: 'Auction control room, spin wheel, manage fixtures',
      icon: Trophy,
      color: 'text-amber-500 bg-amber-50',
    },
    {
      role: 'team_owner' as UserRole,
      teamId: 'team_barasat',
      title: 'Owner: Barasat Blasters',
      desc: 'Bidding console, team purse, squad roster',
      icon: DollarSign,
      color: 'text-emerald-600 bg-emerald-50',
    },
    {
      role: 'team_owner' as UserRole,
      teamId: 'team_kolkata',
      title: 'Owner: Kolkata Knights',
      desc: 'Counter-bid live, monitor remaining funds',
      icon: DollarSign,
      color: 'text-indigo-600 bg-indigo-50',
    },
    {
      role: 'scorer' as UserRole,
      title: 'Official Match Scorer',
      desc: 'Mobile-first ball-by-ball scoring, toss & overs',
      icon: Radio,
      color: 'text-rose-600 bg-rose-50',
    },
    {
      role: 'spectator' as UserRole,
      title: 'Public Spectator',
      desc: 'Live scoreboard, full scorecard, commentary',
      icon: User,
      color: 'text-slate-600 bg-slate-100',
    },
    {
      role: 'super_admin' as UserRole,
      title: 'Super Administrator',
      desc: 'Platform governance, moderation, audit logs',
      icon: Shield,
      color: 'text-purple-600 bg-purple-50',
    },
  ];

  return (
    <div className="relative inline-block text-left">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-1.5 text-xs font-medium rounded-full bg-slate-900 text-white hover:bg-slate-800 transition shadow-sm border border-slate-700"
      >
        <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
        <span>Role: <strong className="text-emerald-400">{currentUser.fullName.split(' ')[0]}</strong> ({currentUser.role})</span>
        <ChevronDown size={14} className={`transform transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-72 rounded-xl bg-white shadow-xl border border-slate-200 z-50 p-2 overflow-hidden animate-in fade-in slide-in-from-top-2 duration-150">
          <div className="px-3 py-2 border-b border-slate-100 flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Switch Active Identity</span>
            <button
              onClick={() => store.resetToDefaults()}
              className="text-[11px] text-slate-400 hover:text-emerald-600 flex items-center gap-1"
              title="Reset all auction & scoring data to fresh state"
            >
              <RefreshCw size={11} /> Reset Data
            </button>
          </div>

          <div className="space-y-1 mt-1">
            {roles.map((item, idx) => {
              const Icon = item.icon;
              const isActive =
                currentUser.role === item.role &&
                (!item.teamId || currentUser.email.includes(item.teamId.replace('team_', '')));

              return (
                <button
                  key={idx}
                  onClick={() => {
                    store.switchRole(item.role, item.teamId);
                    setIsOpen(false);
                  }}
                  className={`w-full text-left p-2 rounded-lg flex items-start gap-2.5 transition text-xs ${
                    isActive ? 'bg-emerald-50/70 border border-emerald-200' : 'hover:bg-slate-50 border border-transparent'
                  }`}
                >
                  <div className={`p-1.5 rounded-md ${item.color} mt-0.5 shrink-0`}>
                    <Icon size={14} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between">
                      <span className="font-semibold text-slate-900 truncate">{item.title}</span>
                      {isActive && <CheckCircle size={14} className="text-emerald-600 shrink-0" />}
                    </div>
                    <p className="text-[11px] text-slate-500 line-clamp-1">{item.desc}</p>
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
