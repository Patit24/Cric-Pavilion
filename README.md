# 🏏 CricPavilion Pro — Cricket Tournament Management, Live Scoring & Franchise Player Auction Platform

**CricPavilion Pro** is an end-to-end cricket tournament platform inspired by **CricHeroes** and **Cricbuzz**, featuring an integrated IPL-style franchise player auction system with spinning wheel selection, real-time bidding, automatic squad assignments, team purse deduction, and a ball-by-ball cricket scoring engine.

---

## 🌟 Key Features & Tournament Lifecycle

1. **Tournament Creation & Rules Configuration**:
   - 7-Step Wizard: Basic Information, Competition Format (Round-Robin, Knockout, Groups), Match Rules (Overs, Squad limits, Powerplays), Registered Franchises, Auction Configuration, and Automated Fixtures Scheduling.
2. **Franchise Player Auction System**:
   - **Interactive Spinning Wheel**: Server-authoritative random selection from eligible player lots with smooth deceleration, tick audio feedback, and spotlight reveals.
   - **Live Real-time Bidding**: Server-authoritative bid validation, tiered increments, squad-size limit checks, and purse protection.
   - **Live Countdown Timer**: 20-second dynamic countdown timer resetting on valid incoming bids.
   - **Automatic Squad Assignment & Purse Deduction**: When a player is sold, the system atomically deducts the purse from the winning franchise, records the transaction in the financial ledger, assigns the player to the team's tournament roster, and updates squad stats.
   - **Cinematic Presentation Modes**: Dedicated Organizer Control Room, Team Owner Bidding Console, Team Purse Dashboard, and full-screen TV / Projector Display mode.
3. **Ball-by-Ball Live Cricket Scoring Engine**:
   - **Rule-Aware Cricket Logic**: Dot balls, singles, boundaries (4s), sixes, wides, no-balls, byes, leg-byes, penalties.
   - **Dismissal Handling**: Bowled, Caught, Caught & Bowled, LBW, Stumped, Hit Wicket (credited to bowler) vs Run Out, Timed Out, Retired Out (not credited to bowler).
   - **Automatic Strike Rotation**: Batter runs, boundary retention, odd-run overthrows, and automatic end-of-over strike rotation.
   - **Scorecard Generation**: Real-time batting scorecards (runs, balls, 4s, 6s, SR), bowling figures (overs, maidens, runs conceded, wickets, economy, dots), partnerships, and fall-of-wickets.
   - **One-Tap Reliable Undo**: Instant delivery reversal recalculating all scorecards and overs accurately.
4. **Standings & Official Net Run Rate (NRR)**:
   - League points table with automatic ranking.
   - **Official ICC / BCCI All-Out Quota Rule**: If a team is bowled out (all out) inside their allocated overs, the full quota of overs ({e.g., 20.0}) is used as the divisor for NRR calculation rather than the truncated overs.
5. **Instant Identity & Role Simulator**:
   - Built-in floating role-switcher widget allowing users and evaluators to test as:
     - **Tournament Organizer** (Debasish Dutta)
     - **Franchise Owner: Barasat Blasters** (Arijit Mukherjee — Purse: ₹68.5L)
     - **Franchise Owner: Kolkata Knights** (Sanjiv Goenka — Purse: ₹72.0L)
     - **Official BCCI Match Scorer** (Pritam Saha)
     - **Public Spectator**
     - **Super Administrator**

---

## 🛠️ Technology Stack

- **Framework**: Next.js 14 (App Router, Server & Client Components)
- **Language**: TypeScript (Strict typing across domain models)
- **Styling**: Tailwind CSS with custom cricket-inspired green, dark navy typography, and stadium gold
- **Icons**: Lucide React
- **Animations & Effects**: Custom CSS Keyframes, Canvas-Confetti, Web Audio API sound synthesizer
- **Backend & Database**:
  - Full PostgreSQL DDL schema with Foreign Keys, Constraints, and Indexes (`supabase/schema.sql`)
  - Atomic Stored Procedures & Concurrency Control (`supabase/functions.sql`)
  - Row Level Security (RLS) Policies (`supabase/rls.sql`)
  - Full local ACID persistence with dual-mode Supabase client (`src/lib/store/mock-db.ts` & `src/lib/supabase/client.ts`)
