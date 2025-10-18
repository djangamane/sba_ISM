import { Router } from 'express';
import env from '../config/env';

const router = Router();

router.post('/webhook', (req, res) => {
  if (!env.stripeWebhookSecret) {
    return res
      .status(501)
      .json({ error: 'Stripe webhook secret not configured. Configure STRIPE_WEBHOOK_SECRET before enabling webhooks.' });
  }

  return res.status(501).json({ error: 'Stripe webhook handling not implemented yet.' });
});

export default router;
