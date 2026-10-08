const test = require('node:test');
const assert = require('node:assert/strict');
const {
  allowStatusCheck,
  app,
  config,
  convertUsdToXaf,
  getPlan,
  isFapshiCheckoutUrl,
  normalizeCameroonPhone,
} = require('./server');

const envNames = [
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'SUPABASE_SERVICE_ROLE_KEY',
  'FAPSHI_API_USER',
  'FAPSHI_API_KEY',
  'FAPSHI_BASE_URL',
  'FAPSHI_WEBHOOK_SECRET',
];

function saveEnvironment() {
  return Object.fromEntries(envNames.map((name) => [name, process.env[name]]));
}

function restoreEnvironment(original) {
  for (const name of envNames) {
    if (original[name] === undefined) delete process.env[name];
    else process.env[name] = original[name];
  }
}

function configureTestEnvironment() {
  process.env.SUPABASE_URL = 'https://supabase.example';
  process.env.SUPABASE_ANON_KEY = 'test-anon-key';
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service-role-key';
  process.env.FAPSHI_API_USER = 'test-fapshi-user';
  process.env.FAPSHI_API_KEY = 'test-fapshi-key';
  process.env.FAPSHI_BASE_URL = 'https://sandbox.fapshi.com';
}

async function startServer(t) {
  const server = app.listen(0);
  t.after(() => {
    server.closeAllConnections();
    return new Promise((resolve) => server.close(resolve));
  });
  await new Promise((resolve) => server.once('listening', resolve));
  return `http://127.0.0.1:${server.address().port}`;
}

test('liveness endpoint reports that the process is running', async (t) => {
  const baseUrl = await startServer(t);
  const response = await fetch(`${baseUrl}/health/live`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'alive' });
});

test('readiness endpoint does not expose configuration details', async (t) => {
  const original = saveEnvironment();
  t.after(() => restoreEnvironment(original));
  for (const name of envNames) delete process.env[name];
  const baseUrl = await startServer(t);
  const response = await fetch(`${baseUrl}/health/ready`);
  assert.equal(response.status, 503);
  assert.deepEqual(await response.json(), {
    status: 'not_ready',
    checks: { configuration: false },
  });
});

test('subscription checkout converts the trusted USD plan and verifies payment', async (t) => {
  const originalEnv = saveEnvironment();
  const originalFetch = global.fetch;
  const storedTransactions = new Map();
  let fapshiRequests = 0;
  t.after(() => {
    global.fetch = originalFetch;
    restoreEnvironment(originalEnv);
  });
  configureTestEnvironment();
  delete process.env.FAPSHI_WEBHOOK_SECRET;

  global.fetch = async (input, options = {}) => {
    const url = new URL(input);
    if (url.pathname === '/auth/v1/user') {
      return Response.json({ id: 'user-1', email: 'technician@example.com' });
    }
    if (url.pathname === '/rest/v1/profiles') {
      return Response.json([{ role: 'Technician' }]);
    }
    if (url.hostname === 'open.er-api.com') {
      return Response.json({
        result: 'success',
        base_code: 'USD',
        rates: { XAF: 600.5 },
      });
    }
    if (url.pathname === '/initiate-pay') {
      fapshiRequests++;
      const request = JSON.parse(options.body);
      assert.equal(request.amount, 5405);
      const transaction = {
        transId: 'subscription-trans-1',
        link: 'https://sandbox.fapshi.com/pay/subscription-trans-1',
        amount: request.amount,
        externalId: request.externalId,
        userId: request.userId,
      };
      storedTransactions.set(transaction.transId, transaction);
      return Response.json(transaction);
    }
    if (url.pathname === '/rest/v1/subscriptions' && options.method === 'POST') {
      const row = JSON.parse(options.body);
      assert.equal(row.amount, 5405);
      assert.equal(row.usd_amount, 9);
      assert.equal(row.usd_to_xaf_rate, 600.5);
      assert.equal(row.status, 'pending');
      return new Response(null, { status: 201 });
    }
    if (url.pathname === '/rest/v1/subscriptions') {
      const transaction = storedTransactions.get('subscription-trans-1');
      return Response.json([{
        id: 'subscription-1',
        user_id: 'user-1',
        amount: transaction.amount,
        external_id: transaction.externalId,
        fapshi_trans_id: transaction.transId,
        status: 'pending',
      }]);
    }
    if (url.pathname === '/payment-status/subscription-trans-1') {
      return Response.json({
        ...storedTransactions.get('subscription-trans-1'),
        status: 'SUCCESSFUL',
      });
    }
    if (url.pathname === '/rest/v1/rpc/activate_subscription') {
      assert.deepEqual(JSON.parse(options.body), {
        p_trans_id: 'subscription-trans-1',
      });
      return new Response(null, { status: 204 });
    }
    throw new Error(`Unexpected mocked upstream request: ${url}`);
  };

  const baseUrl = await startServer(t);
  const originalRequestFetch = originalFetch;
  const checkout = await originalRequestFetch(`${baseUrl}/api/subscriptions/checkout`, {
    method: 'POST',
    headers: { Authorization: 'Bearer test-token', 'Content-Type': 'application/json' },
    body: JSON.stringify({ plan: 'monthly' }),
  });
  assert.equal(checkout.status, 200);
  assert.deepEqual(await checkout.json(), {
    link: 'https://sandbox.fapshi.com/pay/subscription-trans-1',
    transId: 'subscription-trans-1',
  });

  const status = await originalRequestFetch(
    `${baseUrl}/api/subscriptions/subscription-trans-1/status`,
    {
      method: 'POST',
      headers: { Authorization: 'Bearer test-token', 'Content-Type': 'application/json' },
      body: '{}',
    },
  );
  assert.equal(status.status, 200);
  assert.deepEqual(await status.json(), { status: 'active' });
  assert.equal(fapshiRequests, 1);
});

