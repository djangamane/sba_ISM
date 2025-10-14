import dotenv from 'dotenv';

dotenv.config();

const env = {
  port: Number.parseInt(process.env.PORT ?? '4000', 10),
  nodeEnv: process.env.NODE_ENV ?? 'development',
  openAiProxyUrl: process.env.OPENAI_PROXY_URL ?? 'https://api.openai.com/v1/chat/completions',
  openAiApiKey: process.env.OPENAI_API_KEY ?? '',
  openAiAssistantId: process.env.OPENAI_ASSISTANT_ID ?? '',
  supabaseUrl: process.env.SUPABASE_URL ?? '',
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY ?? '',
  revenueCatApiUrl: process.env.REVENUECAT_API_URL ?? 'https://api.revenuecat.com/v1',
  revenueCatApiKey: process.env.REVENUECAT_API_KEY ?? '',
  revenueCatWebhookSecret: process.env.REVENUECAT_WEBHOOK_SECRET ?? '',
};

export default env;
