const crypto = require('node:crypto');
const express = require('express');

const app = express();
app.use(express.json({ limit: '16kb' }));
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', process.env.CORS_ALLOWED_ORIGIN || '*');
  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

const plans = {
  Technician: {
    monthly: { usdAmount: 9 },
    yearly: { usdAmount: 90 },
  },
  Supplier: {
    monthly: { usdAmount: 34 },
    yearly: { usdAmount: 340 },
  },
};
const exchangeRateUrl = 'https://open.er-api.com/v6/latest/USD';
const statusChecks = new Map();

function config(requireFapshi = true) {
  const values = {
    supabaseUrl: process.env.SUPABASE_URL,
    anonKey: process.env.SUPABASE_ANON_KEY,
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  };
  if (requireFapshi) {
    Object.assign(values, {
      fapshiApiUser: process.env.FAPSHI_API_USER,
      fapshiApiKey: process.env.FAPSHI_API_KEY,
      fapshiBaseUrl: process.env.FAPSHI_BASE_URL,
    });
  }
  const missing = Object.entries(values)
    .filter(([, value]) => !value)
    .map(([name]) => name);
  if (missing.length) {
    throw new Error(`Missing required environment settings: ${missing.join(', ')}`);
  }
  if (
    requireFapshi &&
    !['https://sandbox.fapshi.com', 'https://live.fapshi.com'].includes(values.fapshiBaseUrl)
  ) {
    throw new Error('FAPSHI_BASE_URL must be the official sandbox or live endpoint.');
  }
  values.supabaseUrl = values.supabaseUrl.replace(/\/+$/, '');
  if (requireFapshi) {
    values.fapshiWebhookSecret = process.env.FAPSHI_WEBHOOK_SECRET || '';
  }
  return values;
}

function normalizeCameroonPhone(value) {
  let digits = String(value ?? '').replace(/\D/g, '');
  if (digits.startsWith('237') && digits.length === 12) digits = digits.slice(3);
  if (digits.startsWith('0') && digits.length === 10) digits = digits.slice(1);
  return /^([26]\d{8})$/.test(digits) ? digits : null;
}

function getPlan(role, plan) {
  return plans[role]?.[plan] ?? null;
}

function convertUsdToXaf(usdAmount, rate) {
  if (
    !Number.isFinite(usdAmount) ||
    usdAmount <= 0 ||
    !Number.isFinite(rate) ||
    rate <= 0
  ) {
    throw new Error('A valid USD price and USD/XAF exchange rate are required.');
  }
  return Math.round(usdAmount * rate);
}

async function getUsdToXafRate() {
  const response = await fetch(exchangeRateUrl, {
    signal: AbortSignal.timeout(10_000),
  });
  const result = await readJson(response);
  const rate = result?.rates?.XAF;
  if (
    !response.ok ||
    result.result !== 'success' ||
    result.base_code !== 'USD' ||
    !Number.isFinite(rate) ||
    rate <= 0
  ) {
    throw new Error('Could not retrieve a valid USD/XAF exchange rate.');
  }
  return rate;
}

async function checkUpstream(url, headers = {}) {
  const response = await fetch(url, {
    headers,
    signal: AbortSignal.timeout(10_000),
  });
  if (response.body) await response.body.cancel();
  return response.ok;
}

function isFapshiCheckoutUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === 'https:' &&
      (url.hostname === 'fapshi.com' || url.hostname.endsWith('.fapshi.com'));
  } catch {
    return false;
  }
}

function allowStatusCheck(userId, transId, now = Date.now()) {
  const key = `${userId}:${transId}`;
  const recentChecks = (statusChecks.get(key) ?? []).filter(
    (timestamp) => now - timestamp < 60_000,
  );
  if (recentChecks.length >= 5) {
    statusChecks.set(key, recentChecks);
    return false;
  }
  recentChecks.push(now);
  statusChecks.set(key, recentChecks);

  if (statusChecks.size > 10_000) {
    for (const [storedKey, timestamps] of statusChecks) {
      if (timestamps.every((timestamp) => now - timestamp >= 60_000)) {
        statusChecks.delete(storedKey);
      }
    }
  }
  return true;
}