test('product checkout trusts the server total and rejects mismatched payment details', async (t) => {
  const originalEnv = saveEnvironment();
  const originalFetch = global.fetch;
  const externalIdByTransaction = new Map();
  let transactionAmount = 1850;
  let orderCreated = true;
  let initiateCalls = 0;
  let completeCalls = 0;
  let userId = 'customer-1';
  t.after(() => {
    global.fetch = originalFetch;
    restoreEnvironment(originalEnv);
  });
  configureTestEnvironment();

  global.fetch = async (input, options = {}) => {
    const url = new URL(input);
    if (url.pathname === '/auth/v1/user') {
      return Response.json({ id: userId, email: 'customer@example.com' });
    }
    if (url.pathname === '/rest/v1/rpc/create_product_order_checkout') {
      const request = JSON.parse(options.body);
      assert.equal(request.p_customer_id, 'customer-1');
      assert.equal(request.p_items[0].quantity, 2);
      assert.equal(
        request.p_external_id,
        'order_123e4567-e89b-42d3-a456-426614174000',
      );
      return Response.json({
        order_id: 'order-1',
        amount: 1850,
        created: orderCreated,
      });
    }
    if (url.pathname === '/initiate-pay') {
      initiateCalls++;
      const request = JSON.parse(options.body);
      assert.equal(request.amount, 1850);
      const transaction = {
        transId: 'order-trans-1',
        link: 'https://sandbox.fapshi.com/pay/order-trans-1',
        amount: request.amount,
        externalId: request.externalId,
        userId: request.userId,
      };
      externalIdByTransaction.set(transaction.transId, transaction.externalId);
      return Response.json(transaction);
    }
    if (url.pathname === '/rest/v1/product_order_payments' &&
        options.method === 'PATCH') {
      const row = JSON.parse(options.body);
      assert.equal(row.fapshi_trans_id, 'order-trans-1');
      assert.equal(row.checkout_link, 'https://sandbox.fapshi.com/pay/order-trans-1');
      return Response.json([{ order_id: 'order-1' }]);
    }
    if (url.pathname === '/rest/v1/product_order_payments' &&
        options.method !== 'PATCH') {
      if (url.searchParams.get('customer_id') !== 'eq.customer-1' ||
          userId !== 'customer-1') {
        return Response.json([]);
      }
      return Response.json([{
        order_id: 'order-1',
        customer_id: 'customer-1',
        amount: 1850,
        external_id: externalIdByTransaction.get('order-trans-1'),
        fapshi_trans_id: 'order-trans-1',
        checkout_link: 'https://sandbox.fapshi.com/pay/order-trans-1',
        status: 'pending',
      }]);
    }
    if (url.pathname === '/payment-status/order-trans-1') {
      return Response.json({
        transId: 'order-trans-1',
        amount: transactionAmount,
        externalId: externalIdByTransaction.get('order-trans-1'),
        userId: 'customer-1',
        status: 'SUCCESSFUL',
      });
    }
    if (url.pathname === '/rest/v1/rpc/complete_product_order_payment') {
      completeCalls++;
      return new Response(null, { status: 204 });
    }
    throw new Error(`Unexpected mocked upstream request: ${url}`);
  };

  const baseUrl = await startServer(t);
  const headers = {
    Authorization: 'Bearer test-token',
    'Content-Type': 'application/json',
  };
  const checkout = await originalFetch(`${baseUrl}/api/orders/checkout`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      checkoutId: '123e4567-e89b-42d3-a456-426614174000',
      items: [{ product_id: '223e4567-e89b-42d3-a456-426614174000', quantity: 2 }],
    }),
  });
  assert.equal(checkout.status, 200);
  assert.deepEqual(await checkout.json(), {
    orderId: 'order-1',
    link: 'https://sandbox.fapshi.com/pay/order-trans-1',
    transId: 'order-trans-1',
    amount: 1850,
  });

  orderCreated = false;
  const retry = await originalFetch(`${baseUrl}/api/orders/checkout`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      checkoutId: '123e4567-e89b-42d3-a456-426614174000',
      items: [{ product_id: '223e4567-e89b-42d3-a456-426614174000', quantity: 2 }],
    }),
  });
  assert.equal(retry.status, 200);
  assert.deepEqual(await retry.json(), {
    orderId: 'order-1',
    link: 'https://sandbox.fapshi.com/pay/order-trans-1',
    transId: 'order-trans-1',
    amount: 1850,
  });
  assert.equal(initiateCalls, 1);

  const recovery = await originalFetch(`${baseUrl}/api/orders/recover`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      checkoutId: '123e4567-e89b-42d3-a456-426614174000',
    }),
  });
  assert.equal(recovery.status, 200);
  assert.deepEqual(await recovery.json(), {
    orderId: 'order-1',
    status: 'pending',
    transId: 'order-trans-1',
    link: 'https://sandbox.fapshi.com/pay/order-trans-1',
  });

  transactionAmount = 999;
  const mismatch = await originalFetch(`${baseUrl}/api/orders/order-1/status`, {
    method: 'POST',
    headers,
    body: '{}',
  });
  assert.equal(mismatch.status, 503);
  assert.equal(completeCalls, 0);

  transactionAmount = 1850;
  const status = await originalFetch(`${baseUrl}/api/orders/order-1/status`, {
    method: 'POST',
    headers,
    body: '{}',
  });
  assert.equal(status.status, 200);
  assert.deepEqual(await status.json(), { status: 'paid' });
  assert.equal(completeCalls, 1);

  userId = 'different-customer';
  const otherUser = await originalFetch(`${baseUrl}/api/orders/order-1/status`, {
    method: 'POST',
    headers,
    body: '{}',
  });
  assert.equal(otherUser.status, 404);
});

