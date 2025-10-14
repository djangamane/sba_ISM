import { Router, Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middleware/auth';
import env from '../config/env';
import { getOpenAiClient, isOpenAiConfigured } from '../services/openai';
import { logUsage } from '../services/usageLogger';
import { ensureChatAccess } from '../services/entitlements';

const router = Router();

const sleep = (ms: number) =>
  new Promise((resolve) => {
    setTimeout(resolve, ms);
  });

router.post('/', async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  const { message, threadId } = req.body ?? {};
  const userId = req.userId;

  const access = await ensureChatAccess(userId);
  if (!access.allowed) {
    return res.status(402).json({
      error: access.message ?? 'Upgrade required to continue.',
      code: 'PAYWALL',
    });
  }

  if (!message || typeof message !== 'string') {
    return res.status(400).json({ error: '`message` is required in request body' });
  }

  if (!isOpenAiConfigured()) {
    return res.status(503).json({
      error: 'OpenAI credentials are not configured on the server.',
    });
  }

  try {
    const client = getOpenAiClient();
    let activeThreadId: string | undefined =
      typeof threadId === 'string' && threadId.length > 0 ? threadId : undefined;

    if (!activeThreadId) {
      const thread = await client.beta.threads.create();
      activeThreadId = thread.id;
    }

    if (!activeThreadId) {
      throw new Error('Unable to resolve assistant thread.');
    }

    await client.beta.threads.messages.create(activeThreadId, {
      role: 'user',
      content: message,
    });

    const run = await client.beta.threads.runs.create(activeThreadId, {
      assistant_id: env.openAiAssistantId,
    });

    let runStatus = run;
    const maxAttempts = 30;
    let attempts = 0;

    while (
      (runStatus.status === 'queued' || runStatus.status === 'in_progress') &&
      attempts < maxAttempts
    ) {
      await sleep(1000);
      runStatus = await client.beta.threads.runs.retrieve(activeThreadId, run.id);
      attempts += 1;
    }

    if (runStatus.status !== 'completed') {
      return res.status(500).json({
        error: `Assistant run failed with status ${runStatus.status}`,
        threadId: activeThreadId,
      });
    }

    const messages = await client.beta.threads.messages.list(activeThreadId, {
      limit: 5,
      order: 'desc',
    });

    const assistantResponse = messages.data.find((item: any) => item.role === 'assistant');

    const textResponse = assistantResponse?.content
      .flatMap((contentItem: any) => {
        if (contentItem.type === 'text') {
          return contentItem.text?.value ?? '';
        }

        return '';
      })
      .join('\n')
      .trim();

    if (!textResponse) {
      return res.status(500).json({
        error: 'Assistant returned an empty response.',
        threadId: activeThreadId,
      });
    }

    await logUsage(userId, 'chat');

    return res.json({
      message: textResponse,
      threadId: activeThreadId,
      userId,
    });
  } catch (error) {
    return next(error);
  }
});

export default router;