function serviceHeaders(cfg, extra = {}) {
  return {
    apikey: cfg.serviceRoleKey,
    Authorization: `Bearer ${cfg.serviceRoleKey}`,
    'Content-Type': 'application/json',
    ...extra,
  };
}

async function readJson(response) {
  const body = await response.text();
  try {
    return body ? JSON.parse(body) : {};
  } catch {
    throw new Error('The upstream service returned an invalid response.');
  }
}

async function findUserByPhone(cfg, phone) {
  const response = await fetch(`${cfg.supabaseUrl}/rest/v1/rpc/lookup_profile_user_by_phone`, {
    method: 'POST',
    headers: serviceHeaders(cfg),
    body: JSON.stringify({ p_phone: phone }),
  });
  if (!response.ok) throw new Error('Phone lookup is unavailable.');
  const result = await readJson(response);
  return Array.isArray(result) && result.length === 1 ? result[0].user_id : null;
}

async function getAdminUser(cfg, userId) {
  const response = await fetch(`${cfg.supabaseUrl}/auth/v1/admin/users/${encodeURIComponent(userId)}`, {
    headers: serviceHeaders(cfg),
  });
  if (!response.ok) throw new Error('Account lookup is unavailable.');
  return readJson(response);
}

async function getFapshiTransaction(cfg, transId) {
  const response = await fetch(
    `${cfg.fapshiBaseUrl}/payment-status/${encodeURIComponent(transId)}`,
    {
      headers: {
        apiuser: cfg.fapshiApiUser,
        apikey: cfg.fapshiApiKey,
      },
    },
  );
  const result = await readJson(response);
  if (!response.ok) throw new Error(result.message || 'Could not verify payment status.');
  return result;
}

async function getSubscription(cfg, filters) {
  const query = new URLSearchParams({ select: '*', ...filters });
  const response = await fetch(`${cfg.supabaseUrl}/rest/v1/subscriptions?${query}`, {
    headers: serviceHeaders(cfg),
  });
  if (!response.ok) throw new Error('Could not load subscription.');
  const rows = await readJson(response);
  return Array.isArray(rows) ? rows[0] ?? null : null;
}

async function updatePendingSubscription(cfg, subscription, status) {
  const response = await fetch(
    `${cfg.supabaseUrl}/rest/v1/subscriptions?id=eq.${encodeURIComponent(subscription.id)}&status=eq.pending`,
    {
      method: 'PATCH',
      headers: serviceHeaders(cfg, { Prefer: 'return=minimal' }),
      body: JSON.stringify({ status }),
    },
  );
  if (!response.ok) throw new Error('Could not update subscription status.');
}

async function createProductOrder(cfg, userId, items, externalId) {
  const response = await fetch(
    `${cfg.supabaseUrl}/rest/v1/rpc/create_product_order_checkout`,
    {
      method: 'POST',
      headers: serviceHeaders(cfg),
      body: JSON.stringify({
        p_customer_id: userId,
        p_items: items,
        p_external_id: externalId,
      }),
    },
  );
  const result = await readJson(response);
  if (!response.ok) {
    throw new Error(result.message || 'Could not reserve the items in this order.');
  }
  return result;
}

async function cancelProductOrder(cfg, orderId, reason) {
  const response = await fetch(
    `${cfg.supabaseUrl}/rest/v1/rpc/cancel_product_order_checkout`,
    {
      method: 'POST',
      headers: serviceHeaders(cfg),
      body: JSON.stringify({
        p_order_id: orderId,
        p_reason: reason,
      }),
    },
  );
  if (!response.ok) throw new Error('Could not release the order inventory reservation.');
}

