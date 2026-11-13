const test = require('node:test');
const assert = require('node:assert/strict');

const requiredEnvironment = [
  'FIXMATE_STAGING_SUPABASE_URL',
  'FIXMATE_STAGING_ANON_KEY',
  'FIXMATE_STAGING_TECHNICIAN_TOKEN',
  'FIXMATE_STAGING_SUPPLIER_TOKEN',
  'FIXMATE_STAGING_ADMIN_TOKEN',
];
const missingEnvironment = requiredEnvironment.filter((name) => !process.env[name]);

test('staging provider verification and admin access smoke test', {
  skip: missingEnvironment.length
    ? `Set dedicated staging credentials: ${missingEnvironment.join(', ')}`
    : false,
}, async (t) => {
  const supabaseUrl = process.env.FIXMATE_STAGING_SUPABASE_URL.replace(/\/+$/, '');
  const anonKey = process.env.FIXMATE_STAGING_ANON_KEY;
  const users = {};

  async function request(path, token, options = {}) {
    return fetch(`${supabaseUrl}${path}`, {
      ...options,
      headers: {
        apikey: anonKey,
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...options.headers,
      },
    });
  }

  async function read(path, token) {
    const response = await request(path, token);
    assert.equal(response.status, 200, `${path} returned ${response.status}`);
    return response.json();
  }

  for (const [role, envName] of [
    ['Technician', 'FIXMATE_STAGING_TECHNICIAN_TOKEN'],
    ['Supplier', 'FIXMATE_STAGING_SUPPLIER_TOKEN'],
    ['Admin', 'FIXMATE_STAGING_ADMIN_TOKEN'],
  ]) {
    const token = process.env[envName];
    const authResponse = await request('/auth/v1/user', token);
    assert.equal(authResponse.status, 200, `${role} token is not valid`);
    const authUser = await authResponse.json();
    const profiles = await read(
      `/rest/v1/profiles?id=eq.${encodeURIComponent(authUser.id)}&select=id,role`,
      token,
    );
    assert.equal(profiles.length, 1, `Missing ${role} staging profile`);
    assert.equal(profiles[0].role, role);
    users[role] = { id: authUser.id, token };
  }

  for (const role of ['Technician', 'Supplier']) {
    const user = users[role];
    const verificationRows = await read(
      `/rest/v1/business_verifications?user_id=eq.${encodeURIComponent(user.id)}&select=user_id,role,status,created_at`,
      user.token,
    );
    assert.equal(verificationRows.length, 1, `Missing ${role} verification record`);
    const verification = verificationRows[0];

    const ownDocuments = await read(
      `/rest/v1/business_verification_documents?user_id=eq.${encodeURIComponent(user.id)}&select=id,user_id,document_key`,
      user.token,
    );
    assert.ok(Array.isArray(ownDocuments));

    const subscriptions = await read(
      `/rest/v1/subscriptions?user_id=eq.${encodeURIComponent(user.id)}&role=eq.${role}&select=status,expires_at`,
      user.token,
    );
    const hasActiveSubscription = subscriptions.some(
      (subscription) => subscription.status === 'active'
        && Date.parse(subscription.expires_at) > Date.now(),
    );
    const shouldBeListed = role === 'Technician'
      ? Date.parse(verification.created_at) > Date.now() - 7 * 24 * 60 * 60_000
        || ['submitted', 'approved', 'rejected'].includes(verification.status)
        || hasActiveSubscription
      : verification.status === 'approved' && hasActiveSubscription;
    const activeListings = await read(
      `/rest/v1/active_business_profiles?provider_id=eq.${encodeURIComponent(user.id)}&select=provider_id,role,verified`,
      user.token,
    );
    assert.equal(
      activeListings.length === 1,
      shouldBeListed,
      `${role} listing does not match its verification/subscription eligibility`,
    );
    if (shouldBeListed) {
      assert.equal(activeListings[0].verified,
        verification.status === 'approved' && hasActiveSubscription);
    }
  }

  const technician = users.Technician;
  const supplier = users.Supplier;
  for (const [reader, owner] of [
    [technician, supplier],
    [supplier, technician],
  ]) {
    const response = await read(
      `/rest/v1/business_verification_documents?user_id=eq.${encodeURIComponent(owner.id)}&select=id`,
      reader.token,
    );
    assert.deepEqual(response, [], "Provider could read another provider's documents");
  }

  const nonAdminAudit = await read(
    '/rest/v1/business_verification_audit?select=id',
    technician.token,
  );
  assert.deepEqual(nonAdminAudit, [], 'Provider could read admin audit records');

  for (const rpc of [
    'admin_list_business_verifications',
    'admin_list_business_verification_audit',
  ]) {
    const response = await request(`/rest/v1/rpc/${rpc}`, users.Admin.token, {
      method: 'POST',
      body: '{}',
    });
    assert.equal(response.status, 200, `Admin RPC ${rpc} failed`);
    assert.ok(Array.isArray(await response.json()));
  }

  const providerAdminResponse = await request(
    '/rest/v1/rpc/admin_list_business_verification_audit',
    technician.token,
    { method: 'POST', body: '{}' },
  );
  assert.ok(
    providerAdminResponse.status >= 400,
    'Non-admin could invoke admin audit listing',
  );

  await t.test('optional sandbox subscription payment status check', async (paymentTest) => {
    const transactionId = process.env.FIXMATE_STAGING_SUBSCRIPTION_TRANSACTION_ID;
    const apiUrl = process.env.FIXMATE_STAGING_API_URL;
    if (!transactionId || !apiUrl) {
      paymentTest.skip(
        'Set a dedicated sandbox transaction ID and staging API URL to check payment status.',
      );
      return;
    }
    const response = await fetch(
      `${apiUrl.replace(/\/+$/, '')}/api/subscriptions/${encodeURIComponent(transactionId)}/status`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${technician.token}`,
          'Content-Type': 'application/json',
        },
      },
    );
    assert.equal(response.status, 200, 'Could not verify sandbox subscription status');
    const result = await response.json();
    assert.ok(['pending', 'active', 'failed', 'expired'].includes(result.status));
  });
});
