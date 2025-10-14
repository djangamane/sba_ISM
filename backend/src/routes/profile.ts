import { Router } from 'express';
import { AuthenticatedRequest } from '../middleware/auth';
import { getFullProfile } from '../services/profile';

const router = Router();

router.get('/', async (req: AuthenticatedRequest, res) => {
  const userId = req.userId;
  if (!userId) {
    return res.status(401).json({ error: 'Sign in required.' });
  }

  try {
    const profile = await getFullProfile(userId);
    return res.json(profile);
  } catch (error) {
    console.error('Failed to fetch profile', error);
    return res.status(500).json({ error: 'Unable to load profile at this time.' });
  }
});

export default router;
