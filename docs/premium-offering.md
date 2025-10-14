# Premium Offering Specification – Spiritual Bible Chat

## 1. Product Summary
- **Plan Name**: Spiritual Bible Chat Premium
- **Price Points**:
  - Monthly: **$9.99 USD** (tier matching App Store Tier 10 / Play Tier G equivalent).
  - Annual: **$69.99 USD** (≈42% savings vs monthly).
- **Trial**: 7-day free trial available on first activation of either plan.
- **Grace Period**: 3-day auto-renew grace window (handled by stores) before entitlement revocation.
- **Target Launch**: Milestone M3 (Monetization Layer) per product roadmap.

## 2. Value Proposition
| Benefit | Free Tier | Premium Tier |
| --- | --- | --- |
| AI Chat Conversations | 3 per day (rollover disabled) | Unlimited, priority queue |
| Daily Devotionals | 1 per day | Unlimited + archived history |
| Guided Practices | Locked | Full catalog + new weekly drops |
| Streak Boosters | Locked | Friday booster + lapse forgiveness 1×/month |
| Notification Themes | Default only | Seasonal & premium nudges |
| Roadmap Extras | — | Early access to journaling + audio meditations |

Key marketing message: **“Deepen your walk with unlimited guidance, tailored practices, and exclusive spiritual tools.”**

## 3. Gated Touchpoints
- **Chat Screen**: Paywall triggers on the 4th conversation attempt in a 24h window, and on premium-only prompt templates.
- **Devotional Screen**: Upsell when user requests a second devotional in same day; premium badge on archived entries.
- **Today Tab**: Premium-only “Guided Practice” card (locked state shows benefits + CTA).
- **Progress Tab**: Streak booster banner and lapse forgiveness control require premium; display locked state copy for free users.
- **Settings/Profile**: Persistent “Upgrade to Premium” entry point with trial countdown once activated.

## 4. Copy & Visual Guidelines
- **Headline**: “Unlock Your Full Spiritual Journey”
- **Subhead**: “Unlimited conversations, deeper devotionals, and premium practices crafted for your growth.”
- **CTA Labels**:
  - Primary: “Start 7-day free trial”
  - Secondary: “Maybe later” / “Restore purchase”
  - Post-trial: “Subscribe for \$9.99/month” (auto-switch based on offer eligibility)
- **Benefits List** (use iconography):
  1. “Unlimited AI mentoring rooted in scripture”
  2. “Exclusive guided practices and audio reflections”
  3. “Keep your streak soaring with forgiveness boosts”
- **Design Notes**:
  - Gradient background: `#5E4AE3 → #B794F4`
  - Accent icons: outline style with gold highlights `#E3B341`
  - Display plan toggle (Monthly / Annual) with savings badge on annual

## 5. Technical Acceptance Criteria
1. **Entitlement Sources**:
   - RevenueCat entitlements `premium_monthly` and `premium_annual` map to Supabase `profiles.is_premium` + `premium_expires_at`.
   - Trial flag stored via RevenueCat trial identifiers; surfaced to app for countdown.
2. **State Handling**:
   - App reacts instantly to entitlement changes (purchase, renewal, cancellation) via in-app listener plus `/api/v1/profile` fallback sync.
   - Premium badge persists offline using cached profile data.
3. **Paywall Variants**:
   - Modal (contextual trigger) and full-screen (main entry point) share reusable component.
   - Support deep link `sba://paywall` for campaign use.
4. **Copy/Localization**:
   - Strings centralized under `lib/l10n/paywall.json` for future translation.
   - Currency localization handled via RevenueCat price formatting rather than static strings.

## 6. Metrics & Analytics
- **Events**:
  - `paywall_view` (include trigger context).
  - `trial_start`, `subscription_purchase`, `subscription_renew`, `subscription_cancel`.
  - `premium_content_unlock` (per content type) for measuring engagement uplift.
- **Funnels**:
  - Paywall view → trial start → D7 retention.
  - Free cap hit → paywall view → conversion.
- **Dashboards**:
  - RevenueCat overview (MRR, active trials).
  - Supabase logs for entitlement mismatches (ensure 0 after stabilization).

## 7. Dependencies & Open Questions
- **Design**: High-fidelity paywall visuals + icon set due by end of current sprint.
- **Legal**: Confirm subscription copy meets App Store / Play Store guidelines (esp. trial renewal disclosure).
- **Support**: Draft FAQ for billing, cancellations, and trial handling.
- **Question**: Do we allow limited-time promotional codes pre-launch? (Impacts RevenueCat configuration.)

This specification should be reviewed and signed off by Product, Design, and Engineering before implementing the paywall experience.