test('Fapshi setup does not require a webhook secret', () => {
  const originalEnv = saveEnvironment();
  try {
    configureTestEnvironment();
    delete process.env.FAPSHI_WEBHOOK_SECRET;
    assert.equal(config().fapshiWebhookSecret, '');
  } finally {
    restoreEnvironment(originalEnv);
  }
});

test('normalizes supported Cameroon mobile number formats and rejects invalid ones', () => {
  assert.equal(normalizeCameroonPhone('+237 677 12 34 56'), '677123456');
  assert.equal(normalizeCameroonPhone('677123456'), '677123456');
  assert.equal(normalizeCameroonPhone('0677123456'), '677123456');
  assert.equal(normalizeCameroonPhone('123456789'), null);
  assert.equal(normalizeCameroonPhone('67712345'), null);
});

test('accepts only configured plan prices and converts USD to whole FCFA', () => {
  assert.equal(getPlan('Technician', 'monthly').usdAmount, 9);
  assert.equal(getPlan('Technician', 'yearly').usdAmount, 90);
  assert.equal(getPlan('Supplier', 'monthly').usdAmount, 34);
  assert.equal(getPlan('Supplier', 'yearly').usdAmount, 340);
  assert.equal(getPlan('Customer', 'monthly'), null);
  assert.equal(convertUsdToXaf(9, 600), 5400);
  assert.equal(convertUsdToXaf(1, 600.6), 601);
  assert.throws(() => convertUsdToXaf(9, 0));
});

test('checkout URLs, status polling limit, and webhook configuration are guarded', () => {
  assert.equal(isFapshiCheckoutUrl('https://pay.fapshi.com/checkout/abc'), true);
  assert.equal(isFapshiCheckoutUrl('https://attacker.example/checkout'), false);
  assert.equal(isFapshiCheckoutUrl('http://sandbox.fapshi.com/checkout'), false);
  const firstCheck = 1_000_000;
  for (let attempt = 0; attempt < 5; attempt++) {
    assert.equal(allowStatusCheck('user-1', 'trans-1', firstCheck + attempt), true);
  }
  assert.equal(allowStatusCheck('user-1', 'trans-1', firstCheck + 5), false);
  assert.equal(allowStatusCheck('user-1', 'trans-1', firstCheck + 60_001), true);
});