- **Testing**: Vitest automated test suite covering cricket rules, strike rotation, NRR, auction bidding, and purse transactions.

---

## 🚀 Getting Started

### 1. Install Dependencies
```bash
npm install
```

### 2. Run Automated Test Suite
```bash
npm run test
```
All 16 unit and integration test cases will run and verify cricket rules, strike rotation, all-out NRR calculations, and atomic auction validations.

### 3. Run Development Server
```bash
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) in your browser.

### 4. Build for Production
```bash
npm run build
npm run start
```

---

## 📁 Project Structure

```
├── src/
│   ├── app/
│   │   ├── page.tsx                       # Home landing & live match ticker
│   │   ├── layout.tsx                     # Global layout & sports navigation
│   │   ├── auctions/
│   │   │   ├── page.tsx                   # Auctions directory & team purse cards
│   │   │   └── [id]/
│   │   │       ├── page.tsx               # Main Auction Stage (Wheel + Bidding)
│   │   │       ├── display/page.tsx       # Fullscreen Projector / TV mode
│   │   │       ├── control/page.tsx       # Organizer Control Room
│   │   │       └── purse/page.tsx         # Detailed Team Purses & Squad Rosters
│   │   ├── matches/
│   │   │   ├── page.tsx                   # Fixtures & live match directory
│   │   │   └── [id]/page.tsx              # Public Match Centre (5 live tabs)
│   │   ├── scorer/
│   │   │   └── page.tsx                   # Mobile-first Scorer Console
│   │   ├── tournaments/
│   │   │   ├── page.tsx                   # Tournaments directory
│   │   │   └── [id]/standings/page.tsx    # Points Table & ICC NRR
│   │   ├── organizer/
│   │   │   ├── page.tsx                   # Organizer Hub
│   │   │   └── tournaments/new/page.tsx   # 7-Step Tournament Wizard
│   │   ├── teams/
│   │   │   ├── page.tsx                   # Teams directory
│   │   │   └── [id]/page.tsx              # Team profile & auction purchases
│   │   ├── players/
│   │   │   ├── page.tsx                   # Verified talent registry
│   │   │   └── [id]/page.tsx              # Player career statistics
│   │   └── api/
│   │       ├── auction/                   # Atomic bid, sold, and spin routes
│   │       └── scoring/                   # Ball-by-ball delivery & undo routes
│   ├── components/
│   │   ├── Navbar.tsx                     # Responsive navigation with live ticker
│   │   ├── RoleSwitcher.tsx               # Quick role switcher simulator
│   │   ├── auction/
│   │   │   ├── SpinningWheel.tsx          # Interactive SVG/Canvas wheel
│   │   │   ├── PlayerRevealCard.tsx       # Spotlight player reveal card
│   │   │   ├── BiddingConsole.tsx         # Real-time bidding & countdown
│   │   │   └── SoldAnimation.tsx          # Confetti & gavel announcement
│   │   └── scorer/
│   │       └── ScoringKeypad.tsx          # Large runs buttons, extras, wickets
│   ├── lib/
│   │   ├── types.ts                       # Complete domain TypeScript definitions
│   │   ├── cricket-engine/                # Pure cricket rules, scorecard & NRR
│   │   ├── auction-engine/                # Bidding validation & Web Audio SFX
│   │   └── store/                         # Local database & state manager
│   └── tests/                             # Vitest automated test suite
└── supabase/
    ├── schema.sql                         # PostgreSQL production table definitions
    ├── functions.sql                      # Atomic stored procedures
    └── rls.sql                            # Row Level Security policies
```

---

## 🔒 Concurrency & Financial Integrity

- **Purse Deductions**: A team's remaining purse can never be deducted twice for the same player lot.
- **Squad Limits**: Teams cannot exceed maximum squad size ({e.g., 18}). Funds are dynamically reserved to satisfy minimum squad requirements ({₹50,000 per missing slot}).
- **Self-Outbidding Prevention**: A franchise holding the current highest bid is blocked from bidding against itself.
- **Server Authority**: The browser UI never decides the winning player or bid amount independently; all states transition through authoritative logic.

---

## 📄 License
MIT License. Built for professional and community cricket tournament management.
