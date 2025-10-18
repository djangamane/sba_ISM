import env from '../config/env';
import { stripeClient, isStripeConfigured } from './stripeClient';
import { supabaseAdmin, isSupabaseAdminAvailable } from './supabaseClient';
import { applyStripeSubscription } from './entitlements';

const DEFAULT_SUCCESS_URL = 'https://sba-ism.vercel.app/?session_id={CHECKOUT_SESSION_ID}';
const DEFAULT_CANCEL_URL = 'https://sba-ism.vercel.app/';
const DEFAULT_PORTAL_RETURN_URL = 'https://sba-ism.vercel.app/';

const normalizeSuccessUrl = (url: string) => {
  if (url.includes('{CHECKOUT_SESSION_ID}')) {
    return url;
  }
  const separator = url.includes('?') ? '&' : '?';
  return `${url}${separator}session_id={CHECKOUT_SESSION_ID}`;
};

const resolvePriceId = (planId: string): string | null => {
  if (planId === 'premium_annual') {
    return env.stripePriceAnnual || null;
  }
  return env.stripePriceMonthly || null;
};

export const createStripeCheckoutSession = async (
  userId: string,
  planId: 'premium_monthly' | 'premium_annual',
  email?: string | null
): Promise<string> => {
  if (!isStripeConfigured || !stripeClient) {
    throw new Error('Stripe is not configured.');
  }

  const priceId = resolvePriceId(planId);
  if (!priceId) {
    throw new Error('Stripe price ID is not configured for this plan.');
  }

  const successUrl = normalizeSuccessUrl(env.stripeSuccessUrl || DEFAULT_SUCCESS_URL);
  const cancelUrl = env.stripeCancelUrl || DEFAULT_CANCEL_URL;

  const session = await stripeClient.checkout.sessions.create({
    mode: 'subscription',
    customer_email: email ?? undefined,
    allow_promotion_codes: true,
    metadata: {
      user_id: userId,
      plan_id: planId,
    },
    subscription_data: {
      metadata: {
        user_id: userId,
        plan_id: planId,
      },
    },
    success_url: successUrl,
    cancel_url: cancelUrl,
    line_items: [
      {
        price: priceId,
        quantity: 1,
      },
    ],
  });

  if (!session.url) {
    throw new Error('Stripe did not return a checkout URL.');
  }

  return session.url;
};

export const createStripePortalSession = async (userId: string): Promise<string> => {
  if (!isStripeConfigured || !stripeClient) {
    throw new Error('Stripe is not configured.');
  }
  if (!isSupabaseAdminAvailable || !supabaseAdmin) {
    throw new Error('Supabase admin client unavailable');
  }

  const { data, error } = await supabaseAdmin
    .from('profiles')
    .select('stripe_customer_id')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  const customerId = data?.stripe_customer_id;
  if (!customerId) {
    throw new Error('No active subscription found for this user.');
  }

  const returnUrl =
    env.stripePortalReturnUrl || env.stripeSuccessUrl || env.stripeCancelUrl || DEFAULT_PORTAL_RETURN_URL;

  const session = await stripeClient.billingPortal.sessions.create({
    customer: customerId,
    return_url: returnUrl,
  });

  if (!session.url) {
    throw new Error('Stripe did not return a portal URL.');
  }

  return session.url;
};

const logStripeEvent = async (userId: string | null, event: any) => {
  if (!userId || !isSupabaseAdminAvailable || !supabaseAdmin) {
    return;
  }

  await supabaseAdmin.from('premium_events').insert({
    user_id: userId,
    event_type: event.type,
    event_id: event.id,
    payload: event,
  });
};

const toStripeId = (value: unknown): string | null => {
  if (!value) return null;
  if (typeof value === 'string') return value;
  if (typeof value === 'object' && value !== null && 'id' in value) {
    const obj = value as { id?: string };
    return obj.id ?? null;
  }
  return null;
};

const subscriptionIsActive = (status: string | null | undefined): boolean => {
  if (!status) return false;
  return ['trialing', 'active', 'past_due', 'unpaid'].includes(status);
};

const applySubscriptionFromStripe = async (subscription: any, userId: string | null) => {
  if (!userId) {
    return;
  }

  await applyStripeSubscription(userId, {
    isActive: subscriptionIsActive(subscription.status),
    currentPeriodEnd: subscription.current_period_end ?? null,
    trialEnd: subscription.trial_end ?? null,
    customerId: toStripeId(subscription.customer),
    planId: subscription.metadata?.plan_id ?? null,
  });
};

const handleCheckoutSessionCompleted = async (event: any) => {
  if (!stripeClient) return;
  const session = event.data.object as any;
  const userId = session.metadata?.user_id ?? null;
  const subscriptionId = toStripeId(session.subscription);

  if (!userId) {
    await logStripeEvent(null, event);
    return;
  }

  if (!subscriptionId) {
    await logStripeEvent(userId, event);
    return;
  }

  const subscription = await stripeClient.subscriptions.retrieve(subscriptionId);
  if (subscription.metadata?.plan_id == null && session.metadata?.plan_id) {
    subscription.metadata.plan_id = session.metadata.plan_id;
  }
  await applySubscriptionFromStripe(subscription, userId);
  await logStripeEvent(userId, event);
};

const handleSubscriptionEvent = async (event: any) => {
  const subscription = event.data.object as any;
  const userId = subscription.metadata?.user_id ?? null;
  if (!userId) {
    await logStripeEvent(null, event);
    return;
  }

  await applySubscriptionFromStripe(subscription, userId);
  await logStripeEvent(userId, event);
};

export const handleStripeEvent = async (event: any) => {
  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckoutSessionCompleted(event);
      break;
    case 'customer.subscription.updated':
    case 'customer.subscription.deleted':
      await handleSubscriptionEvent(event);
      break;
    default:
      break;
  }
};
