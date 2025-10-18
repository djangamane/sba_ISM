import { Request, Response } from 'express';
import env from '../config/env';
import { stripeClient, isStripeConfigured } from '../services/stripeClient';
import { handleStripeEvent } from '../services/stripeBilling';

const stripeWebhookHandler = async (req: Request, res: Response) => {
  if (!isStripeConfigured || !stripeClient) {
    return res.status(501).json({ error: 'Stripe is not configured.' });
  }

  if (!env.stripeWebhookSecret) {
    return res.status(501).json({ error: 'Stripe webhook secret not configured.' });
  }

  const signature = req.headers['stripe-signature'];
  if (!signature || typeof signature !== 'string') {
    return res.status(400).json({ error: 'Missing Stripe signature header.' });
  }

  const payload = req.body;

  let event: any;
  try {
    event = stripeClient.webhooks.constructEvent(payload, signature, env.stripeWebhookSecret);
  } catch (error) {
    console.error('Stripe webhook signature verification failed', error);
    return res.status(400).json({ error: 'Webhook signature verification failed.' });
  }

  try {
    await handleStripeEvent(event);
  } catch (error) {
    console.error('Stripe webhook processing failed', error);
    return res.status(500).json({ error: 'Failed to process webhook.' });
  }

  return res.json({ received: true });
};

export default stripeWebhookHandler;
