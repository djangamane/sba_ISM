# Spiritual Bible Chat App – Architecture Blueprint

## 1. Overview
The system delivers a personalized, AI-assisted spiritual experience while preserving user privacy and ensuring cross-platform reach. Architecture is divided into three main layers:

1. **Client (Flutter Mobile App)** – Provides onboarding, daily content, chat UX, and streak gamification. Handles local caching, offline reading, and notification scheduling.
2. **Application Backend** – Acts as a secure middle layer for AI requests, content management, subscription validation, and analytics hooks.
3. **External Services** – OpenAI for language generation, Firebase suite for auth/notifications/storage, RevenueCat for subscriptions, optional Bible content APIs.

## 2. Mobile Client
- **Framework**: Flutter 3.x, targeting iOS & Android. Declarative UI with adaptive theming (light/dark). Uses Riverpod for state management.
- **Modules**:
  - `onboarding`: dynamic quiz + personalization logic.
  - `today`: daily verse card, streak status, share actions.
  - `chat`: conversational UI, message persistence, retry handling.
  - `paywall`: subscription upsell, free-trial messaging.
  - `profile`: streak history, badges, settings, account prefs.
- **Local Storage**:
  - `shared_preferences` for lightweight flags (quiz completion, notification time).
  - `Hive` (encrypted box) for chat transcript cache and verse backlog.
  - `flutter_secure_storage` for auth tokens and RevenueCat app user ID.
- **Networking**: `dio` with interceptors for auth headers, rate limit handling, exponential backoff.
- **Notifications**: `flutter_local_notifications` (device-scheduled daily inspiration) + FCM background handler for remote campaigns.

## 3. Backend Services
- **Runtime**: Node.js 20 + Express (fastify option for future performance).
- **Responsibilities**:
  - Authenticate requests (Firebase Auth token validation when signed-in).
  - Enforce daily usage limits for free tier (`userId + date` counters in Firestore/Redis).
  - Proxy GPT requests with system prompt injection + conversation context trimming.
  - Optional retrieval augmentation using embeddings and a vector store (Pinecone/Weaviate) seeded with Neville Goddard libraries + key scriptures.
  - Serve daily content feed (verse of day, affirmations) from CMS/Firestore.
  - Webhooks for RevenueCat subscription events to update entitlements.
  - Trigger push campaigns (via Firebase Cloud Messaging) for streak nudges.
- **Data Stores**:
  - Firestore collections: `users`, `preferences`, `streaks`, `usageCounters`, `dailyContent`, `badges`.
  - Cloud Storage: pre-rendered share images, audio devotionals (premium).
  - Optional Redis: rate limiting + ephemeral chat context caching.

## 4. AI Integration
- **Provider**: OpenAI GPT-4o (primary) with GPT-3.5-turbo fallback.
- **Prompt Strategy**:
  - System prompt seeds assistant persona (Neville-aligned, scripture grounded, empathetic).
  - Conversation payload includes last 6–8 turns to preserve context.
  - Retrieval layer optionally injects top 2–3 relevant passages (Bible + Neville) using embeddings (OpenAI `text-embedding-3-large`).
- **Safety**:
  - Pre-check user input with OpenAI Moderation API.
  - Post-process responses to ensure scripture references exist when promised; fallback to templated encouragement otherwise.
  - Guardrails for non-spiritual requests (redirect kindly).

## 5. Subscriptions & Monetization
- **Strategy**: Freemium with soft gate; Paywall triggered on usage limit, accessible via profile.
- **Implementation**:
  - RevenueCat entitlements: `premium_monthly`, `premium_annual` with 7-day trial.
  - App identifies user via RevenueCat `AppUserID` (anonymous until optional sign-in).
  - Backend uses RevenueCat webhooks to mirror entitlement status into Firestore for quick lookups and targeted messaging.

## 6. Notifications & Engagement
- **Daily Inspiration**: Local scheduled notification at user-selected time, preloaded with verse snippet. Offline safe (verses cached one week ahead).
- **Re-engagement**: Backend-driven FCM pushes for streak risk (e.g., after 20 hours idle) respecting user consent and quiet hours.
- **A/B Testing**: Future integration with Firebase Remote Config to tweak paywall copy, notification tone, verse selection weighting.

## 7. Analytics & Telemetry
- Firebase Analytics: funnels (onboarding completion, chat usage, paywall views → trial starts → conversions).
- Crashlytics: monitor stability across devices.
- Privacy-first logging: no chat content stored in analytics; only metadata (length, response latency).
- Optional Mixpanel segmenting advanced cohorts (Devoted Learner vs New Explorer) using onboarding tags.

## 8. Security & Privacy Controls
- All network traffic over HTTPS/TLS 1.2+.
- Minimize PII collection: default anonymous, optional sign-in for sync; GDPR-compliant deletion path.
- Chat transcripts stored locally only unless user opts-in for cloud sync (future feature).
- Secrets managed via backend environment vars + secure storage on device; no API keys bundled in app.
- Regular dependency audits (`flutter pub outdated`, `npm audit`).

## 9. Deployment Pipeline
- **CI/CD**: GitHub Actions workflows
  - `ci_mobile`: lint (`flutter analyze`), tests (`flutter test`), build (debug APK/IPA artifacts).
  - `ci_backend`: lint (`eslint`), unit tests (`vitest/jest`), deploy via `gcloud functions deploy` or similar on main branch.
- **Release**: Tag-based release triggers build pipelines, upload to App Store Connect / Play Console via Fastlane.

## 10. Future Extensions
- Guided audio meditations (premium) streamed via CDN.
- Journaling module syncing to Firestore with optional export.
- Community prayer circles with opt-in sharing (requires new moderation tooling).
- Web companion app (Flutter Web) leveraging same backend.

This document will evolve as implementation details solidify. Contributions should update the relevant sections when architecture decisions change.
