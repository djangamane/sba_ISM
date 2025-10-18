import { Router } from 'express';
import healthRouter from './health';
import chatRouter from './chat';
import devotionalRouter from './devotional';
import paywallRouter from './paywall';
import profileRouter from './profile';
import stripeRouter from './stripe';
import { requireAuth } from '../middleware/auth';
import { rateLimit, DEFAULT_CHAT_LIMIT, DEFAULT_DEVOTIONAL_LIMIT } from '../middleware/rateLimit';

const router = Router();

router.use('/health', healthRouter);
router.use('/v1/chat', requireAuth, rateLimit(DEFAULT_CHAT_LIMIT), chatRouter);
router.use('/v1/devotional', requireAuth, rateLimit(DEFAULT_DEVOTIONAL_LIMIT), devotionalRouter);
router.use('/v1/paywall', requireAuth, paywallRouter);
router.use('/v1/profile', requireAuth, profileRouter);
router.use('/v1/stripe', stripeRouter);

export default router;
