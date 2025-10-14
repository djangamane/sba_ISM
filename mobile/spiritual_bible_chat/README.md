# Spiritual Bible Chat – Flutter Client

The Flutter application implements the Spiritual Bible Chat experience described in the PRD. The current state provides a navigation scaffold with placeholder content for Today, Chat, Progress, and Profile tabs.

## Prerequisites
- Flutter 3.22.x (stable channel)  
- Android SDK + command line tools (for mobile builds)  
- Optional: `clang`, `ninja-build`, `libgtk-3-dev` for Linux desktop support  

Verify with:
```bash
flutter doctor
```

## Getting Started
```bash
flutter pub get
flutter run

# For web: supply Supabase credentials via dart-define
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Useful commands:
- `flutter analyze` – static analysis
- `flutter test` – run unit/widget tests
- `flutter run -d chrome` – run in a Chrome web instance

## Project Structure Highlights
```
lib/
  models/
    onboarding_profile.dart   # Data model + enum helpers for personalization
    streak_state.dart         # Streak progress tracking model
  utils/
    api_base.dart             # Platform-aware API base URL helper
    reminders.dart            # Stubbed reminder scheduling helpers
  services/
    notification_service.dart # Local notifications bootstrap/scheduling wrapper
  auth/
    auth_gate.dart            # Supabase auth wrapper
    sign_in_screen.dart       # Email/password + guest access UI
  screens/onboarding/
    onboarding_flow.dart      # Five-step onboarding experience
  screens/devotional/
    devotional_screen.dart    # Verse-driven devotional experience
  main.dart          # App theme + navigation shell + placeholder screens
test/
  widget_test.dart   # Example test (replace with real coverage)
```

## Roadmap Snapshot
- Implement onboarding quiz and persistence.
- Integrate backend chat proxy + message list UI.
- Add streak tracker, achievements, and analytics instrumentation.
- Introduce feature flag/config service for paywall and content experiments.
