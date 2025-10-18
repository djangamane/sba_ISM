# Spiritual Bible Chat App (V1)

This repository hosts the codebase for the Spiritual Bible Chat App, an AI-assisted daily faith companion inspired by Neville Goddard's teachings. The first milestone is a dual-platform (iOS + Android) mobile experience that blends GPT-powered guidance with habit-forming spiritual practices.

## Vision
- Provide uplifting, scripture-rooted conversations tailored to each user.
- Encourage consistent daily reflection through verse prompts and streak mechanics.
- Deliver a premium-yet-accessible experience with a soft paywall monetization model.

## Core Pillars (V1)
1. **AI Chat Assistant** – GPT-driven spiritual mentor constrained to Bible + Neville Goddard context, with empathetic conversational tone.
2. **Dynamic Onboarding Quiz** – 5-question flow that personalizes content, tone, and notifications.
3. **Daily Verse & Prompts** – Verse/affirmation of the day with optional deep-dive via the AI and share actions.
4. **Streaks & Badges** – Light gamification reinforcing daily engagement without guilt.
5. **Soft Paywall** – Freemium model: limited daily chats for free tier, unlimited + premium content for subscribers.
6. **Calming UI** – Modern, cross-platform design with subtle spiritual motifs.

## Tech Stack (proposed)
| Area | Choice | Notes |
| --- | --- | --- |
| Mobile client | Flutter (Dart) | Single codebase, smooth animations, strong tooling |
| State management | Riverpod + Hooks | Scalable, testable state patterns |
| Networking | `dio` | Interceptors, retries, typed responses |
| Local storage | `shared_preferences`, `hive` | Preferences + lightweight offline cache |
| Notifications | `flutter_local_notifications`, Firebase Cloud Messaging | Local scheduling + remote campaigns |
| Auth & data sync | Firebase Authentication & Firestore | Optional account sync + personalization |
| Subscriptions | Stripe Billing | Hosted checkout + subscriptions |
| AI gateway | Custom server (Node.js/Express) | Proxy to OpenAI, enforce usage limits, retrieval augmentation |
| AI provider | OpenAI GPT-4 / GPT-3.5 | System prompt tuned to Neville’s teachings |

## High-Level Architecture
```
┌────────────┐       ┌────────────────┐       ┌───────────────┐
│  Flutter    │HTTP ↔│ Backend API    │↔ GPT  │  OpenAI API   │
│  Mobile App │      │ (Node.js)      │       │ (Chat / Mods) │
└────────────┘      └────────────────┘       └───────────────┘
      │                      │                        │
      │ Firebase SDKs        │ Firestore / Storage    │ Stripe Billing
      ▼                      ▼                        ▼
┌──────────────┐     ┌────────────────┐        ┌────────────────┐
│Local Storage │     │ User Profiles  │        │ Subscription    │
│(Hive/Prefs)  │     │ Daily Content  │        │ Entitlements    │
└──────────────┘     └────────────────┘        └────────────────┘
```

## Repository Layout
```
SBA/
├── README.md
├── docs/
│   ├── architecture.md        # Detailed system architecture
│   ├── product-roadmap.md     # Milestones, sprints, KPIs
│   └── qa-plan.md             # Testing strategy & checklists
├── backend/                   # Node.js API scaffold (Express + TypeScript)
│   ├── .env.example
│   ├── src/
│   └── package.json
├── mobile/
│   ├── README.md              # Mobile-specific instructions
│   └── spiritual_bible_chat/  # Flutter client project
└── ...
```

## Development Setup
### Prerequisites
- Node.js 18+ (v22.19.0 verified in this environment) + npm 10+.
- Flutter 3.22.x (stable). Android Studio + Android SDK command-line tools for device builds.
- Optional for Linux desktop builds: `sudo apt install clang ninja-build libgtk-3-dev`.

### Backend (API prototype)
1. `cd backend`
2. `cp .env.example .env`
3. Populate `OPENAI_API_KEY` and `OPENAI_ASSISTANT_ID` in `.env`
4. `npm install`
5. `npm run dev`

The dev server listens on `http://localhost:4000` and exposes:
- `GET /api/health` – health probe.
- `POST /api/v1/chat` – proxies user prompts to the configured OpenAI Assistant (returns assistant reply + thread id).

### Mobile (Flutter client)
1. `cd mobile/spiritual_bible_chat`
2. `flutter pub get`
3. `flutter run -d <device>` (choose an emulator/device via `flutter devices`)

`lib/main.dart` currently exposes a navigation shell with placeholder screens that map to Today, Chat, Progress, and Profile flows. Build out features incrementally, keeping documentation in sync with the roadmap.

## Tooling Status (current environment)
- ✅ Node.js / npm available.
- ✅ Flutter CLI installed (`flutter doctor` reports Android toolchain ready; Linux desktop tooling optional).

## Next Actions
- Finalize UX flows & visual design system.
- Flesh out the mobile shell with onboarding, streak tracking, and chat integration.
- Expand backend to include OpenAI integration, auth middleware, and persistence layer stubs.
- Implement AI chat MVP end-to-end with feature flags gating premium limits.
- Build paywall flow and subscription gating.

Consult the documents in `docs/` for deeper architectural, roadmap, and QA details.
