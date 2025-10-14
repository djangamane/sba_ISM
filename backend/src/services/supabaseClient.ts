import { createClient, SupabaseClient } from '@supabase/supabase-js';

import env from '../config/env';

let client: SupabaseClient | null = null;

if (env.supabaseUrl && env.supabaseServiceRoleKey) {
  client = createClient(env.supabaseUrl, env.supabaseServiceRoleKey);
} else {
  console.warn('Supabase credentials not fully configured; admin client disabled.');
}

export const supabaseAdmin = client;
export const isSupabaseAdminAvailable = !!client;
