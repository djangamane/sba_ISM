import { NextFunction, Response } from 'express';
import { AuthenticatedRequest } from './auth';

interface RateLimiterOptions {
  windowMs: number;
  limit: number;
  scope: string;
}

const buckets = new Map<string, { count: number; expiresAt: number }>();

const cleanup = () => {
  const now = Date.now();
  for (const [key, bucket] of buckets.entries()) {
    if (bucket.expiresAt <= now) {
      buckets.delete(key);
    }
  }
};
setInterval(cleanup, 30 * 1000).unref();

export const rateLimit = ({ windowMs, limit, scope }: RateLimiterOptions) => {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const identifier = req.userId ?? req.ip ?? 'anonymous';
    const key = `${scope}:${identifier}`;
    const now = Date.now();

    const bucket = buckets.get(key);
    if (!bucket || bucket.expiresAt <= now) {
      buckets.set(key, { count: 1, expiresAt: now + windowMs });
      return next();
    }

    if (bucket.count >= limit) {
      const retryAfter = Math.ceil((bucket.expiresAt - now) / 1000);
      res.setHeader('Retry-After', retryAfter.toString());
      return res.status(429).json({
        error: 'Rate limit exceeded. Please wait before trying again.',
        retryAfterSeconds: retryAfter,
      });
    }

    bucket.count += 1;
    buckets.set(key, bucket);
    return next();
  };
};

export const DEFAULT_CHAT_LIMIT = {
  windowMs: 60 * 1000,
  limit: 30,
  scope: 'chat',
};

export const DEFAULT_DEVOTIONAL_LIMIT = {
  windowMs: 10 * 60 * 1000,
  limit: 10,
  scope: 'devotional',
};
