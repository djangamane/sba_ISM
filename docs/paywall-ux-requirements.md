# Paywall UX Requirements – Flutter Client

## 1. Component Architecture
- **PaywallScaffold** (full-screen)  
  - Header with gradient background, close button, product toggle (monthly/annual).  
  - Benefit carousel (3 cards), testimonials placeholder, FAQ accordion.  
  - Primary CTA anchored to bottom with trial-aware label.  
  - Restore purchase + terms link in footer.
- **PaywallModal** (contextual)  
  - Appears as bottom sheet when triggered from usage cap.  
  - Tight copy, highlights single key benefit, secondary CTA to view full paywall.
- **PremiumBadge**  
  - Lightweight widget for Today/Chat/Progress entries, displays status pill + optional countdown (trial remaining days).
- **LockedContentCard**  
  - Reusable skeleton for premium-only tiles; shows benefit summary and CTA `View Premium`.

## 2. Entry Points & Navigation
- Chat screen: raise `PaywallModal` on limit reached (existing hook), offer “See full benefits” to push `PaywallScaffold`.
- Today tab: `Guided Practice` tile uses `LockedContentCard`; tapping pushes `PaywallScaffold`.
- Progress tab: `Streak booster` CTA opens full paywall.
- Settings/Profile: static list tile `Manage Subscription` that navigates to paywall when not premium, and to subscription settings when premium.
- Deep links: support `sba://paywall` to open `PaywallScaffold` with optional query `source`.

## 3. Visual & Motion Details
- Gradient: `LinearGradient(colors: [Color(0xFF5E4AE3), Color(0xFFB794F4)])`.
- Icons: use `material_symbols` outlined set; premium color `Color(0xFFE3B341)`.
- Animations:  
  - Hero transition from modal CTA to full-screen paywall header.  
  - Benefit cards fade/slide-in sequentially on first appearance.
- Accessibility: ensure contrast ratios > 4.5:1, provide `Semantics` labels for benefits, CTA.

## 4. State Management & Data
- Introduce `PremiumStateNotifier` (Riverpod) backed by `ProfileRepository`.  
  - Holds `isPremium`, `trialEndsAt`, `source` info.  
  - Listens for Stripe webhook refresh events (via backend polling); exposes stream for UI updates.
- Paywall components consume provider to:
  - Render trial countdown.  
  - Disable purchase button when pending transaction.  
  - Switch CTA copy post-trial.
- Locked components check `isPremium` before rendering CTA vs unlocked content.

## 5. Purchase Flow Hooks
- Paywall CTA delegates to `StripeCheckoutService.startSession(plan)`.  
- On success redirect: backend listens to Stripe webhook → refresh premium state; show informative banner after returning to app.
- On failure/user cancel: show inline error (non-disruptive) with “Try again” button.
- Provide “I already subscribed” button to force refresh from backend profile endpoint.

## 6. Content & Copy Integration
- Strings collected under new localization namespace `paywall`.  
  - Example keys: `headline`, `subheadline`, `cta_start_trial`, `cta_subscribe_monthly`, `benefit_unlimited_chat`.
- Benefit list and FAQ data stored as JSON in `lib/data/paywall_content.dart` for consistent use across full and modal paywalls.
- Marketing to supply 2 testimonial blurbs; placeholders ready in UI.

## 7. Telemetry Hooks
- When modal shown: log `paywall_view` with `presentation=modal` and `source`.
- When full screen shown: log `paywall_view` with `presentation=full`.
- CTA tap: `paywall_cta_tap` with `plan`, `trial_eligible`.
- Restoration attempt: `paywall_restore`.

## 8. Acceptance Tests
- Widget tests ensuring:
  - Paywall shows correct plan price/cta based on mocked state.  
  - LockedContentCard switches to unlocked view when state becomes premium.  
  - Modal > full-screen navigation works via tester taps.
- Golden tests for light/dark mode to validate visual consistency.

## 9. Open Questions
- Need final copy for FAQ items and testimonial sources.  
- Decide whether to auto-open full paywall after second modal display within session.  
- Confirm if we localize testimonials or keep English-only at launch.