async function applyProductOrderPaymentStatus(cfg, payment, transaction) {
  if (
    transaction.transId !== payment.fapshi_trans_id ||
    Number(transaction.amount) !== payment.amount ||
    transaction.externalId !== payment.external_id ||
    (transaction.userId && transaction.userId !== payment.customer_id)
  ) {
    throw new Error('Payment details do not match the product order.');
  }

  if (transaction.status === 'SUCCESSFUL') {
    const response = await fetch(
      `${cfg.supabaseUrl}/rest/v1/rpc/complete_product_order_payment`,
      {
        method: 'POST',
        headers: serviceHeaders(cfg),
        body: JSON.stringify({ p_trans_id: payment.fapshi_trans_id }),
      },
    );
    if (!response.ok) throw new Error('Could not confirm the product order payment.');
    return 'paid';
  }

  if (transaction.status === 'FAILED' || transaction.status === 'EXPIRED') {
    await cancelProductOrder(cfg, payment.order_id, transaction.status.toLowerCase());
    return 'failed';
  }
  return payment.status;
}

async function validateAndApplyStatus(cfg, subscription, transaction) {
  if (
    transaction.transId !== subscription.fapshi_trans_id ||
    Number(transaction.amount) !== subscription.amount ||
    transaction.externalId !== subscription.external_id ||
    (transaction.userId && transaction.userId !== subscription.user_id)
  ) {
    throw new Error('Payment details do not match the pending subscription.');
  }

  if (transaction.status === 'SUCCESSFUL') {
    const response = await fetch(`${cfg.supabaseUrl}/rest/v1/rpc/activate_subscription`, {
      method: 'POST',
      headers: serviceHeaders(cfg),
      body: JSON.stringify({ p_trans_id: subscription.fapshi_trans_id }),
    });
    if (!response.ok) throw new Error('Could not activate subscription.');
    return 'active';
  }

  const status = {
    FAILED: 'failed',
    EXPIRED: 'expired',
  }[transaction.status];
  if (status) await updatePendingSubscription(cfg, subscription, status);
  return status ?? subscription.status;
}

function requireFapshiConfig(req, res, next) {
  try {
    req.config = config();
    next();
  } catch (error) {
    console.error(error.message);
    res.status(503).json({ error: 'The payment service is not configured.' });
  }
}

function requireSupabaseConfig(req, res, next) {
  try {
    req.config = config(false);
    next();
  } catch (error) {
    console.error(error.message);
    res.status(503).json({ error: 'Phone sign-in is not configured.' });
  }
}

app.get('/health/live', (_req, res) => {
  res.json({ status: 'alive' });
});

app.get('/health/ready', async (_req, res) => {
  let cfg;
  try {
    cfg = config();
  } catch (error) {
    return res.status(503).json({
      status: 'not_ready',
      checks: { configuration: false },
    });
  }

  const results = await Promise.allSettled([
    checkUpstream(`${cfg.supabaseUrl}/rest/v1/`, serviceHeaders(cfg)),
    checkUpstream(`${cfg.fapshiBaseUrl}/balance`, {
      apiuser: cfg.fapshiApiUser,
      apikey: cfg.fapshiApiKey,
    }),
    getUsdToXafRate(),
  ]);
  const checks = {
    supabase: results[0].status === 'fulfilled' && results[0].value,
    fapshi: results[1].status === 'fulfilled' && results[1].value,
    exchangeRate: results[2].status === 'fulfilled',
  };
  const ready = Object.values(checks).every(Boolean);
  res.status(ready ? 200 : 503).json({
    status: ready ? 'ready' : 'not_ready',
    checks,
  });
});

