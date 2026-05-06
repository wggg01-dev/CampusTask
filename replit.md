# CampusTask

A Flutter + Supabase fintech app that lets students earn money by completing tasks (surveys, offerwalls).

## Tech Stack

- **Framework**: Flutter (Dart 3.10)
- **Backend / Auth**: Supabase
- **Font**: Plus Jakarta Sans (via Google Fonts)
- **Theme**: Deep Navy (#0F172A) + Emerald Green (#10B981), Material 3 dark

## Project Structure

```
lib/
  main.dart                     # App entry point, ThemeData, CampusTaskApp, AuthGate → MainScreen
  screens/
    main_screen.dart            # Bottom nav shell: Home (0) · Tasks (1) · Leaderboard (2)
    home_tab.dart               # Balance card + ₦2000 progress bar + Withdraw + Invite + Quick Tasks preview
    tasks_screen.dart           # Full task list with search, task cards, Open/Submit Proof buttons
    leaderboard_screen.dart     # Referral code + stats + copy/share + Top 10 rankings
    rules_screen.dart           # One-time rules gate + How It Works (6-step How-To)
    login_screen.dart           # Email/password login via Supabase
    signup_screen.dart          # Registration + optional referral code pre-fill
    bank_setup_screen.dart      # Payout settings — bank name, code, account number → profiles table
    payout_history_screen.dart  # Real-time withdrawal history streamed from payouts table
    spin_wheel_screen.dart      # Daily spin wheel with animated CustomPainter wheel + Supabase reward crediting
    withdraw_screen.dart        # Withdrawal screen with ₦2000 minimum check and ₦50 fee deduction
    profile_screen.dart         # User profile, bank setup access, logout
pubspec.yaml                    # Dependencies
```

## Supabase Tables

- `profiles` — user profile + bank details + referral data
  - `id`, `bank_account_number`, `bank_code`, `bank_name`, `ref_code`
  - `available_balance_ngn`, `pending_balance_ngn`
  - `has_accepted_rules`, `rules_accepted_at`
- `payouts` — withdrawal records (real-time stream)
- `tasks` — active tasks (`is_active`, `priority_level`, `slots_left`, `task_url`, `form_url`)
- `referral_stats` — SQL view: `id`, `referral_count`, `referral_earnings_ngn` (used by leaderboard)

## Key Dependencies

- `supabase_flutter: ^2.3.0` — Auth + real-time database
- `google_fonts: ^6.2.1` — Plus Jakarta Sans typography
- `share_plus: ^10.0.0` — Native share sheet for referral links
- `app_links: ^6.0.0` — Deep link handling (referral URL → signup pre-fill)

## Auth Flow

`AuthGate` → `_RulesGate` (checks `has_accepted_rules`):
- Rules not accepted → `RulesScreen` (on accept → pushReplacement to `MainScreen`)
- Rules accepted → `MainScreen` (bottom nav shell)
- No session → `LoginScreen`

Deep links (`campustask.app/signup?ref=CODE`) handled in `main.dart` via `app_links`.

## Architecture decisions

- **IndexedStack** in MainScreen preserves tab state across navigation
- **HomeTab** takes `onNavigate(int)` callback so Quick Tasks "See All" and Invite banner can switch tabs without re-mounting
- Referral block removed from Home — lives exclusively on Leaderboard for contextual growth hook
- Tasks have `task_url` + `form_url` columns — "Open App" and "Submit Proof" buttons shown only when non-null
- `referral_stats` is a Supabase view queried for both user's own stats and the top-10 leaderboard

## Product

- Home: live balance, ₦2,000 withdrawal progress bar, Withdraw + History, Invite banner, Quick Tasks preview
- Tasks: searchable full task list with HOT badge, payout, slots, and action buttons
- Leaderboard: referral code copy/share, personal referral stats, top 10 earners with gold/silver/bronze medals
- Rules: rules gate with How It Works 6-step guide (shown once on first login)

## User preferences

- No clutter — each screen has one clear purpose
- Referral logic lives on Leaderboard, not Dashboard
- ₦2,000 progress bar on home balance card

## Gotchas

- `referral_count` and `referral_earnings_ngn` read from `profiles` stream in LeaderboardScreen — ensure these columns exist on profiles OR refactor to query `referral_stats` filtered by user id
- `dashboard_screen.dart` still exists but is no longer used — safe to delete
