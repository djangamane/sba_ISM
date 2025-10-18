import { Router, Response } from 'express';

import { AuthenticatedRequest } from '../middleware/auth';
import { grantDemoPremium } from '../services/entitlements';
import { createStripeCheckoutSession } from '../services/stripeBilling';

const router = Router();

router.post('/grant-demo', async (req: AuthenticatedRequest, res: Response) => {
  const userId = req.userId;
  if (!userId) {
    return res.status(401).json({ error: 'Sign in required.' });
  }

  try {
    await grantDemoPremium(userId);
    return res.json({ success: true });
  } catch (error) {
    console.error('Failed to grant demo premium', error);
    return res.status(500).json({ error: 'Unable to upgrade at this time.' });
  }
});

router.post('/stripe-checkout', async (req: AuthenticatedRequest, res: Response) => {
  if (!req.userId) {
    return res.status(401).json({ error: 'Sign in required.' });
  }

  const planId =
    typeof req.body?.planId === 'string' && req.body.planId === 'premium_annual'
      ? 'premium_annual'
      : 'premium_monthly';

  try {
    const checkoutUrl = await createStripeCheckoutSession(req.userId, planId, req.userEmail);
    return res.json({ checkoutUrl });
  } catch (error) {
    console.error('Failed to create Stripe checkout session', error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : 'Unable to create Stripe checkout session.',
    });
  }
});

export default router;