async function requireUser(req, res, next) {
  const match = /^Bearer\s+(.+)$/i.exec(req.get('authorization') || '');
  if (!match) return res.status(401).json({ error: 'Please sign in and try again.' });

  try {
    const response = await fetch(`${req.config.supabaseUrl}/auth/v1/user`, {
      headers: {
        apikey: req.config.anonKey,
        Authorization: `Bearer ${match[1]}`,
      },
    });
    if (!response.ok) return res.status(401).json({ error: 'Please sign in and try again.' });
    req.user = await readJson(response);
    next();
  } catch (error) {
    console.error('Session validation failed:', error.message);
    res.status(503).json({ error: 'Could not validate your session. Please try again.' });
  }
}

app.post('/api/auth/phone-login', requireSupabaseConfig, async (req, res) => {
  const phone = normalizeCameroonPhone(req.body?.phone);
  const password = req.body?.password;
  if (!phone || typeof password !== 'string' || password.length === 0 || password.length > 256) {
    return res.status(400).json({ error: 'Incorrect phone number or password.' });
  }

  try {
    const userId = await findUserByPhone(req.config, phone);
    if (!userId) return res.status(401).json({ error: 'Incorrect phone number or password.' });

    const user = await getAdminUser(req.config, userId);
    if (typeof user.email !== 'string' || !user.email) {
      return res.status(401).json({ error: 'Incorrect phone number or password.' });
    }

    const response = await fetch(
      `${req.config.supabaseUrl}/auth/v1/token?grant_type=password`,
      {
        method: 'POST',
        headers: {
          apikey: req.config.anonKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email: user.email, password }),
      },
    );
    const result = await readJson(response);
    if (!response.ok || typeof result.refresh_token !== 'string') {
      return res.status(401).json({ error: 'Incorrect phone number or password.' });
    }
    res.json({ refreshToken: result.refresh_token });
  } catch (error) {
    console.error('Phone sign-in failed:', error.message);
    res.status(503).json({ error: 'Phone sign-in is temporarily unavailable.' });
  }
});

app.post('/api/subscriptions/checkout', requireFapshiConfig, requireUser, async (req, res) => {
  try {
    const profileResponse = await fetch(
      `${req.config.supabaseUrl}/rest/v1/profiles?id=eq.${encodeURIComponent(req.user.id)}&select=role`,
      { headers: serviceHeaders(req.config) },
    );
    if (!profileResponse.ok) throw new Error('Could not load account profile.');
    const profiles = await readJson(profileResponse);
    const profile = Array.isArray(profiles) ? profiles[0] : null;
    const plan = getPlan(profile?.role, req.body?.plan);
    if (!profile || !plan || !req.user.email) {
      return res.status(400).json({ error: 'This account cannot purchase the selected plan.' });
    }

    let exchangeRate;
    try {
      exchangeRate = await getUsdToXafRate();
    } catch (error) {
      console.error('Exchange rate lookup failed:', error.message);
      return res.status(503).json({
        error: 'The current exchange rate is unavailable. No payment was started; please retry shortly.',
      });
    }
    const amountXaf = convertUsdToXaf(plan.usdAmount, exchangeRate);
    const externalId = `sub_${crypto.randomUUID()}`;
    const fapshiResponse = await fetch(`${req.config.fapshiBaseUrl}/initiate-pay`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apiuser: req.config.fapshiApiUser,
        apikey: req.config.fapshiApiKey,
      },
      body: JSON.stringify({
        amount: amountXaf,
        email: req.user.email,
        userId: req.user.id,
        externalId,
        message: `${profile.role} ${req.body.plan} subscription - FixMate`,
      }),
    });
    const transaction = await readJson(fapshiResponse);
    if (
      !fapshiResponse.ok ||
      typeof transaction.transId !== 'string' ||
      typeof transaction.link !== 'string'
    ) {
      console.error('Fapshi checkout rejected:', transaction.message || fapshiResponse.status);
      return res.status(502).json({ error: 'Fapshi could not start this payment. Please try again.' });
    }

    const checkoutUrl = new URL(transaction.link);
    if (!isFapshiCheckoutUrl(checkoutUrl.toString())) {
      throw new Error('Fapshi returned an unexpected checkout URL.');
    }

    const saveResponse = await fetch(`${req.config.supabaseUrl}/rest/v1/subscriptions`, {
      method: 'POST',
      headers: serviceHeaders(req.config, { Prefer: 'return=minimal' }),
      body: JSON.stringify({
        user_id: req.user.id,
        role: profile.role,
        plan: req.body.plan,
        amount: amountXaf,
        usd_amount: plan.usdAmount,
        usd_to_xaf_rate: exchangeRate,
        external_id: externalId,
        fapshi_trans_id: transaction.transId,
        status: 'pending',
      }),
    });
    if (!saveResponse.ok) {
      console.error('Could not save pending subscription:', await saveResponse.text());
      return res.status(503).json({ error: 'Could not save this payment. Please try again.' });
    }

    res.json({ link: checkoutUrl.toString(), transId: transaction.transId });
  } catch (error) {
    console.error('Checkout initiation failed:', error.message);
    res.status(503).json({ error: 'Could not start this payment. Please try again.' });
  }
});

