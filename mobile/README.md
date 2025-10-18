# Spiritual Bible Chat Mobile App

This directory hosts the Flutter client source in `spiritual_bible_chat/`. The project is already scaffolded with an initial navigation shell that mirrors the PRD flows (Today, Chat, Progress, Profile tabs).

## Local Setup Prerequisites
1. [Install Flutter](https://docs.flutter.dev/get-started/install) 3.19 or newer.
2. Ensure Android Studio + Android SDK command-line tools are installed (`flutter doctor` should show ✅ for the Android toolchain). Linux desktop toolchain packages are optional unless you target desktop builds.

## Running the App
```bash
cd mobile/spiritual_bible_chat
flutter pub get        # redundant after clone but safe
flutter run            # chooses a connected device/emulator

# For web builds, provide Supabase credentials via dart-define.
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

To run with a specific device, pass `-d <device-id>`; list available devices via `flutter devices`.
Ensure the backend dev server is running at `http://localhost:4000` (or `10.0.2.2` from Android emulators) so the chat screen can reach the OpenAI assistant. When targeting the hosted backend, set `API_BASE_URL` in `.env` (or pass `--dart-define=API_BASE_URL=https://sba-ism.onrender.com`).

### Web Build & Vercel Deployment
1. Enable Flutter web support (once): `flutter config --enable-web`.
2. Build the web bundle: `flutter build web --release`.
3. The output lives in `build/web/`. For Vercel, use the root build command `bash scripts/build_web.sh` and set the output directory to `mobile/spiritual_bible_chat/build/web`.
4. Expose runtime configuration on Vercel:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `API_BASE_URL`
   - `STRIPE_PUBLISHABLE_KEY`
5. After deploy, verify the hosted site on desktop and mobile browsers (Lighthouse, responsive layouts) and confirm premium gating hits the production backend.

### Notifications
- Android: Accept the runtime notification permission prompt (Android 13+). The manifest already declares `POST_NOTIFICATIONS`.
- iOS: Update `Info.plist` with `NSUserNotificationUsageDescription` when enabling real notifications.
- Current implementation schedules local notifications via `flutter_local_notifications`; push delivery can be layered on later.

## Project Overview
- `lib/main.dart` – navigation shell, streak tracker wiring, Supabase-aware auth hooks.
- `lib/auth/` – Supabase auth gate + sign-in screen components.
- `lib/screens/onboarding/onboarding_flow.dart` – multi-step onboarding quiz with personalization storage.
- `lib/screens/devotional/devotional_screen.dart` – daily devotional experience powered by the backend assistant.
- `lib/utils/reminders.dart` – reminder scheduling helpers used by the notification stub.
- `lib/services/notification_service.dart` – local notification bootstrap/scheduling wrapper.
- `pubspec.yaml` – dependencies (Flutter SDK + Supabase, notifications, etc.).
- `test/` – sample widget test; expand with real coverage as features land.

## Supabase Setup
1. Create a Supabase project and capture the project URL + anon (publishable) key.
2. Run the SQL migration provided earlier to create the `profiles`, `streaks`, `devotional_cache`, and `reminder_events` tables with row-level security policies.
3. Copy `.env.example` to `.env` inside `mobile/spiritual_bible_chat/` and populate `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL`, and `STRIPE_PUBLISHABLE_KEY`.
4. Create user accounts via Supabase Auth or the in-app “Create account” button. A “Continue as guest” option remains for local-only testing.

## Next Mobile Milestones
- Wire onboarding flow and persistent user preferences.
- Implement chat data layer (linking to backend proxy once available).
- Add theming tokens + component library per design system.
- Integrate analytics and feature flags.
