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
  main.dart                  # App entry point, ThemeData, CampusTaskApp, AuthGate
  screens/
    login_screen.dart        # Email/password login via Supabase
    dashboard_screen.dart    # Balance card + task list
    bank_setup_screen.dart      # Payout settings — bank name, code, account number → profiles table
    payout_history_screen.dart  # Real-time withdrawal history streamed from payouts table
pubspec.yaml                 # Dependencies
```

## Supabase Tables

- `profiles` — stores user profile + bank details
  - `id` (FK → auth.users), `bank_account_number`, `bank_code`, `bank_name`
- `payouts` — withdrawal records (real-time stream)
  - `id`, `user_id` (FK → auth.users), `amount_ngn`, `status` (sent | pending), `created_at`

## Key Dependencies

- `supabase_flutter: ^2.3.0` — Auth + real-time database
- `google_fonts: ^6.2.1` — Plus Jakarta Sans typography

## Auth Flow

`AuthGate` listens to Supabase's `onAuthStateChange` stream:
- Session exists → `DashboardScreen`
- No session → `LoginScreen`

## Environment Variables

Set these before running (via `--dart-define` or your environment):
- `SUPABASE_URL` — Your Supabase project URL
- `SUPABASE_ANON_KEY` — Your Supabase anonymous key

## Planned Features

- Real-time balance from Supabase
- Offerwall / task integration
- Withdrawal flow