app.post('/api/orders/checkout', requireFapshiConfig, requireUser, async (req, res) => {
  const items = req.body?.items;
  const checkoutId = req.body?.checkoutId;
  if (
    !Array.isArray(items) ||
    items.length < 1 ||
    items.length > 25 ||
    items.some(
      (item) =>
        !item ||
        typeof item.product_id !== 'string' ||
        !/^[0-9a-f-]{36}$/i.test(item.product_id) ||
        !Number.isInteger(item.quantity) ||
        item.quantity < 1 ||
        item.quantity > 50,
    ) ||
    typeof checkoutId !== 'string' ||
    !/^[0-9a-f-]{36}$/i.test(checkoutId)
  ) {
    return res.status(400).json({ error: 'The cart contains invalid items or quantities.' });
  }
  if (!req.user.email) {
    return res.status(400).json({ error: 'Add a verified email to your account before checkout.' });
  }

  let orderId;
  let paymentInitiated = false;
  try {
    const externalId = `order_${checkoutId.toLowerCase()}`;
    const order = await createProductOrder(req.config, req.user.id, items, externalId);
    orderId = order.order_id;
    const amount = Number(order.amount);
    if (typeof orderId !== 'string' || !Number.isInteger(amount) || amount < 100) {
      throw new Error('Order service returned invalid order details.');
    }

    if (!order.created) {
      const existingResponse = await fetch(
        `${req.config.supabaseUrl}/rest/v1/product_order_payments?external_id=eq.${encodeURIComponent(externalId)}&customer_id=eq.${encodeURIComponent(req.user.id)}&select=*`,
        { headers: serviceHeaders(req.config) },
      );
      if (!existingResponse.ok) throw new Error('Could not load the existing product payment.');
      const existingRows = await readJson(existingResponse);
      const existingPayment = Array.isArray(existingRows) ? existingRows[0] : null;
      if (existingPayment?.status === 'pending' &&
          existingPayment.fapshi_trans_id &&
          isFapshiCheckoutUrl(existingPayment.checkout_link)) {
        return res.json({
          orderId,
          link: existingPayment.checkout_link,
          transId: existingPayment.fapshi_trans_id,
          amount,
        });
      }
      return res.status(409).json({
        error: 'This checkout is already being processed. Check its status before starting another payment.',
      });
    }

    const fapshiResponse = await fetch(`${req.config.fapshiBaseUrl}/initiate-pay`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apiuser: req.config.fapshiApiUser,
        apikey: req.config.fapshiApiKey,
      },
      body: JSON.stringify({
        amount,
        email: req.user.email,
        userId: req.user.id,
        externalId,
        message: 'FixMate product order',
      }),
    });
    const transaction = await readJson(fapshiResponse);
    if (
      !fapshiResponse.ok ||
      typeof transaction.transId !== 'string' ||
      typeof transaction.link !== 'string' ||
      !isFapshiCheckoutUrl(transaction.link)
    ) {
      throw new Error(transaction.message || 'Fapshi could not start this payment.');
    }
    paymentInitiated = true;

    const saveResponse = await fetch(
      `${req.config.supabaseUrl}/rest/v1/product_order_payments?order_id=eq.${encodeURIComponent(orderId)}&customer_id=eq.${encodeURIComponent(req.user.id)}&status=eq.pending`,
      {
        method: 'PATCH',
        headers: serviceHeaders(req.config, { Prefer: 'return=representation' }),
        body: JSON.stringify({
          fapshi_trans_id: transaction.transId,
          checkout_link: new URL(transaction.link).toString(),
        }),
      },
    );
    if (!saveResponse.ok) throw new Error('Could not save the payment record.');
    const savedPayments = await readJson(saveResponse);
    if (!Array.isArray(savedPayments) || savedPayments.length !== 1) {
      throw new Error('Could not attach Fapshi transaction to the product order.');
    }

    res.json({
      orderId,
      link: new URL(transaction.link).toString(),
      transId: transaction.transId,
      amount,
    });
  } catch (error) {
    console.error('Product checkout failed:', error.message);
    if (orderId && !paymentInitiated) {
      try {
        await cancelProductOrder(req.config, orderId, 'checkout_failed');
      } catch (releaseError) {
        console.error('Could not release product order:', releaseError.message);
      }
    }
    res.status(503).json({
      error: paymentInitiated
        ? 'Fapshi started this payment, but its checkout reference could not be saved. Do not start a new payment; retry this checkout or contact support.'
        : 'Could not start checkout. No payment was initiated; please try again.',
      retryable: !paymentInitiated,
    });
  }
});

