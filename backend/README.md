# Spiritual Bible Chat – Backend API

This Node.js/Express service proxies mobile traffic to OpenAI and central services. Current state is a scaffold with health checks and a placeholder chat endpoint.

## Scripts
- `npm run dev` – Start development server with hot-reload.
- `npm run build` – Compile TypeScript to `dist/`.
- `npm start` – Run compiled server.
- `npm run lint` – Type-check without emitting output.

## Environment Variables (`.env`)
| Key | Default | Description |
| --- | --- | --- |
| `PORT` | `4000` | HTTP port for the API |
| `NODE_ENV` | `development` | Runtime environment label |
| `OPENAI_PROXY_URL` | `https://api.openai.com/v1/chat/completions` | Legacy field (unused once Assistants API is configured) |
| `OPENAI_API_KEY` | _required_ | OpenAI API key with Assistants access |
| `OPENAI_ASSISTANT_ID` | _required_ | Assistant ID to run conversations against |
| `SUPABASE_URL` | _required_ | Supabase project URL used for JWT validation |
| `SUPABASE_SERVICE_ROLE_KEY` | _required_ | Supabase service role key used for server-side auth/usage logging |
| `STRIPE_SECRET_KEY` | _required_ | Stripe API secret used to create checkout sessions |
| `STRIPE_WEBHOOK_SECRET` | _(recommended)_ | Stripe webhook signing secret to validate events |

Copy `.env.example` to `.env` before running locally.

## HTTP Endpoints
- `GET /api/health` – health probe (no auth required)
- `POST /api/v1/chat` – conversational chat endpoint (Supabase JWT required, rate limited)
- `POST /api/v1/devotional` – generates a daily devotional paragraph (Supabase JWT required, rate limited)
- `GET /api/v1/profile` – fetch combined profile + streak + premium entitlement state (Supabase JWT required)
- `POST /api/v1/paywall/grant-demo` – temporary helper to grant a 7-day premium demo to the authenticated user
- `POST /api/v1/paywall/stripe-checkout` – placeholder endpoint for creating Stripe checkout sessions (returns 501 until wired)
- `POST /api/v1/stripe/webhook` – Stripe webhook placeholder (returns 501 until wired)

### Rate Limiting & Usage Logs
- Chat: 30 requests per user per minute.
- Devotional: 10 requests per user per 10 minutes.
- Usage is recorded in the `usage_logs` table. Ensure it exists with the following SQL:

```sql
alter table public.profiles
  add column if not exists is_premium boolean not null default false,
  add column if not exists premium_expires_at timestamptz,
  add column if not exists premium_trial_ends_at timestamptz,
  add column if not exists premium_source text,
  add column if not exists next_reminder_at timestamptz;

alter table public.profiles drop constraint if exists profiles_premium_source_check;
alter table public.profiles add constraint profiles_premium_source_check
  check (premium_source in ('stripe', 'demo') or premium_source is null);

create table if not exists public.usage_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users,
  endpoint text not null,
  created_at timestamptz not null default now()
);

alter table public.usage_logs enable row level security;

create policy "Insert usage logs" on public.usage_logs
  for insert with check (true);

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
