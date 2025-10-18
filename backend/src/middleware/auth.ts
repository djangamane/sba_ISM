import { NextFunction, Request, Response } from 'express';
import { supabaseAdmin, isSupabaseAdminAvailable } from '../services/supabaseClient';
import env from '../config/env';

export interface AuthenticatedRequest extends Request {
  userId?: string;
  userEmail?: string;
}

export const requireAuth = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  if (!isSupabaseAdminAvailable || !supabaseAdmin) {
    if (env.nodeEnv === 'development' || env.nodeEnv === 'test') {
      return next();
    }
    return res.status(500).json({
      error:
        'Supabase service role credentials are not configured. Configure SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY on the server.',
    });
  }

  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing authorization header' });
    }

    const accessToken = header.slice('Bearer '.length);
    const { data, error } = await supabaseAdmin.auth.getUser(accessToken);
    if (error || !data?.user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    req.userId = data.user.id;
    req.userEmail = data.user.email ?? undefined;
    return next();
  } catch (error) {
    console.error('Auth middleware failed', error);
    return res.status(500).json({ error: 'Failed to validate authentication token' });
  }
};
