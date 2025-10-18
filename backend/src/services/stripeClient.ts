import Stripe from 'stripe';

import env from '../config/env';

let client: Stripe | null = null;

if (env.stripeSecretKey) {
  try {
    client = new Stripe(env.stripeSecretKey, {
      apiVersion: '2024-06-20',
    });
  } catch (error) {
    console.error('Failed to initialize Stripe client', error);
    client = null;
  }
} else {
  console.warn('Stripe secret key not configured; premium checkout disabled.');
}

export const stripeClient = client;
export const isStripeConfigured = !!client;