app.post('/api/orders/recover', requireFapshiConfig, requireUser, async (req, res) => {
  const checkoutId = req.body?.checkoutId;
  if (typeof checkoutId !== 'string' || !/^[0-9a-f-]{36}$/i.test(checkoutId)) {
    return res.status(400).json({ error: 'The checkout reference is invalid.' });
  }

  try {
    const externalId = `order_${checkoutId.toLowerCase()}`;
    const response = await fetch(
      `${req.config.supabaseUrl}/rest/v1/product_order_payments?external_id=eq.${encodeURIComponent(externalId)}&customer_id=eq.${encodeURIComponent(req.user.id)}&select=order_id,status,fapshi_trans_id,checkout_link`,
      { headers: serviceHeaders(req.config) },
    );
    if (!response.ok) throw new Error('Could not recover the product checkout.');
    const rows = await readJson(response);
    const payment = Array.isArray(rows) ? rows[0] : null;
    if (!payment) return res.status(404).json({ error: 'No product checkout was found.' });

    res.json({
      orderId: payment.order_id,
      status: payment.status,
      transId: payment.fapshi_trans_id,
      link: payment.checkout_link,
    });
  } catch (error) {
    console.error('Product checkout recovery failed:', error.message);
    res.status(503).json({ error: 'Could not recover this checkout yet. Please try again.' });
  }
});

app.post('/api/orders/:orderId/status', requireFapshiConfig, requireUser, async (req, res) => {
  try {
    const response = await fetch(
      `${req.config.supabaseUrl}/rest/v1/product_order_payments?order_id=eq.${encodeURIComponent(req.params.orderId)}&customer_id=eq.${encodeURIComponent(req.user.id)}&select=*`,
      { headers: serviceHeaders(req.config) },
    );
    if (!response.ok) throw new Error('Could not load product order payment.');
    const rows = await readJson(response);
    const payment = Array.isArray(rows) ? rows[0] : null;
    if (!payment) return res.status(404).json({ error: 'Order payment was not found.' });

    if (payment.status === 'pending') {
      if (!payment.fapshi_trans_id) return res.json({ status: 'pending' });
      if (!allowStatusCheck(req.user.id, payment.fapshi_trans_id)) {
        res.setHeader('Retry-After', '60');
        return res.status(429).json({ error: 'Please wait before checking this payment again.' });
      }
      const transaction = await getFapshiTransaction(
        req.config,
        payment.fapshi_trans_id,
      );
      const status = await applyProductOrderPaymentStatus(
        req.config,
        payment,
        transaction,
      );
      return res.json({ status });
    }
    res.json({ status: payment.status });
  } catch (error) {
    console.error('Product order payment verification failed:', error.message);
    res.status(503).json({ error: 'Could not verify this payment yet. Please try again.' });
  }
});

