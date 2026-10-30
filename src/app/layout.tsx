import type { Metadata } from 'next';
import './globals.css';
import Navbar from '@/components/Navbar';
import Link from 'next/link';
import { Trophy, Shield, Heart } from 'lucide-react';

export const metadata: Metadata = {
  title: 'CricPavilion Pro — Tournament Management, Live Scoring & Franchise Auction Platform',
  description:
    'Complete cricket platform inspired by CricHeroes and Cricbuzz with real-time player auctions, ball-by-ball live scoring, team purses, and tournament standings.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="min-h-screen flex flex-col bg-slate-50 text-slate-900 antialiased">
        <Navbar />
        <main className="flex-1">{children}</main>

        {/* Global Footer */}
        <footer className="bg-slate-950 text-slate-400 text-xs border-t border-slate-800 py-10 mt-16">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-8 pb-8 border-b border-slate-800">
              <div className="space-y-3">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-xl bg-cricket-600 flex items-center justify-center text-white font-bold">
                    <Trophy size={18} />
                  </div>
                  <span className="text-base font-black text-white tracking-tight">
                    CRIC<span className="text-cricket-500">PAVILION</span>
                  </span>
                </div>
                <p className="text-[11px] text-slate-400 leading-relaxed">
                  The complete cricket tournament ecosystem: ball-by-ball live scoring engine, franchise spinning wheel player auctions, squad management, and real-time net run rate calculation.
                </p>
              </div>

              <div>
                <h4 className="font-bold text-white uppercase tracking-wider text-[11px] mb-3">Live Platform</h4>
                <ul className="space-y-2 text-[11px]">
                  <li><Link href="/matches" className="hover:text-emerald-400 transition">Live Match Centre</Link></li>
                  <li><Link href="/auctions" className="hover:text-emerald-400 transition">Franchise Auction Stage</Link></li>
                  <li><Link href="/scorer" className="hover:text-emerald-400 transition">Scorer Console</Link></li>
                  <li><Link href="/tournaments" className="hover:text-emerald-400 transition">Tournament Standings & NRR</Link></li>
                </ul>
              </div>

              <div>
                <h4 className="font-bold text-white uppercase tracking-wider text-[11px] mb-3">Franchise & Teams</h4>
                <ul className="space-y-2 text-[11px]">
                  <li><Link href="/teams" className="hover:text-emerald-400 transition">Team Rosters & Squads</Link></li>
                  <li><Link href="/auctions/auc_bpl_2026/purse" className="hover:text-emerald-400 transition">Team Purse Balances</Link></li>
                  <li><Link href="/players" className="hover:text-emerald-400 transition">Verified Player Registry</Link></li>
                  <li><Link href="/organizer" className="hover:text-emerald-400 transition">Tournament Organizer Hub</Link></li>
                </ul>
              </div>

              <div>
                <h4 className="font-bold text-white uppercase tracking-wider text-[11px] mb-3">Architecture & Rules</h4>
                <p className="text-[11px] text-slate-400 leading-relaxed mb-2">
                  Engineered with PostgreSQL transactional integrity, ICC Net Run Rate rules with All-Out quota handling, and server-authoritative bidding concurrency controls.
                </p>
                <div className="flex items-center gap-2 text-emerald-400 font-semibold text-[10px]">
                  <Shield size={13} />
                  <span>RLS & Concurrency Protected</span>
                </div>
              </div>
            </div>

            <div className="pt-6 flex flex-col sm:flex-row items-center justify-between text-[11px] text-slate-500">
              <p>© 2026 CricPavilion. All rights reserved.</p>
              <p className="mt-2 sm:mt-0 flex items-center gap-1">
                Built with <Heart size={11} className="text-rose-500 fill-rose-500" /> for grassroots and professional cricket.
              </p>
            </div>
          </div>
        </footer>
      </body>
    </html>
  );
}
