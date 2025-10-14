import { Router, Response } from 'express';

import { AuthenticatedRequest } from '../middleware/auth';
import { grantDemoPremium } from '../services/entitlements';

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

export default router;
