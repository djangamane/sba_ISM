# QA Strategy – Spiritual Bible Chat App V1

## Objectives
- Guarantee core flows (onboarding, daily content, chat, paywall) are reliable across iOS & Android.
- Validate AI-generated guidance remains on-brand, empathetic, and safe.
- Ensure monetization (trials, subscriptions) adheres to store policies.

## Test Types

### 1. Functional Testing
- **Onboarding**: question branching, preference persistence, notification scheduling.
- **Daily Verse**: date roll-over, offline cache, share actions.
- **Chat**: streaming responses, retry handling, context continuity, usage limit enforcement.
- **Streaks/Badges**: day rollover edge cases, timezone shifts, manual clock tampering resilience.
- **Paywall**: trigger points, entitlement gating, restore purchases.

### 2. Non-Functional Testing
- **Usability**: heuristic review + 5-person usability study (personas cover seeker, learner, explorer).
- **Performance**: response latency <3s P95 for AI call, cold start <2.5s on mid-tier devices.
- **Accessibility**: VoiceOver/TalkBack labels, font scaling, contrast AA compliance.
- **Localization-ready**: verify strings pulled from `arb/json`, no hard-coded copy.

### 3. Security & Privacy
- Static analysis (`dart analyze`, `npm audit`).
- Network sniff test (ensure TLS everywhere, no secrets in payloads).
- Data deletion flow validation (account removal wipes Supabase profile, Stripe customer metadata).

### 4. Regression
- Automated test suites run on CI for every PR:
  - Flutter unit & widget tests.
  - Integration tests via `flutter_test`/`integration_test` covering onboarding → paywall.
  - Backend API tests (Jest/Vitest) mocking OpenAI responses.
- Manual regression checklist per release candidate.

## Environments
- **Local**: dev configs with mock OpenAI server (to avoid quota drain).
- **Staging**: mirrors production services (Firebase project `sba-staging`, Stripe test mode, OpenAI staging key).
- **Production**: locked to release builds, monitoring via Crashlytics and Stripe dashboards.

## Tooling
- Device lab: iPhone 12/14, iPad Mini, Pixel 5/7, Galaxy A series, low-end Android (Moto G).
- Cloud device farms (Firebase Test Lab) for matrix coverage.
- Test case management: Notion board or Jira Xray (to be chosen).
- Bug tracking: Jira with severity triage (S0-blocker → S3-minor).

## Release Checklist Snapshot
1. ✅ All automated tests green on CI main branch.
2. ✅ Crash-free sessions ≥99% on staging dogfood build.
3. ✅ AI transcript audit (50-sample manual review) passes theology & tone checks.
4. ✅ Subscription sandbox tests (purchase, trial, cancel, restore) documented.
5. ✅ Privacy policy & TOS links live and accessible in settings + store listings.
6. ✅ Store metadata reviewed by marketing & legal.

## Post-Launch Monitoring
- Daily scan Crashlytics for new issues; respond within 24h for S0/S1.
- Review App Store/Play reviews every morning; triage actionable feedback.
- Weekly AI performance sampling; adjust prompts/retrieval as needed.
- Track KPI dashboards for retention, conversion; set alert thresholds (e.g., Day-1 retention drop >5% WoW triggers investigation).

## Continuous Improvement
- Convert critical bug fixes into automated regression tests.
- Maintain known-issues log with mitigation/workaround.
- Schedule quarterly security assessment and dependency updates.

This plan will evolve with product scope. Update alongside feature additions or new regulatory requirements.
