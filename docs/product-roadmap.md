# Product Roadmap & Milestones (V1)

## Goal Metrics (V1 Launch)
- **Activation**: ≥75% onboarding completion, ≥60% notification opt-in.
- **Engagement**: ≥35% Day-1 retention, ≥20% Day-7 retention.
- **Monetization**: ≥5% free → trial start, ≥2.5% trial → paid conversion.
- **NPS Target**: +45 within first 3 months post-launch.

## Milestones

### M0 – Foundations (Week 0–2)
- [ ] Confirm UX wireframes & design system tokens.
- [ ] Scaffold Flutter app (`mobile/`) with navigation shell & theming.
- [ ] Establish backend repo + CI pipelines.
- [ ] Integrate Firebase project, environment config templates.

### M1 – Personalization Core (Week 3–5)
- [ ] Implement onboarding quiz (UI + local preference store).
- [ ] Build daily verse module with cached content + local notifications.
- [ ] Implement streak tracking logic & badge data model.
- [ ] Seed content CMS / Firestore with initial 30-day verse plan.

### M2 – AI Chat MVP (Week 6–8)
- [ ] Backend proxy to OpenAI with moderation guardrails.
- [ ] Flutter chat UI with streaming responses & error states.
- [ ] Usage metering for free tier + local messaging cache.
- [ ] Internal QA of AI responses, prompt tuning backlog.

### M3 – Monetization Layer (Week 9–11)
- [ ] Integrate RevenueCat SDK, define products, implement paywall UI.
- [ ] Enforce entitlements client + server side.
- [ ] Soft paywall triggers (usage overage, premium content gating).
- [ ] Analytics funnel instrumentation (paywall → conversion).

### M4 – Polish & Beta (Week 12–14)
- [ ] Visual polish (animations, illustrations, dark mode).
- [ ] Accessibility audit & copy review.
- [ ] Closed beta (TestFlight & Play Internal) feedback iteration.
- [ ] Localization prep (strings extraction) – future ready.

### Launch Prep (Week 15)
- [ ] App Store & Play Store listings, screenshots, trailer.
- [ ] Backend scaling review, monitoring alerts configured.
- [ ] Final QA regression + penetration tests.
- [ ] Submit for store review & resolve feedback.

## Backlog (Post V1 Ideas)
- Expanded content packs (e.g., themed devotionals, guided meditations).
- Audio companion with text-to-speech for verses.
- Journaling with AI reflection prompts & export.
- Community prayer rooms (moderated micro-groups).
- Wearable widgets (Apple Watch complications, Android widgets).
- Web portal for premium subscribers.

## Cross-Team Dependencies
- **Design**: High-fidelity mockups, iconography, illustration pack by M0 + 2w.
- **Content**: Verse library, commentary scripts, Neville quote curation by M1.
- **Marketing**: Launch campaign assets, landing page, email drip sequence by M4.
- **Legal/Compliance**: Privacy policy, terms of service, data processing agreements by Launch Prep.

## Risks & Mitigations
| Risk | Impact | Mitigation |
| --- | --- | --- |
| AI responses drift off-theology | User distrust | Tight system prompts, retrieval augmentation, human eval set |
| Subscription rejection during review | Launch delay | Follow store guidelines, use approved wording, test sandbox thoroughly |
| Notification opt-in low | Retention drop | Value-focused pre-permission screens, A/B message |
| Content licensing for Bible translations | Blockers for future features | Start with public domain KJV, negotiate modern translation rights post-launch |

## Tracking
- Weekly checkpoints reviewing KPI dashboards (Firebase Analytics, RevenueCat, OpenAI usage).
- Retro after each milestone to recalibrate scope.
- Update this roadmap as milestones complete or priorities shift.
