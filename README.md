# 🏏 CricPavilion Pro — Flutter Cross-Platform Cricket App
### Tournament Management, Live Ball-by-Ball Scoring & Franchise Player Auction

**CricPavilion Pro** is a complete, production-grade Flutter cross-platform application (iOS, Android, macOS, Web, Windows, Linux) inspired by **CricHeroes** and **Cricbuzz**, featuring an integrated franchise player auction with a spinning wheel, real-time bidding, team purse ledger, and a certified ball-by-ball cricket scoring engine.

---

## 🌟 App Modules & Features

### 1. 🏠 Home Screen & Cricket Scorecard Centre
- **Multi-Tab Scorecard Centre**:
  - 🔴 **Live Scoring Tab**:
    - Live match banner (e.g., Barasat Blasters vs Kolkata Kings).
    - Real-time score `142/2 (14.2 ov)`, Current Run Rate (CRR).
    - **Crease HUD**: Striker (runs, balls, 4s, 6s, SR, strike badge `★`) and Non-Striker details.
    - **Active Bowler HUD**: Overs, maidens, runs conceded, wickets, economy (`ECON`).
    - Quick actions: `Detailed Scorecard` and `Open Scorer Console`.
  - ✅ **Past Match Scoring Tab (Results)**:
    - Certified completed matches (e.g., Barasat Blasters vs Howrah Hurricanes).
    - Trophy banner: 🏆 **Barasat Blasters won by 24 runs**.
    - Innings 1 (172/5) & Innings 2 (148/8) side-by-side breakdowns.
    - Top batters and bowlers for both teams.
  - 📅 **Upcoming Fixtures Tab (Scheduled)**:
    - Fixture cards with venue, date, format (20 Overs T20), and competing squads.
    - Direct **`🪙 Conduct Toss & Start Scoring →`** button opening the 3-step Coin Toss Wizard!
- **Franchise Auction Highlight**: Lot reveal and one-tap jump to the live auction.

---

### 2. 🔴 Ball-by-Ball Scorer Console
- **3-Step Pre-Match Toss Wizard**:
  - Step 1: Coin Toss (Winner selection & Elected to Bat/Bowl).
  - Step 2: Opening Crease Lineup (Striker, Non-Striker, Opening Bowler).
  - Step 3: Direct launch into live scoring at Over 0.1.
- **Crease HUD (Heads-Up Display)**:
  - Batters Table: Striker with `★ Strike` badge, non-striker, Runs, Balls, 4s, 6s, Strike Rate (`SR`), and `Swap Ends` control.
  - Active Bowler Table: Overs, Maidens, Runs Conceded, Wickets, Economy (`ECON`), bowling style, and `Change Bowler`.
- **Strict Cricket Law Enforcement**:
  - **20.0 Overs Hard Cap**: Disallows deliveries once the 20-over quota is complete.
  - **ICC Law 17.8**: Prevents the same bowler from bowling consecutive overs.
  - **Bowler Quota Check**: Maximum 4 overs per bowler in a 20-over match.
  - **Automatic Over Complete Dialog**: Auto-prompts next bowler selection with consecutive lockout.
  - **2-Step Wicket Modal**:
    - Step 1: Dismissal mode (Caught + fielder picker, Run Out + thrower, Bowled, LBW, Stumped).
    - Step 2: Incoming batsman selection from the dugout (**already-dismissed batsmen are locked out!**).
- **Innings Automation**:
  - When 20.0 overs or 10 wickets are reached, Innings 1 automatically finishes, target runs are calculated (`Inn1 + 1`), and Innings 2 is unlocked with defending & chasing teams assigned.
- **Full Interactive Scorecard**: View detailed batting cards, extras, totals, and bowling figures for both innings.

---

### 3. 🔨 Franchise Player Auction Stage
- **Cinematic Dark Stadium Aesthetic**:
  - Stadium gold highlights, deep dark theme, and high-contrast typography.
- **Interactive Spinning Wheel**:
  - Custom-painted multi-color segments.
  - Realistic spin physics with friction & deceleration.
  - Dynamically selects and reveals incoming player lots.
- **Real-Time Bidding**:
  - Franchise selector dropdown.
  - Increments: `+₹25,000`, `+₹50,000`, `+₹1,00,000`.
  - Real-time bid log timeline with franchise names and amounts.
- **Auctioneer Controls**:
  - 🔨 **HAMMER SOLD**: Deducts purse from the winning franchise, increments team squad count, assigns player to roster, and advances to the next lot.
  - ❌ **UNSOLD (PASS)**: Marks player unsold and loads the next lot.
- **Franchise Purse Ledger**:
  - Real-time remaining purse balances (e.g. ₹85,00,000 / ₹1,00,00,000) with visual progress bars and squad sizes.

---

### 4. 🏏 Match Centre & Tournament Standings
- **Match Centre (`Matches`)**:
  - Filter pills for All, Live, Completed, and Scheduled matches.
  - Real-time score summaries, venue, and quick links.
- **Tournament Standings (`Standings`)**:
  - League Points Table with Played, Won, Lost, Points, and Net Run Rate (NRR) with color formatting.

---

## 🚀 Running the Flutter App

Ensure Flutter is in your PATH:
```bash
export PATH="/Users/patitpabanroy/Desktop/flutter/bin:$PATH"
```

### Run Tests:
```bash
flutter test
```

### Static Analysis:
```bash
flutter analyze
```

### Run the App on Connected Device (macOS / Chrome / Simulator / Phone):
```bash
flutter run
```
Or specify the target device:
```bash
flutter run -d chrome    # Run as Flutter Web
flutter run -d macos     # Run as macOS Desktop
```

---

## 📁 Flutter Project Architecture

```
lib/
├── main.dart                               # App entry point, MultiProvider & Bottom Navigation
├── models/
│   └── models.dart                         # Strongly-typed models (Tournament, Team, Player, Match, Innings, Delivery, Scorecard, Auction)
├── services/
│   ├── cricket_rules_engine.dart           # ICC Law 17.8, over format, bowler & batsman eligibility
│   └── mock_database.dart                  # ChangeNotifier reactive store with seed data & mutations
└── screens/
    ├── home_screen.dart                    # Scorecard Centre (Live, Past, Upcoming) & Auction Highlight
    ├── scorer/
    │   ├── scorer_screen.dart              # Ball-by-ball keypad, over summary, innings switcher
    │   ├── crease_hud_widget.dart          # Live Batters table & Bowler table with R, B, 4s, 6s, SR, O, M, R, W, ECON
    │   ├── toss_wizard_sheet.dart          # 3-Step Coin Toss & Opening Lineup wizard
    │   ├── over_complete_dialog.dart       # Automatic next bowler picker with Law 17.8 lockout
    │   ├── wicket_dialog.dart              # 2-Step dismissal & incoming dugout batsman selector
    │   └── full_scorecard_dialog.dart      # Fullscreen dual-innings scorecard modal
    ├── auction/
    │   └── auction_screen.dart             # Animated spinning wheel, bidding controls, purse ledger
    ├── matches/
    │   ├── matches_list_screen.dart        # Filterable fixtures and match scorecards
    │   └── match_detail_screen.dart        # Deep match details (Live crease, scorecard, commentary, squads)
    └── tournaments/
        └── tournament_standings_screen.dart# Points table with Net Run Rate (NRR)
```
