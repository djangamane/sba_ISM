import { Router } from 'express';
import { Router } from 'express';
import { AuthenticatedRequest } from '../middleware/auth';
import { createStripePortalSession } from '../services/stripeBilling';

const router = Router();

router.post('/portal', async (req: AuthenticatedRequest, res) => {
  if (!req.userId) {
    return res.status(401).json({ error: 'Sign in required.' });
  }

  try {
    const portalUrl = await createStripePortalSession(req.userId);
    return res.json({ portalUrl });
  } catch (error) {
    console.error('Failed to create Stripe portal session', error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : 'Unable to create Stripe billing portal session.',
    });
  }
});

export default router;
