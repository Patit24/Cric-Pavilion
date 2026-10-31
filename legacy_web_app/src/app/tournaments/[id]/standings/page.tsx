'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { store } from '@/lib/store/mock-db';
import { Trophy, ArrowLeft, Info, ArrowUpRight } from 'lucide-react';

export default function TournamentStandingsPage() {
  const params = useParams();
  const tournamentId = (params?.id as string) || 'tourn_bpl_2026';

  const [state, setState] = useState(() => store.getState());

  useEffect(() => {
    return store.subscribe(() => {
      setState({ ...store.getState() });
    });
  }, []);

  const tournament = state.tournaments.find((t) => t.id === tournamentId) || state.tournaments[0];
  const standings = state.tournamentStandings.filter((s) => s.tournamentId === tournament?.id);

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-6">
      <div className="flex items-center gap-3">
        <Link
          href="/tournaments"
          className="p-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 transition"
        >
          <ArrowLeft size={16} />
        </Link>
        <div>
          <h1 className="text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">
            {tournament?.name} — Points Table & Standings
          </h1>
          <p className="text-xs text-slate-500">
            Official league table. Net Run Rate (NRR) calculated according to ICC / BCCI tournament rules.
          </p>
        </div>
      </div>

      {/* Official NRR Explanation Banner */}
      <div className="p-4 rounded-2xl bg-cricket-50 border border-cricket-200 text-xs text-cricket-900 flex items-start gap-3">
        <Info size={18} className="text-cricket-600 shrink-0 mt-0.5" />
        <div>
          <span className="font-bold block">ICC Net Run Rate (NRR) Standard Implemented:</span>
          <span>
            NRR is calculated as: <em>(Total Runs Scored / Total Overs Faced) - (Total Runs Conceded / Total Overs Bowled)</em>. If a team is bowled out (all out) inside their allocated overs, their run rate is calculated using the full quota of overs that they were scheduled to have received ({tournament?.oversPerInnings} overs).
          </span>
        </div>
      </div>

      {/* Points Table */}
      <div className="bg-white rounded-3xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 text-slate-500 font-bold uppercase tracking-wider border-b border-slate-200">
              <tr>
                <th className="px-6 py-4">Pos & Franchise</th>
                <th className="px-4 py-4 text-center">Played</th>
                <th className="px-4 py-4 text-center">Won</th>
                <th className="px-4 py-4 text-center">Lost</th>
                <th className="px-4 py-4 text-center">Tied</th>
                <th className="px-4 py-4 text-center">NR</th>
                <th className="px-4 py-4 text-center font-black text-slate-900">Points</th>
                <th className="px-6 py-4 text-right">Net Run Rate (NRR)</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 font-medium">
              {standings.map((row, idx) => (
                <tr
                  key={row.teamId}
                  className={`hover:bg-slate-50/80 transition ${
                    idx < 2 ? 'bg-emerald-50/30' : ''
                  }`}
                >
                  <td className="px-6 py-4 flex items-center gap-3">
                    <span className={`w-5 font-black text-center ${idx < 2 ? 'text-emerald-700' : 'text-slate-400'}`}>
                      {row.rank || idx + 1}
                    </span>
                    <div className="w-8 h-8 rounded-lg overflow-hidden bg-slate-100 border border-slate-200 shrink-0">
                      <img src={row.teamLogoUrl} alt={row.teamName} className="w-full h-full object-cover" />
                    </div>
                    <div>
                      <span className="font-bold text-slate-900 text-sm block">{row.teamName}</span>
                      <span className="text-[10px] text-slate-400 uppercase font-mono">{row.teamShortName}</span>
                    </div>
                  </td>
                  <td className="px-4 py-4 text-center text-slate-600 font-bold">{row.matchesPlayed}</td>
                  <td className="px-4 py-4 text-center font-black text-emerald-600">{row.won}</td>
                  <td className="px-4 py-4 text-center text-slate-500">{row.lost}</td>
                  <td className="px-4 py-4 text-center text-slate-500">{row.tied}</td>
                  <td className="px-4 py-4 text-center text-slate-500">{row.noResult}</td>
                  <td className="px-4 py-4 text-center font-black text-slate-900 text-base">{row.points}</td>
                  <td
                    className={`px-6 py-4 text-right font-mono font-black text-sm ${
                      row.netRunRate > 0 ? 'text-emerald-600' : row.netRunRate < 0 ? 'text-rose-600' : 'text-slate-600'
                    }`}
                  >
                    {row.netRunRate > 0 ? `+${row.netRunRate.toFixed(3)}` : row.netRunRate.toFixed(3)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
