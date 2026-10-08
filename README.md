# FixMate

FixMate is a Flutter marketplace for customers, technicians, and suppliers. Authentication and profile data use Supabase; the Node API handles phone-number sign-in and secure Fapshi subscription payments.

## Run the app

Install Flutter dependencies, then run the Flutter app as usual. To enable phone sign-in and subscription checkout, build or run it with the URL of the deployed FixMate API:

```sh
flutter run --dart-define=FIXMATE_API_URL=https://api.example.com
```

Email/password sign-in continues to use Supabase directly. Phone/password sign-in uses the API to resolve a unique Cameroon phone number to its account; Supabase still verifies the password and issues the user's normal session.

## Run the API

Use Node.js 18 or newer. Use `.env.example` as a list of the settings to add to your hosting provider's secret/environment configuration, then start the server with `npm start`. The server does not load `.env` files automatically. Never commit real credentials.

Required settings:

| Setting | Purpose |
| --- | --- |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Public/anon key used to validate user sessions and proxy password verification |
| `SUPABASE_SERVICE_ROLE_KEY` | Server-only key for profile lookup and subscription writes |
| `FAPSHI_API_USER`, `FAPSHI_API_KEY` | Server-only Fapshi API credentials |
| `FAPSHI_BASE_URL` | `https://sandbox.fapshi.com` or `https://live.fapshi.com` |
| `CORS_ALLOWED_ORIGIN` | Optional allowed Flutter web origin |
| `FAPSHI_WEBHOOK_SECRET` | Optional shared secret; omit it if Fapshi does not provide webhook secrets |

Set `FAPSHI_BASE_URL` and credentials to the same environment. Fapshi may also require the API server's IP address to be allowlisted. Live direct-pay is not used; the app opens Fapshi's hosted checkout.

## Supabase and Fapshi setup

1. Apply the SQL migrations in `supabase/migrations/` to the Supabase project, in filename order. In addition to phone sign-in, subscriptions, and ratings, they enforce unique normalized Cameroon phone numbers, create the server-only product checkout/payment functions, and configure the public product-image bucket with active-supplier upload permissions. The latest `20261008235000_marketplace_management.sql` migration adds multi-photo product galleries, listing visibility, customer product reports, order notifications, and admin moderation/account-management RPCs. The phone-integrity migration stops with an actionable error if existing profiles contain duplicate normalized phone numbers; resolve those records and retry it.
2. Deploy the API over HTTPS and set its environment variables. Configure the Flutter `FIXMATE_API_URL` to that deployment.
3. If Fapshi supports webhook setup for your service, configure `https://api.example.com/api/fapshi/webhook` and set `FAPSHI_WEBHOOK_SECRET` to the same secret. Both settings are optional; without them, the app checks transaction status directly with Fapshi after the user taps “Check payment status”.
4. Test in sandbox, including successful and failed payments, before switching both the Fapshi base URL and credentials to live.

Subscription plans display USD prices: technicians pay USD 9 monthly or USD 90 yearly; suppliers pay USD 34 monthly or USD 340 yearly. At checkout, the API fetches the latest available USD/XAF rate from ExchangeRate-API, converts the fixed USD price to the nearest whole XAF amount required by Fapshi, and stores both the quoted rate and resulting amount with the pending subscription. This quote is fixed for that payment attempt; starting a new attempt fetches a fresh rate. The app shows prices in USD, while Fapshi requests the converted XAF amount.

The API computes prices from the authenticated account role and selected plan; it does not trust a client-supplied amount or payment status. Payment completion is verified against Fapshi and recorded server-side. The app’s authenticated status-check flow is the fallback when no webhook secret is configured; webhook notifications are disabled in that case.

Product checkout uses the same hosted Fapshi flow. The API reads product prices from Supabase, atomically reserves available stock, and creates a pending order before it starts payment. Stock is restored if Fapshi reports a failed or expired payment; an unpaid reservation expires after 24 hours and is released the next time a checkout is created. The app clears the cart only after the server verifies payment. Product catalog prices remain in FCFA because they are the actual amount due; subscription plans alone are displayed in USD. Existing products are initialized with one unit when `in_stock` is true and zero otherwise. Suppliers can manage stock quantities in the product editor.

Suppliers can post and edit product details, stock, listing visibility, and up to five product photos. Photos are resized/compressed in the app and stored in the public `product-images` bucket (JPEG, PNG, or WebP, max 5 MB each). Uploads are restricted by Storage policies to the signed-in supplier's folder and active subscription; viewers can fetch public listing images. Product details include the full description and photo gallery, and customers can submit one report per product.

Customers and suppliers receive in-app notifications when a product order is paid or its fulfillment status changes. Enable `user_notifications` in Supabase Realtime if it is not already added by the marketplace-management migration. Admin accounts can review/hide product listings, resolve reports, and suspend or restore accounts from the Admin dashboard. Suspension also blocks future Supabase authentication/refresh; an access token already issued to a signed-in session can remain valid until its normal expiry.

Signup validates email, Cameroon phone format, and password strength in the client, while a database unique index prevents normalized phone numbers from being reused. Phone numbers are not OTP-verified; phone login is a lookup plus normal Supabase password authentication. For recovery by numeric code, configure the Supabase recovery email template to include the OTP token (`{{ .Token }}`) and ensure the project has a working SMTP provider.

## Tests

Run Flutter checks with `flutter analyze` and `flutter test`. Run API unit tests with `npm test`. Product checkout tests mock both Supabase and Fapshi; they do not reserve production stock or make a real charge.
The API exposes `/health/live` for process liveness and `/health/ready` to check configured Supabase, Fapshi, and exchange-rate dependencies without exposing credentials. The checkout-to-activation API test uses mocked upstream responses; it does not create a real Fapshi transaction. Before launch, complete a real sandbox payment manually using Fapshi's sandbox checkout and test numbers, then confirm the app shows an active subscription.

Before launch, also apply and verify every migration in a staging Supabase project, set the Fapshi environment to sandbox, test successful/failed/expired subscription and product payments, confirm stock restoration and supplier order visibility, configure Supabase SMTP, and then rotate/configure production credentials. The API health endpoint cannot verify database migrations or a real payment.

**Credential rotation:** Credentials were present in the local `.env.example`, and Fapshi credentials were previously embedded in the Flutter client source. Revoke/rotate the affected Supabase and Fapshi credentials before deployment; removing them from current files does not remove them from prior Git history or distributed app builds.
