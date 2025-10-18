# Project Status – Spiritual Bible Chat

_Last updated: 2024-10-12_

## Completed to Date
- **Architecture & Docs**: Root README plus `docs/architecture.md`, `product-roadmap.md`, and `qa-plan.md` outline vision, milestones, QA, and tech stack.
- **Backend (Node/Express + TypeScript)**
  - `GET /api/health` health probe.
  - `POST /api/v1/chat` proxied OpenAI Assistant conversation with thread persistence.
  - `POST /api/v1/devotional` generates verse-focused devotionals via OpenAI.
  - `.env.example` documents required secrets.
  - Supabase JWT auth middleware, rate limiting, and usage logging (chat/devotional endpoints).
- **Supabase Database**
  - Tables created: `profiles`, `streaks`, `devotional_cache`, `reminder_events` with RLS policies.
- **Flutter Mobile Client**
  - Navigation shell for Today / Chat / Progress / Profile.
  - Onboarding quiz with SharedPreferences persistence.
  - GPT chat UI integrated with backend including "Reflect with AI" flow.
  - Daily devotional screen calling backend endpoint.
  - Streak tracking, reminder scheduling, and presentation across screens.
  - Local notification scheduling stub using `flutter_local_notifications`.
  - Supabase auth gate with email/password + continue-as-guest option.
  - `.env.example` for mobile + dotenv / `--dart-define` support.
- **Tooling / Utilities**
  - `NotificationService` wrapper (timezone aware, tap stream).
  - `reminders.dart` helper for next reminder calculation.
  - `PreferencesService` for local caching.
  - Project READMEs updated with Supabase + web run instructions.

## Workflows / Terminal Setup
- **Terminal 1 – Backend API**
  ```bash
  cd backend
  npm install     # first run only
  npm run dev     # listens on http://localhost:4000
  ```
- **Terminal 2 – Flutter Client**
  ```bash
  cd mobile/spiritual_bible_chat
  flutter pub get
  flutter run -d <device>
  # For web builds supply Supabase credentials:
  flutter run -d chrome \
    --dart-define=SUPABASE_URL=https://<project>.supabase.co \
    --dart-define=SUPABASE_ANON_KEY=<anon-key>
  ```
- **Terminal 3 – Android Studio / Emulator (optional)**
  - Launch Android Studio or `flutter emulators --launch <id>` for device management.
  - Accept notification permission prompts (Android 13+).

## Outstanding Tasks
1. **Paywall & Entitlements**
   - Introduce premium gating in Flutter and backend enforcement.
   - Integrate Stripe-based subscription record with Supabase sync.
2. **Notification Enhancements**
   - Hook Supabase cron / cloud functions for server-driven reminders.
   - Deep link notification taps into contextual screens.
3. **Testing & QA**
   - Expand unit/widget tests for onboarding, chat, streaks.
   - Add API integration tests and lint/CI automation.
4. **UX / Content Polish**
   - Apply design tokens, animations, and copy review.
   - Implement adjust reminders UI to handle timezone edge cases & multi-device sync.
5. **Analytics & Observability**
   - Add Firebase Analytics or Supabase logs dashboard.

## Running Checklist
- [ ] Supabase `.env` populated (mobile) or `--dart-define` flags provided for web.
- [ ] Backend `.env` filled with OpenAI credentials.
- [ ] All three terminals running (`backend`, `flutter`, optional emulator).
- [ ] Local notifications permission granted on device.
- [ ] Test chat/devotional endpoints after each restart.

## Notes / Next Planning Session
- Decide on authentication UX (magic link, OAuth, passwordless).
- Outline data migration strategy once Supabase sync is live.
- Evaluate push notification provider (FCM, OneSignal) once server-driven reminders are required.
- Revisit roadmap milestones in `docs/product-roadmap.md` after Supabase integration is complete.
