declare module 'stripe' {
  export default class Stripe {
    constructor(apiKey: string, options?: any);
    checkout: {
      sessions: {
        create: (params: any) => Promise<any>;
        retrieve: (id: string) => Promise<any>;
      };
    };
    billingPortal: {
      sessions: {
        create: (params: any) => Promise<any>;
      };
    };
    subscriptions: {
      retrieve: (id: string) => Promise<any>;
    };
    webhooks: {
      constructEvent: (payload: Buffer | string, signature: string, secret: string) => any;
    };
  }

  export type Event = any;
  export type Subscription = any;
  export namespace checkout {
    type Session = any;
  }
}
