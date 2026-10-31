'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import RoleSwitcher from './RoleSwitcher';
import { store } from '@/lib/store/mock-db';
import {
  Trophy,
  Radio,
  Gavel,
  Shield,
  Menu,
  X,
  Flame,
  Search,
} from 'lucide-react';

export default function Navbar() {
  const pathname = usePathname();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [liveMatch, setLiveMatch] = useState(() => {
    return store.getState().matches.find((m) => m.status === 'live');
  });

  useEffect(() => {
    return store.subscribe(() => {
      setLiveMatch(store.getState().matches.find((m) => m.status === 'live'));
    });
  }, []);

  const navLinks = [
    { name: 'Home', href: '/' },
    { name: 'Tournaments', href: '/tournaments' },
    { name: 'Live Matches', href: '/matches', badge: 'LIVE' },
    { name: 'Player Auction', href: '/auctions', badge: 'HOT' },
    { name: 'Scorer Console', href: '/scorer' },
    { name: 'Organizer Hub', href: '/organizer' },
    { name: 'Teams', href: '/teams' },
    { name: 'Players', href: '/players' },
  ];

  return (
    <header className="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-slate-200 shadow-xs">
      {/* Live Match Alert Ticker Bar */}
      {liveMatch && (
        <div className="bg-slate-900 text-white text-xs px-4 py-1.5 flex items-center justify-between border-b border-slate-800">
          <div className="max-w-7xl mx-auto w-full flex items-center justify-between">
            <div className="flex items-center gap-2 overflow-hidden">
              <span className="flex h-2 w-2 relative shrink-0">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-rose-500"></span>
              </span>
              <span className="font-semibold text-rose-400 uppercase tracking-wider text-[11px] shrink-0">Live Match:</span>
              <span className="truncate text-slate-300">
                Bengal Premier League 2026 • Barasat Blasters vs Kolkata Knights (Over 14.3)
              </span>
            </div>
            <Link
              href={`/matches/${liveMatch.id}`}
              className="text-emerald-400 hover:text-emerald-300 font-medium text-[11px] shrink-0 flex items-center gap-1 ml-4"
            >
              Watch Scorecard →
            </Link>
          </div>
        </div>
      )}

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo & Brand */}
          <div className="flex items-center gap-3">
            <Link href="/" className="flex items-center gap-2 group">
              <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-cricket-700 to-cricket-500 flex items-center justify-center text-white shadow-md shadow-cricket-600/20 group-hover:scale-105 transition">
                <Trophy size={20} className="stroke-[2.5]" />
              </div>
              <div>
                <span className="text-lg font-black tracking-tight text-slate-900 flex items-center">
                  CRIC<span className="text-cricket-600">PAVILION</span>
                </span>
                <span className="text-[10px] block font-semibold text-slate-400 tracking-wider uppercase -mt-1">
                  Pro Tournament & Auction
                </span>
              </div>
            </Link>
          </div>

          {/* Desktop Navigation */}
          <nav className="hidden lg:flex items-center gap-1">
            {navLinks.map((link) => {
              const isActive = pathname === link.href || (link.href !== '/' && pathname.startsWith(link.href));
              return (
                <Link
                  key={link.name}
                  href={link.href}
                  className={`px-3 py-2 rounded-lg text-xs font-semibold transition flex items-center gap-1.5 ${
                    isActive
                      ? 'bg-cricket-50 text-cricket-700 font-bold'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                  }`}
                >
                  {link.name}
                  {link.badge && (
                    <span
                      className={`text-[9px] px-1.5 py-0.2 rounded-full font-bold ${
                        link.badge === 'LIVE'
                          ? 'bg-rose-500 text-white animate-pulse'
                          : 'bg-amber-400 text-slate-900'
                      }`}
                    >
                      {link.badge}
                    </span>
                  )}
                </Link>
              );
            })}
          </nav>

          {/* Right Action: Role Switcher & Mobile Menu Trigger */}
          <div className="flex items-center gap-3">
            <RoleSwitcher />

            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="lg:hidden p-2 rounded-lg text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition"
              aria-label="Toggle mobile menu"
            >
              {mobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Drawer */}
      {mobileMenuOpen && (
        <div className="lg:hidden border-t border-slate-200 bg-white px-4 pt-2 pb-6 space-y-1 shadow-lg animate-in slide-in-from-top-3">
          {navLinks.map((link) => {
            const isActive = pathname === link.href || (link.href !== '/' && pathname.startsWith(link.href));
            return (
              <Link
                key={link.name}
                href={link.href}
                onClick={() => setMobileMenuOpen(false)}
                className={`block px-3 py-2.5 rounded-lg text-sm font-semibold transition flex items-center justify-between ${
                  isActive
                    ? 'bg-cricket-50 text-cricket-700'
                    : 'text-slate-700 hover:bg-slate-50'
                }`}
              >
                <span>{link.name}</span>
                {link.badge && (
                  <span
                    className={`text-[10px] px-2 py-0.5 rounded-full font-bold ${
                      link.badge === 'LIVE'
                        ? 'bg-rose-500 text-white animate-pulse'
                        : 'bg-amber-400 text-slate-900'
                    }`}
                  >
                    {link.badge}
                  </span>
                )}
              </Link>
            );
          })}
        </div>
      )}
    </header>
  );
}
