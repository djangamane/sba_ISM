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
      "entitlement_source": "revenuecat",
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

### 1.2 `/api/v1/paywall/offerings` (GET)
- Optional endpoint to surface dynamic offers if needed; proxied from RevenueCat REST.
- Include cache headers (5 min) to limit rate usage.

## 2. RevenueCat Integration
### 2.1 Server-side
- Configure webhook endpoint `/api/v1/revenuecat/webhook` (POST).
  - Verify `X-Authorization` header matches shared secret.
  - Handle events: `INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, `REFUND`, `EXPIRATION`.
  - Upsert Supabase `profiles` with:
    - `is_premium` boolean.
    - `premium_expires_at`.
    - `premium_source` (`revenuecat`).
    - `premium_trial_ends_at`.
  - Log events to `premium_events` table for auditing.
- Idempotent processing via `event_id` (store processed IDs).

### 2.2 Mobile App Sync
- RevenueCat App User ID = Supabase user UUID (or generated anon).  
- On app launch:
  1. RevenueCat listener updates local state immediately.
  2. App calls `/api/v1/profile` to confirm backend state; reconcile differences.
- On webhook delta, backend can push realtime update via Supabase Realtime (optional stretch).

## 3. Data Model Changes
```sql
alter table public.profiles
  add column if not exists premium_source text check (premium_source in ('revenuecat')) default null,
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
- **RevenueCat**:
  - Enable Webhooks for Sandbox + Production; send to same handler with environment flag.
  - Configure integrations (Mixpanel/Firebase) once analytics stack ready.

## 5. Testing Strategy
- Unit tests for entitlement service:
  - Process webhook payloads (initial, renewal, cancel) → verify Supabase mutations.
  - Ensure expired entitlements flip flags and blocks endpoints.
- Integration tests:
  - Mock RevenueCat API in `/paywall/offerings`.
  - Exercise `/api/v1/profile` to ensure premium block removed post-upgrade.
- End-to-end manual checklist:
  1. Create sandbox user, purchase trial, verify profile updated.
  2. Cancel subscription, allow expiry, confirm access revoked.
  3. Restore purchase on second device, ensure entitlement sync.

## 6. Open Questions / Risks
- Multi-platform account linking: do we support anonymous RevenueCat IDs upgrading before Supabase signup?
- Handling legacy demo upgrades: plan migration path to revoke once real subscriptions live.
- Need SLA for webhook processing (retry/backoff strategy).

This scope should guide backend implementation work and align analytics expectations for the premium launch.
