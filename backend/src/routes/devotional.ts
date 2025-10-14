import { Router } from 'express';
import { AuthenticatedRequest } from '../middleware/auth';
import { logUsage } from '../services/usageLogger';
import { ensureDevotionalAccess } from '../services/entitlements';
import env from '../config/env';
import { getOpenAiClient, isOpenAiConfigured } from '../services/openai';

interface DevotionalRequestBody {
  verseText?: string;
  verseReference?: string;
  persona?: {
    goal?: string;
    familiarity?: string;
    preferences?: string[];
  };
}

const router = Router();

const DEVOTIONAL_INSTRUCTIONS = `Compose a 180-220 word devotional reflection. Structure:
- Begin with a warm, empathetic tone referencing the provided verse.
- Offer Neville Goddard-aligned insight that bridges scripture with imagination/assumption.
- Provide one actionable practice or affirmation for the reader today.
- Close with a short, hopeful encouragement (no generic sign-off).`;

router.post('/', async (req: AuthenticatedRequest, res, next) => {
  const { verseText, verseReference, persona } = (req.body ?? {}) as DevotionalRequestBody;
  const userId = req.userId;

  const access = await ensureDevotionalAccess(userId);
  if (!access.allowed) {
    return res.status(402).json({
      error: access.message ?? 'Upgrade required to continue.',
      code: 'PAYWALL',
    });
  }

  if (!verseText || !verseReference) {
    return res.status(400).json({
      error: '`verseText` and `verseReference` are required',
    });
  }

  if (!isOpenAiConfigured()) {
    return res.status(503).json({
      error: 'OpenAI credentials are not configured on the server.',
    });
  }

  try {
    const client = getOpenAiClient();

    const personaSummary = [
      persona?.goal ? `User goal: ${persona.goal}.` : null,
      persona?.familiarity ? `Neville familiarity: ${persona.familiarity}.` : null,
      persona?.preferences?.length
        ? `Preferred tone/content: ${persona.preferences.join(', ')}.`
        : null,
    ]
      .filter(Boolean)
      .join(' ');

    const thread = await client.beta.threads.create();

    const prompt = `Verse: ${verseReference}\nText: ${verseText}\n${personaSummary}\n${DEVOTIONAL_INSTRUCTIONS}`;

    await client.beta.threads.messages.create(thread.id, {
      role: 'user',
      content: prompt,
    });

    const run = await client.beta.threads.runs.create(thread.id, {
      assistant_id: env.openAiAssistantId,
    });

    let runStatus = run;
    let attempts = 0;
    const maxAttempts = 30;

    while (
      (runStatus.status === 'queued' || runStatus.status === 'in_progress') &&
      attempts < maxAttempts
    ) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      runStatus = await client.beta.threads.runs.retrieve(thread.id, run.id);
      attempts += 1;
    }

    if (runStatus.status !== 'completed') {
      return res.status(500).json({
        error: `Assistant run failed with status ${runStatus.status}`,
      });
    }

    const messages = await client.beta.threads.messages.list(thread.id, {
      limit: 5,
      order: 'desc',
    });

    const assistantMessage = messages.data.find((item) => item.role === 'assistant');

    const devotional = assistantMessage?.content
      .flatMap((entry) => (entry.type === 'text' ? entry.text?.value ?? '' : ''))
      .join('\n')
      .trim();

    if (!devotional) {
      return res.status(500).json({ error: 'Assistant returned an empty devotional.' });
    }

    await logUsage(userId, 'devotional');

    return res.json({ devotional, userId });
  } catch (error) {
    return next(error);
  }
});

export default router;
