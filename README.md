# FixMate

FixMate is a Flutter marketplace for customers, technicians, and suppliers. Authentication and profile data use Supabase; the Node API handles phone-number sign-in and secure Fapshi subscription payments.

## Run the app

Install Flutter dependencies, then run the Flutter app as usual. To enable phone sign-in and subscription checkout, build or run it with the URL of the deployed FixMate API:

```sh
flutter run --dart-define=FIXMATE_API_URL=https://api.example.com
```

Email/password sign-in continues to use Supabase directly. Phone/password sign-in uses the API to resolve a unique Cameroon phone number to its account; Supabase still verifies the password and issues the user's normal session.

## Build for iPhone

The repository includes the Flutter iOS runner and iPhone app icon assets. Building or signing an iOS app requires macOS with Xcode; iOS apps cannot be compiled or signed from this Windows development environment.

On a Mac with Flutter and Xcode installed:

1. Open `ios/Runner.xcworkspace` in Xcode, select the **Runner** target, and set **Signing & Capabilities → Team** to your Apple developer team.
2. Replace the example bundle identifier `com.example.fixmate` in the Runner target's **Signing & Capabilities** with a unique identifier registered to your Apple developer account.
3. From the repository root, fetch packages and run on a connected iPhone or iOS simulator:

   ```sh
   flutter pub get
   flutter run -d <device-id> --dart-define=FIXMATE_API_URL=https://your-deployed-api.example.com
   ```

4. To build a signed release archive for distribution, use Xcode's **Product → Archive**. For an unsigned release build to inspect or archive with Xcode later:

   ```sh
   flutter build ios --release --dart-define=FIXMATE_API_URL=https://your-deployed-api.example.com
   ```

The deployed API URL must use HTTPS. App Store or TestFlight distribution also requires Apple Developer account access and valid signing/provisioning; set up App Store Connect listing, privacy disclosures, and review requirements before submission. The app asks iPhone users for photo-library access when suppliers select product photos.

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

Signup requires a syntactically valid email, a valid Cameroon phone number, and a password of at least eight characters containing uppercase, lowercase, and numeric characters. The app offers email OTP verification through Supabase or WhatsApp OTP verification through Twilio Verify. An email can only be confirmed as deliverable and controlled by the user by successfully verifying the code; syntax checks alone cannot determine whether a mailbox exists. With WhatsApp selected, the required email remains unverified until the user separately confirms it. A database unique index prevents normalized phone numbers from being reused.

For email signup, enable email confirmations in Supabase Auth, configure the confirmation email template to display `{{ .Token }}`, and set the OTP length to six digits. Configure Supabase Auth's password policy to require at least 8 characters, uppercase, lowercase, and digits so API clients cannot bypass the app's password checks. Use a working SMTP provider and appropriate OTP expiry and rate limits.

For WhatsApp signup, enable Supabase phone authentication and deploy the API with `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `TWILIO_VERIFY_SERVICE_SID` set as server-only secrets. Supabase phone SMS delivery is not used: Twilio Verify delivers and checks the WhatsApp code. The Twilio Verify service must have WhatsApp enabled and be approved/configured for the regions where it will be used. Never include these credentials in the Flutter app or commit real values. The API verifies the OTP before creating an account, marks only the phone as confirmed, then returns the normal Supabase session. The app also applies a per-process one-code-per-minute send cooldown; configure provider-side limits for distributed deployments.

Password recovery sends a generic response to avoid confirming whether an email is registered, requires a numeric recovery token and a strong new password, and applies a client-side resend cooldown. Configure the Supabase recovery email template to include the OTP token (`{{ .Token }}`), set an appropriate token expiry and rate limits in Supabase Auth, and ensure the project has a working SMTP provider. Recovery verification does not end an existing app session for an invalid code; after successful verification the recovery session is signed out so the user must log in with the new password.

## Tests

Run Flutter checks with `flutter analyze` and `flutter test`. Run API unit tests with `npm test`. Product checkout tests mock both Supabase and Fapshi; they do not reserve production stock or make a real charge.
The API exposes `/health/live` for process liveness and `/health/ready` to check configured Supabase, Fapshi, and exchange-rate dependencies without exposing credentials. The checkout-to-activation API test uses mocked upstream responses; it does not create a real Fapshi transaction. Before launch, complete a real sandbox payment manually using Fapshi's sandbox checkout and test numbers, then confirm the app shows an active subscription.

Before launch, also apply and verify every migration in a staging Supabase project, set the Fapshi environment to sandbox, test successful/failed/expired subscription and product payments, confirm stock restoration and supplier order visibility, configure Supabase SMTP, and then rotate/configure production credentials. The API health endpoint cannot verify database migrations or a real payment.

**Credential rotation:** Credentials were present in the local `.env.example`, and Fapshi credentials were previously embedded in the Flutter client source. Revoke/rotate the affected Supabase and Fapshi credentials before deployment; removing them from current files does not remove them from prior Git history or distributed app builds.
