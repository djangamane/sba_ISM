import env from '../config/env';
import { supabaseAdmin, isSupabaseAdminAvailable } from './supabaseClient';

const ENTITLEMENT_CANDIDATES = ['premium', 'premium_monthly', 'premium_annual'];

interface RevenueCatEntitlement {
  product_identifier?: string | null;
  expires_date?: string | null;
  grace_period_expires_date?: string | null;
  unsubscribe_detected_at?: string | null;
  billing_issues_detected_at?: string | null;
  purchase_date?: string | null;
  trial_starts_at?: string | null;
  trial_ends_at?: string | null;
  is_active?: boolean;
}

interface RevenueCatEventPayload {
  event?: {
    id?: string;
    type?: string;
    app_user_id?: string;
    original_app_user_id?: string;
    product_id?: string;
    environment?: string;
    period_type?: string;
    store?: string;
    purchased_at_ms?: number;
    expires_at_ms?: number | null;
    expiration_at_ms?: number | null;
  };
  subscriber?: {
    entitlements?: Record<string, RevenueCatEntitlement | undefined>;
  };
  [key: string]: unknown;
}

export interface RevenueCatProcessingResult {
  processed: boolean;
  reason?: string;
  userId?: string;
  isActive?: boolean;
  expiresAt?: string | null;
}

const msToIso = (value?: number | null): string | null => {
  if (typeof value !== 'number' || Number.isNaN(value) || value <= 0) {
    return null;
  }
  return new Date(value).toISOString();
};

const selectEntitlement = (
  entitlements?: Record<string, RevenueCatEntitlement | undefined>
): RevenueCatEntitlement | undefined => {
  if (!entitlements) {
    return undefined;
  }

  for (const candidate of ENTITLEMENT_CANDIDATES) {
    const match = entitlements[candidate];
    if (match) {
      return match;
    }
  }

  return Object.values(entitlements).find((entry) => entry?.is_active);
};

const determineExpiry = (
  payload: RevenueCatEventPayload,
  entitlement?: RevenueCatEntitlement
): string | null => {
  const eventExpiry =
    msToIso(payload.event?.expires_at_ms ?? payload.event?.expiration_at_ms ?? null);
  if (eventExpiry) {
    return eventExpiry;
  }

  if (entitlement?.expires_date) {
    return entitlement.expires_date;
  }

  if (entitlement?.grace_period_expires_date) {
    return entitlement.grace_period_expires_date;
  }

  return null;
};

const determineTrialEnd = (
  payload: RevenueCatEventPayload,
  entitlement?: RevenueCatEntitlement
): string | null => {
  if (entitlement?.trial_ends_at) {
    return entitlement.trial_ends_at;
  }

  const periodType = payload.event?.period_type?.toLowerCase();
  if (periodType === 'trial' || periodType === 'intro') {
    return determineExpiry(payload, entitlement);
  }

  return null;
};

export const processRevenueCatWebhook = async (
  payload: RevenueCatEventPayload
): Promise<RevenueCatProcessingResult> => {
  if (!env.revenueCatWebhookSecret) {
    throw new Error('RevenueCat webhook secret is not configured.');
  }

  if (!isSupabaseAdminAvailable || !supabaseAdmin) {
    throw new Error('Supabase admin client unavailable');
  }

  const eventId = payload.event?.id;
  if (!eventId) {
    return { processed: false, reason: 'missing_event_id' };
  }

  const userId = payload.event?.app_user_id;
  if (!userId) {
    return { processed: false, reason: 'missing_app_user_id' };
  }

  const { data: existingEvent, error: eventLookupError } = await supabaseAdmin
    .from('premium_events')
    .select('event_id')
    .eq('event_id', eventId)
    .maybeSingle();

  if (eventLookupError) {
    throw eventLookupError;
  }

  if (existingEvent) {
    return { processed: false, reason: 'duplicate_event', userId };
  }

  const entitlement = selectEntitlement(payload.subscriber?.entitlements);
  const expiresAt = determineExpiry(payload, entitlement);
  const trialEndsAt = determineTrialEnd(payload, entitlement);

  const expiresTimestamp = expiresAt ? Date.parse(expiresAt) : undefined;
  const hasValidExpiry = !!expiresTimestamp && !Number.isNaN(expiresTimestamp);
  const isActive =
    Boolean(entitlement) && (!hasValidExpiry || (expiresTimestamp as number) > Date.now());

  const upsertPayload: Record<string, unknown> = {
    user_id: userId,
    is_premium: isActive,
    premium_expires_at: expiresAt,
    premium_trial_ends_at: trialEndsAt,
    premium_source: isActive ? 'revenuecat' : null,
  };

  const { error: upsertError } = await supabaseAdmin
    .from('profiles')
    .upsert(upsertPayload, { onConflict: 'user_id' });

  if (upsertError) {
    throw upsertError;
  }

  const { error: insertEventError } = await supabaseAdmin.from('premium_events').insert({
    user_id: userId,
    event_type: payload.event?.type ?? 'unknown',
    event_id: eventId,
    payload,
  });

  if (insertEventError) {
    throw insertEventError;
  }

  return {
    processed: true,
    userId,
    isActive,
    expiresAt,
  };
};
