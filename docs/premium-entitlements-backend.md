# Premium Entitlements – Backend & Analytics Scope

## 1. API Surface
### 1.1 `/api/v1/profile` (GET)
- Auth: Supabase JWT required.
- Response payload:
  ```json
  {
    "profile": {
      "goal": "stress_relief",
      "familiarity": "curious",
      "content_preferences": ["guided_prayer", "affirmations"],
      "reminder_slot": "evening",
      "wants_streaks": true
    },
    "streak": { "...": "..." },
    "premium": {
      "is_active": true,
      "entitlement_source": "stripe",
      "expires_at": "2024-11-10T18:45:00Z",
      "trial": {
        "is_trial": true,
        "trial_ends_at": "2024-11-07T18:45:00Z"
      }
    }
  }
  ```
- Implementation notes:
  - Fetch joins `profiles`, `streaks`, and cached premium metadata.
  - Return HTTP 200 for guests (with `is_active=false`) and 401 if token missing.

### 1.2 `/api/v1/paywall/stripe-checkout` (POST)
- Starts a Stripe Checkout Session and returns `{ "checkoutUrl": "https://..." }`.
- Request body: `{ "planId": "premium_monthly" }`.
- Requires Supabase JWT; backend derives Stripe customer from profile (creates one if missing).

## 2. Stripe Integration
### 2.1 Server-side
- Configure webhook endpoint `/api/v1/stripe/webhook` (POST).
  - Verify `Stripe-Signature` header using the webhook signing secret.
  - Handle events: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.payment_failed`.
  - Upsert Supabase `profiles` with:
    - `is_premium` boolean.
    - `premium_expires_at`.
    - `premium_source` (`stripe`).
    - `premium_trial_ends_at`.
  - Log events to `premium_events` table for auditing.
- Idempotent processing via `event_id` (store processed IDs).

### 2.2 Mobile App Sync
- Stripe Customer ID stored alongside Supabase user UUID.  
- On app launch:
  1. App opens Stripe Checkout (web) or Billing Portal; backend receives webhook.
  2. App calls `/api/v1/profile` to confirm backend state; reconcile differences.
- On webhook delta, backend can push realtime update via Supabase Realtime (optional stretch).

## 3. Data Model Changes
```sql
alter table public.profiles
  add column if not exists premium_source text check (premium_source in ('stripe', 'demo')) default null,
  add column if not exists premium_trial_ends_at timestamptz;

create table if not exists public.premium_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users,
  event_type text not null,
  event_id text not null unique,
  occurred_at timestamptz not null default now(),
  payload jsonb not null
);

alter table public.premium_events enable row level security;
create policy "Service role insert only" on public.premium_events
  for insert to service_role with check (true);
```

## 4. Analytics & Telemetry
- **Backend Logs**:
  - Log paywall trigger context (`endpoint`, `user_id`, `reason`) before returning 402.
  - Emit structured logs for entitlement changes (`info` level).
- **Supabase**:
  - Create SQL view `premium_conversions` summarizing events per day.
- **Stripe**:
  - Configure separate webhook endpoints for test vs production.
  - Enable Stripe Sigma or Data Pipeline if deeper financial reporting is required later.

## 5. Testing Strategy
- Unit tests for entitlement service:
  - Process webhook payloads (checkout completed, subscription updated/cancelled) → verify Supabase mutations.
  - Ensure expired entitlements flip flags and blocks endpoints.
- Integration tests:
  - Mock Stripe SDK in `/paywall/stripe-checkout`.
  - Exercise `/api/v1/profile` to ensure premium block removed post-upgrade.
- End-to-end manual checklist:
  1. Create test-mode customer, run checkout with Stripe test card, verify profile updated.
  2. Cancel subscription, allow expiry, confirm access revoked.
  3. Re-run checkout for same customer to ensure entitlement sync and expiry overrides.

## 6. Open Questions / Risks
- Multi-platform account linking: do we support anonymous Stripe customers upgrading before Supabase signup?
- Handling legacy demo upgrades: plan migration path to revoke once real subscriptions live.
- Need SLA for webhook processing (retry/backoff strategy).

This scope should guide backend implementation work and align analytics expectations for the premium launch.
