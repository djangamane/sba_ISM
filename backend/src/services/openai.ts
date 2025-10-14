import OpenAI from 'openai';
import env from '../config/env';

let client: OpenAI | null = null;

export const getOpenAiClient = (): OpenAI => {
  if (!env.openAiApiKey) {
    throw new Error('OPENAI_API_KEY is not configured.');
  }

  if (!client) {
    client = new OpenAI({
      apiKey: env.openAiApiKey,
    });
  }

  return client;
};

export const isOpenAiConfigured = (): boolean =>
  Boolean(env.openAiApiKey && env.openAiAssistantId);

