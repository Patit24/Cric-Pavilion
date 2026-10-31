'use client';

import React, { useRef, useState, useEffect } from 'react';
import { AuctionPlayerPoolItem } from '@/lib/types';
import { auctionSound } from '@/lib/auction-engine/sound';
import { Play, Volume2, VolumeX, Sparkles, RefreshCw } from 'lucide-react';

interface SpinningWheelProps {
  eligibleLots: AuctionPlayerPoolItem[];
  isSpinning: boolean;
  onSpinRequest?: () => void;
  onSpinComplete?: (selectedLot: AuctionPlayerPoolItem) => void;
  canSpin?: boolean;
}

export default function SpinningWheel({
  eligibleLots,
  isSpinning,
  onSpinRequest,
  onSpinComplete,
  canSpin = true,
}: SpinningWheelProps) {
  const [rotationAngle, setRotationAngle] = useState(0);
  const [isMuted, setIsMuted] = useState(false);
  const [animating, setAnimating] = useState(false);
  const spinIntervalRef = useRef<NodeJS.Timeout | null>(null);

  // Palette for wheel segments
  const sliceColors = [
    '#10b981', // emerald
    '#6366f1', // indigo
    '#f59e0b', // amber
    '#06b6d4', // cyan
    '#ec4899', // pink
    '#8b5cf6', // purple
    '#14b8a6', // teal
    '#f97316', // orange
  ];

  const count = Math.max(1, eligibleLots.length);
  const sliceAngle = 360 / count;

  const handleSpinClick = () => {
    if (animating || !canSpin || eligibleLots.length === 0) return;
    setAnimating(true);

    if (onSpinRequest) {
      onSpinRequest();
    }

    // Pick random target lot
    const targetIdx = Math.floor(Math.random() * eligibleLots.length);
    const targetLot = eligibleLots[targetIdx];

    // Compute extra full spins (5-8 rotations) + target angle so needle (top 270 deg) aligns
    const extraRotations = (5 + Math.floor(Math.random() * 3)) * 360;
    const targetOffset = 360 - (targetIdx * sliceAngle + sliceAngle / 2);
    const finalAngle = rotationAngle + extraRotations + targetOffset;

    setRotationAngle(finalAngle);

    // Audio click sequence during spin
    let tickCounter = 0;
    const tickInterval = setInterval(() => {
      auctionSound.playWheelTick();
      tickCounter++;
      if (tickCounter > 35) {
        clearInterval(tickInterval);
      }
    }, 110);

    // Animation completion
    setTimeout(() => {
      setAnimating(false);
      clearInterval(tickInterval);
      if (onSpinComplete) {
        onSpinComplete(targetLot);
      }
    }, 4000);
  };

  return (
    <div className="relative flex flex-col items-center justify-center p-6 bg-slate-950/80 rounded-3xl border border-slate-800 shadow-2xl backdrop-blur-md overflow-hidden">
      {/* Background Stadium Glow & Spotlights */}
      <div className="absolute inset-0 pointer-events-none opacity-30">
        <div className="absolute -top-24 -left-24 w-80 h-80 rounded-full bg-emerald-500/20 blur-3xl"></div>
        <div className="absolute -bottom-24 -right-24 w-80 h-80 rounded-full bg-amber-500/20 blur-3xl"></div>
      </div>

      {/* Header controls */}
      <div className="w-full flex items-center justify-between mb-4 z-10 px-2">
        <div className="flex items-center gap-2">
          <span className="w-2.5 h-2.5 rounded-full bg-amber-400 animate-ping"></span>
          <span className="text-xs font-bold text-amber-400 uppercase tracking-widest">
            Player Selection Wheel
          </span>
        </div>
        <button
          onClick={() => {
            const muted = auctionSound.toggleMute();
            setIsMuted(muted);
          }}
          className="p-1.5 rounded-lg bg-slate-800/80 text-slate-300 hover:text-white transition text-xs flex items-center gap-1 border border-slate-700"
          title={isMuted ? 'Unmute Sound' : 'Mute Sound'}
        >
          {isMuted ? <VolumeX size={14} className="text-rose-400" /> : <Volume2 size={14} className="text-emerald-400" />}
          <span className="text-[10px]">{isMuted ? 'Muted' : 'Audio On'}</span>
        </button>
      </div>

      {/* Wheel Assembly */}
      <div className="relative w-72 h-72 sm:w-84 sm:h-84 md:w-96 md:h-96 flex items-center justify-center my-2">
        {/* Top Needle Indicator */}
        <div className="absolute -top-4 z-30 flex flex-col items-center pointer-events-none filter drop-shadow-[0_4px_8px_rgba(0,0,0,0.8)]">
          <div className="w-6 h-8 bg-gradient-to-b from-amber-400 to-amber-600 clip-arrow shadow-lg border border-amber-300"></div>
          <div className="w-3 h-3 rounded-full bg-white -mt-1 shadow-sm"></div>
        </div>

        {/* Outer Glowing Chrome Bezel */}
        <div className="absolute inset-0 rounded-full border-4 border-amber-500/40 p-1.5 shadow-[0_0_40px_rgba(245,158,11,0.25)]">
          <div className="w-full h-full rounded-full border-2 border-slate-700 bg-slate-900 shadow-inner flex items-center justify-center">
            {/* Rotating Wheel Canvas / SVG */}
            <div
              className="w-full h-full rounded-full relative overflow-hidden transition-transform ease-out"
              style={{
                transform: `rotate(${rotationAngle}deg)`,
                transitionDuration: animating ? '4000ms' : '0ms',
                transitionTimingFunction: 'cubic-bezier(0.15, 0.85, 0.25, 1)',
              }}
            >
              <svg viewBox="0 0 100 100" className="w-full h-full transform -rotate-90">
                {eligibleLots.length === 0 ? (
                  <circle cx="50" cy="50" r="48" fill="#1e293b" />
                ) : (
                  eligibleLots.map((lot, idx) => {
                    const startAngle = idx * sliceAngle;
                    const endAngle = (idx + 1) * sliceAngle;
                    const startRad = (startAngle * Math.PI) / 180;
                    const endRad = (endAngle * Math.PI) / 180;

                    const x1 = 50 + 48 * Math.cos(startRad);
                    const y1 = 50 + 48 * Math.sin(startRad);
                    const x2 = 50 + 48 * Math.cos(endRad);
                    const y2 = 50 + 48 * Math.sin(endRad);

                    const largeArc = sliceAngle > 180 ? 1 : 0;
                    const pathData = `M 50 50 L ${x1} ${y1} A 48 48 0 ${largeArc} 1 ${x2} ${y2} Z`;

                    return (
                      <path
                        key={lot.id}
                        d={pathData}
                        fill={sliceColors[idx % sliceColors.length]}
                        stroke="#0f172a"
                        strokeWidth="0.8"
                        opacity={0.88}
                      />
                    );
                  })
                )}
              </svg>

              {/* Player Labels on Segments */}
              {eligibleLots.map((lot, idx) => {
                const angle = idx * sliceAngle + sliceAngle / 2;
                return (
                  <div
                    key={lot.id}
                    className="absolute top-1/2 left-1/2 origin-left text-white text-[10px] sm:text-xs font-bold whitespace-nowrap pl-8 select-none pointer-events-none drop-shadow-md"
                    style={{
                      transform: `rotate(${angle}deg) translateY(-50%)`,
                      width: '45%',
                    }}
                  >
                    <span className="truncate max-w-[100px] inline-block font-sans">
                      #{lot.lotNumber} {lot.player?.displayName || lot.player?.fullName || `Lot ${lot.lotNumber}`}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* Center Hub & Spin Button */}
        <div className="absolute z-20">
          <button
            onClick={handleSpinClick}
            disabled={animating || !canSpin || eligibleLots.length === 0}
            className={`w-18 h-18 sm:w-20 sm:h-20 rounded-full font-black text-xs uppercase tracking-wider flex flex-col items-center justify-center shadow-2xl transition transform active:scale-95 ${
              animating
                ? 'bg-amber-500 text-slate-950 animate-pulse cursor-wait'
                : canSpin && eligibleLots.length > 0
                ? 'bg-gradient-to-tr from-amber-500 to-amber-300 text-slate-950 hover:scale-105 shadow-amber-500/40 border-2 border-white'
                : 'bg-slate-800 text-slate-500 cursor-not-allowed border border-slate-700'
            }`}
          >
            {animating ? (
              <RefreshCw size={22} className="animate-spin text-slate-950" />
            ) : (
              <>
                <Sparkles size={16} className="text-slate-950 mb-0.5" />
                <span className="leading-tight">SPIN</span>
              </>
            )}
          </button>
        </div>
      </div>

      {/* Eligible Lot count indicator */}
      <div className="mt-4 text-center z-10">
        <p className="text-xs text-slate-400">
          {eligibleLots.length > 0 ? (
            <>
              <strong className="text-emerald-400 font-bold">{eligibleLots.length}</strong> eligible player lots in the auction pool
            </>
          ) : (
            <span className="text-rose-400 font-medium">All lots completed or none pending</span>
          )}
        </p>
      </div>

      <style jsx>{`
        .clip-arrow {
          clip-path: polygon(50% 100%, 0 0, 100% 0);
        }
      `}</style>
    </div>
  );
}
