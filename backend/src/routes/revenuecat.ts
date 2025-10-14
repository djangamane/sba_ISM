import { Router, Request, Response } from 'express';
import env from '../config/env';
import { processRevenueCatWebhook } from '../services/revenuecat';

const router = Router();

router.post('/webhook', async (req: Request, res: Response) => {
  if (!env.revenueCatWebhookSecret) {
    return res.status(501).json({ error: 'RevenueCat webhook secret not configured.' });
  }

  const providedSecretHeader = req.headers['x-authorization'];
  const providedSecret = Array.isArray(providedSecretHeader)
    ? providedSecretHeader[0]
    : providedSecretHeader;

  if (!providedSecret || providedSecret !== env.revenueCatWebhookSecret) {
    return res.status(401).json({ error: 'Invalid webhook authorization.' });
  }

  try {
    const result = await processRevenueCatWebhook(req.body);
    return res.json(result);
  } catch (error) {
    console.error('RevenueCat webhook processing failed', error);
    return res.status(500).json({ error: 'Failed to process webhook.' });
  }
});

export default router;
