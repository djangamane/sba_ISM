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
  stripeSecretKey: process.env.STRIPE_SECRET_KEY ?? '',
  stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET ?? '',
  stripePriceMonthly: process.env.STRIPE_PRICE_MONTHLY ?? '',
  stripePriceAnnual: process.env.STRIPE_PRICE_ANNUAL ?? '',
  stripeSuccessUrl: process.env.STRIPE_SUCCESS_URL ?? '',
  stripeCancelUrl: process.env.STRIPE_CANCEL_URL ?? '',
  stripePortalReturnUrl: process.env.STRIPE_PORTAL_RETURN_URL ?? '',
};

export default env;