app.post('/api/subscriptions/:transId/status', requireFapshiConfig, requireUser, async (req, res) => {
  try {
    const subscription = await getSubscription(req.config, {
      fapshi_trans_id: `eq.${req.params.transId}`,
      user_id: `eq.${req.user.id}`,
    });
    if (!subscription) return res.status(404).json({ error: 'Payment was not found.' });

    if (subscription.status === 'pending') {
      if (!allowStatusCheck(req.user.id, subscription.fapshi_trans_id)) {
        res.setHeader('Retry-After', '60');
        return res.status(429).json({ error: 'Please wait before checking this payment again.' });
      }
      const transaction = await getFapshiTransaction(req.config, subscription.fapshi_trans_id);
      const status = await validateAndApplyStatus(req.config, subscription, transaction);
      return res.json({ status });
    }
    res.json({ status: subscription.status });
  } catch (error) {
    console.error('Payment verification failed:', error.message);
    res.status(503).json({ error: 'Could not verify payment yet. Please try again.' });
  }
});

app.post('/api/fapshi/webhook', requireFapshiConfig, async (req, res) => {
  if (!req.config.fapshiWebhookSecret) {
    return res.status(503).json({ error: 'Fapshi webhook notifications are not configured.' });
  }
  const suppliedSecret = req.get('x-wh-secret') || '';
  const expectedSecret = req.config.fapshiWebhookSecret;
  const supplied = Buffer.from(suppliedSecret);
  const expected = Buffer.from(expectedSecret);
  if (supplied.length !== expected.length || !crypto.timingSafeEqual(supplied, expected)) {
    return res.sendStatus(401);
  }

  const transId = req.body?.transId;
  if (typeof transId !== 'string' || !transId) return res.sendStatus(400);

  try {
    const subscription = await getSubscription(req.config, {
      fapshi_trans_id: `eq.${transId}`,
    });
    if (subscription) {
      await validateAndApplyStatus(req.config, subscription, req.body);
      return res.sendStatus(200);
    }

    const paymentResponse = await fetch(
      `${req.config.supabaseUrl}/rest/v1/product_order_payments?fapshi_trans_id=eq.${encodeURIComponent(transId)}&select=*`,
      { headers: serviceHeaders(req.config) },
    );
    if (!paymentResponse.ok) throw new Error('Could not load product payment.');
    const paymentRows = await readJson(paymentResponse);
    const payment = Array.isArray(paymentRows) ? paymentRows[0] : null;
    if (!payment) return res.sendStatus(404);
    const transaction = await getFapshiTransaction(req.config, transId);
    await applyProductOrderPaymentStatus(req.config, payment, transaction);
    res.sendStatus(200);
  } catch (error) {
    console.error('Fapshi webhook processing failed:', error.message);
    res.sendStatus(500);
  }
});

if (require.main === module) {
  const port = Number(process.env.PORT || 3000);
  app.listen(port, () => console.log(`FixMate API listening on port ${port}`));
}

module.exports = {
  allowStatusCheck,
  app,
  config,
  convertUsdToXaf,
  getPlan,
  getUsdToXafRate,
  isFapshiCheckoutUrl,
  normalizeCameroonPhone,
};
