import { supabaseAdmin, isSupabaseAdminAvailable } from './supabaseClient';

export interface FullProfileResponse {
  profile: {
    goal: string | null;
    familiarity: string | null;
    content_preferences: string[];
    reminder_slot: string | null;
    wants_streaks: boolean;
    next_reminder_at: string | null;
  } | null;
  streak: {
    current_streak: number;
    longest_streak: number;
    last_completed_date: string | null;
  } | null;
  premium: {
    is_active: boolean;
    entitlement_source: string | null;
    expires_at: string | null;
    trial: {
      is_trial: boolean;
      trial_ends_at: string | null;
    };
    plan_id: string | null;
    customer_id: string | null;
  };
}

const sanitizeStringArray = (value: unknown): string[] => {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.filter((entry): entry is string => typeof entry === 'string');
};

export const getFullProfile = async (userId: string): Promise<FullProfileResponse> => {
  if (!isSupabaseAdminAvailable || !supabaseAdmin) {
    throw new Error('Supabase admin client unavailable');
  }

  const [profileResult, streakResult] = await Promise.all([
    supabaseAdmin
      .from('profiles')
      .select(
        'goal,familiarity,content_preferences,reminder_slot,wants_streaks,next_reminder_at,is_premium,premium_expires_at,premium_trial_ends_at,premium_source,premium_plan_id,stripe_customer_id'
      )
      .eq('user_id', userId)
      .maybeSingle(),
    supabaseAdmin
      .from('streaks')
      .select('current_streak,longest_streak,last_completed_date')
      .eq('user_id', userId)
      .maybeSingle(),
  ]);

  if (profileResult.error) {
    throw profileResult.error;
  }

  if (streakResult.error) {
    throw streakResult.error;
  }

  const profileData = profileResult.data;
  const streakData = streakResult.data;

  const profile = profileData
    ? {
        goal: typeof profileData.goal === 'string' ? profileData.goal : null,
        familiarity: typeof profileData.familiarity === 'string' ? profileData.familiarity : null,
        content_preferences: sanitizeStringArray(profileData.content_preferences),
        reminder_slot:
          typeof profileData.reminder_slot === 'string' ? profileData.reminder_slot : null,
        wants_streaks:
          typeof profileData.wants_streaks === 'boolean' ? profileData.wants_streaks : true,
        next_reminder_at:
          typeof profileData.next_reminder_at === 'string' ? profileData.next_reminder_at : null,
      }
    : null;

  const streak = streakData
    ? {
        current_streak:
          typeof streakData.current_streak === 'number' ? streakData.current_streak : 0,
        longest_streak:
          typeof streakData.longest_streak === 'number' ? streakData.longest_streak : 0,
        last_completed_date:
          typeof streakData.last_completed_date === 'string'
            ? streakData.last_completed_date
            : null,
      }
    : null;

  const premiumExpiresAt =
    profileData && typeof profileData.premium_expires_at === 'string'
      ? profileData.premium_expires_at
      : null;
  const premiumTrialEndsAt =
    profileData && typeof profileData.premium_trial_ends_at === 'string'
      ? profileData.premium_trial_ends_at
      : null;
  const premiumSource =
    profileData && typeof profileData.premium_source === 'string'
      ? profileData.premium_source
      : null;
  const premiumPlanId =
    profileData && typeof profileData.premium_plan_id === 'string'
      ? profileData.premium_plan_id
      : null;
  const stripeCustomerId =
    profileData && typeof profileData.stripe_customer_id === 'string'
      ? profileData.stripe_customer_id
      : null;

  const expiresTimestamp = premiumExpiresAt ? Date.parse(premiumExpiresAt) : undefined;
  const isActive =
    !!profileData?.is_premium &&
    (!expiresTimestamp || Number.isNaN(expiresTimestamp) || expiresTimestamp > Date.now());

  const trialTimestamp = premiumTrialEndsAt ? Date.parse(premiumTrialEndsAt) : undefined;
  const trialIsActive = !!trialTimestamp && !Number.isNaN(trialTimestamp) && trialTimestamp > Date.now();

  return {
    profile,
    streak,
    premium: {
      is_active: isActive,
      entitlement_source: premiumSource,
      expires_at: premiumExpiresAt,
      trial: {
        is_trial: trialIsActive,
        trial_ends_at: premiumTrialEndsAt,
      },
      plan_id: premiumPlanId,
      customer_id: stripeCustomerId,
    },
  };
};
