import { supabaseAdmin, isSupabaseAdminAvailable } from './supabaseClient';

export const logUsage = async (userId: string | undefined, endpoint: string) => {
  if (!isSupabaseAdminAvailable || !supabaseAdmin) {
    return;
  }

  try {
    await supabaseAdmin.from('usage_logs').insert({
      user_id: userId ?? null,
      endpoint,
    });
  } catch (error) {
    console.error('Failed to log usage', error);
  }
};
