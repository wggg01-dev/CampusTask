# CampusTask

A Flutter + Supabase fintech app that lets students earn money by completing tasks (surveys, offerwalls).

## Tech Stack

- **Framework**: Flutter (Dart 3.10)
- **Backend / Auth**: Supabase (Auth + Realtime + Edge Functions)
- **Font**: Plus Jakarta Sans (via Google Fonts)
- **Theme**: Deep Navy (#0F172A) + Emerald Green (#10B981), Material 3 dark

## Project Structure

```
lib/
  main.dart                     # App entry, AuthGate → _OnboardingGate (reactive StreamBuilder chain)
  screens/
    main_screen.dart            # Bottom nav shell: Home (0) · Tasks (1) · Leaderboard (2)
    home_tab.dart               # Balance card + ₦2000 progress bar + Withdraw + Invite + Quick Tasks preview
    tasks_screen.dart           # Full task list with search + smart Complete button
    leaderboard_screen.dart     # Referral code + stats + copy/share + Top 10 rankings
    signup_screen.dart          # Registration: email/pass + full bio-data (name, age, gender, phone, location) + optional ref code
    bio_data_screen.dart        # Bio-data collection for users who reach the gate without it
    otp_screen.dart             # 4-digit WhatsApp OTP verification with resend timer
    rules_screen.dart           # One-time rules gate + How It Works (5-step guide)
    login_screen.dart           # Email/password login via Supabase
    bank_setup_screen.dart      # Payout settings — bank name, code, account number → profiles table
    payout_history_screen.dart  # Real-time withdrawal history streamed from payouts table
    spin_wheel_screen.dart      # Daily spin wheel modal (not a screen) with countdown timer
    withdraw_screen.dart        # Withdrawal screen with ₦2000 minimum check and ₦50 fee deduction
    profile_screen.dart         # User profile, referral stats, logout
pubspec.yaml                    # Dependencies
```

## Onboarding Gate Chain (all reactive via StreamBuilder on profiles)

```
AuthGate (session?) → _OnboardingGate → [checks in order]
  1. full_name empty?       → BioDataScreen
  2. phone_verified = false? → OtpScreen(phone)
  3. has_accepted_rules = false? → RulesScreen
  4. all good              → MainScreen
```
Each screen just updates the DB. The StreamBuilder re-evaluates and navigates automatically — no explicit pushReplacement needed.

## Supabase Tables

- `profiles` — user profile + bank details + referral + bio-data
  - `id`, `ref_code`, `referred_by`, `available_balance_ngn`, `pending_balance_ngn`
  - `full_name`, `age`, `gender`, `phone`, `location` — bio-data (required for task completion)
  - `phone_verified` (bool), `has_accepted_rules` (bool), `rules_accepted_at`
- `payouts` — withdrawal records (real-time stream)
- `tasks` — active tasks (`id`, `is_active`, `priority_level`, `slots_left`, `task_url`, `description`)
- `task_submissions` — auto-submitted bio-data for tasks with no URL
  - `user_id`, `task_id`, `full_name`, `age`, `gender`, `phone`, `location`, `submitted_at`
- `referral_stats` — SQL view: `id`, `referral_count`, `referral_earnings_ngn`

## Edge Functions Required

- `send-whatsapp-otp` — sends 4-digit code to phone via WhatsApp Business API
- `verify-whatsapp-otp` — verifies OTP, body: `{otp, phone}`
- `daily-spin` — handles spin reward logic
- `handle-referral` — credits referrer on new signup

## Key Dependencies

- `supabase_flutter: ^2.3.0` — Auth + real-time database + edge functions
- `google_fonts: ^6.2.1` — Plus Jakarta Sans typography
- `share_plus: ^10.0.0` — Native share sheet for referral links
- `app_links: ^6.0.0` — Deep link handling (referral URL → signup pre-fill)
- `url_launcher: ^6.3.0` — Opens task URLs in external browser

## Complete Button Logic (tasks_screen.dart)

1. Check `_bioComplete` (full_name in profile) — if missing, show lock dialog
2. If `task_url` is set → `launchUrl` (external browser)
3. If no `task_url` → upsert bio-data to `task_submissions` table

## User preferences

- No clutter — each screen has one clear purpose
- Referral logic lives on Leaderboard, not Dashboard
- ₦2,000 progress bar on home balance card
- Spin wheel is a bottom sheet modal, not a screen
- OTP sent via WhatsApp (green branding, not SMS)

## Gotchas

- `_OnboardingGate` uses StreamBuilder — all screens in the gate must NOT push/replace manually; they just update the DB
- `url_launcher` must be added to Android/iOS manifests for external URL queries (`<queries>` intent in AndroidManifest.xml)
- `task_submissions` table must be created in Supabase before the bio-data submit workflow works
- `dashboard_screen.dart` still exists but is no longer used — safe to delete
