import { supabaseAdmin, isSupabaseAdminAvailable } from './supabaseClient';

const FREE_CHAT_DAILY_LIMIT = 3;
const FREE_DEVOTIONAL_DAILY_LIMIT = 1;

interface AccessResult {
  allowed: boolean;
  message?: string;
}

const isPremiumUser = async (userId: string): Promise<boolean> => {
  if (!isSupabaseAdminAvailable || !supabaseAdmin) {
    return true;
  }

  const { data, error } = await supabaseAdmin
    .from('profiles')
    .select('is_premium,premium_expires_at')
    .eq('user_id', userId)
    .maybeSingle();

  if (error || !data) {
    return false;
  }

  if (data.is_premium) {
    if (!data.premium_expires_at) {
      return true;
    }
    const expires = new Date(data.premium_expires_at);
    return expires.getTime() > Date.now();
  }

  return false;
};

const countUsageSince = async (
  userId: string,
  endpoint: string,
  since: Date
): Promise<number> => {
  if (!isSupabaseAdminAvailable || !supabaseAdmin) {
    return 0;
  }

  const { count } = await supabaseAdmin
    .from('usage_logs')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('endpoint', endpoint)
    .gte('created_at', since.toISOString());

  return count ?? 0;
};

const startOfToday = () => {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
};

export const ensureChatAccess = async (userId?: string): Promise<AccessResult> => {
  if (!userId) {
    return { allowed: false, message: 'Please sign in to continue.' };
  }

  if (!isSupabaseAdminAvailable || !supabaseAdmin) {
    return { allowed: true };
  }

  if (await isPremiumUser(userId)) {
    return { allowed: true };
  }

  const count = await countUsageSince(userId, 'chat', startOfToday());
  if (count >= FREE_CHAT_DAILY_LIMIT) {
    return {
      allowed: false,
      message: 'Daily chat limit reached. Upgrade to Premium for unlimited conversations.',
    };
  }

  return { allowed: true };
};

export const ensureDevotionalAccess = async (userId?: string): Promise<AccessResult> => {
  if (!userId) {
    return { allowed: false, message: 'Please sign in to continue.' };
  }

  if (!isSupabaseAdminAvailable || !supabaseAdmin) {
    return { allowed: true };
  }

  if (await isPremiumUser(userId)) {
    return { allowed: true };
  }

  const count = await countUsageSince(userId, 'devotional', startOfToday());
  if (count >= FREE_DEVOTIONAL_DAILY_LIMIT) {
    return {
      allowed: false,
      message: 'Daily devotional limit reached. Upgrade to Premium to unlock unlimited access.',
    };
  }

  return { allowed: true };
};

export const grantDemoPremium = async (userId: string, durationDays = 7) => {
  if (!isSupabaseAdminAvailable || !supabaseAdmin) {
    throw new Error('Supabase admin client unavailable');
  }

  const expires = new Date();
  expires.setDate(expires.getDate() + durationDays);
  const expiresIso = expires.toISOString();

  await supabaseAdmin
    .from('profiles')
    .upsert({
      user_id: userId,
      is_premium: true,
      premium_expires_at: expiresIso,
      premium_trial_ends_at: null,
      premium_source: 'demo',
    }, { onConflict: 'user_id' });
};

interface StripeSubscriptionState {
  isActive: boolean;
  currentPeriodEnd?: number | null;
  trialEnd?: number | null;
  customerId?: string | null;
  planId?: string | null;
}

export const applyStripeSubscription = async (userId: string, state: StripeSubscriptionState) => {
  if (!isSupabaseAdminAvailable || !supabaseAdmin) {
    throw new Error('Supabase admin client unavailable');
  }

  const expiresAtIso =
    state.currentPeriodEnd && state.isActive
      ? new Date(state.currentPeriodEnd * 1000).toISOString()
      : null;
  const trialEndsIso =
    state.trialEnd && state.isActive
      ? new Date(state.trialEnd * 1000).toISOString()
      : null;

  await supabaseAdmin
    .from('profiles')
    .upsert(
      {
        user_id: userId,
        is_premium: state.isActive,
        premium_expires_at: state.isActive ? expiresAtIso : null,
        premium_trial_ends_at: state.isActive ? trialEndsIso : null,
        premium_source: state.isActive ? 'stripe' : null,
        stripe_customer_id: state.customerId ?? null,
        premium_plan_id: state.planId ?? null,
      },
      { onConflict: 'user_id' }
    );
};
