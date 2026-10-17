# 2pi STORE — Flutter project for Klencod IDE

Arabic RTL, black/purple digital storefront starter. Official store identifier remains `2pi` / `2pi STORE`.

## Open it in Klencod IDE
1. Download and extract `2pi-store-flutter.zip` on your phone.
2. In Klencod IDE (prefer the current version), choose **Import Project / ZIP** and select the extracted project folder or ZIP.
3. Confirm it is recognized as a Flutter project (`pubspec.yaml`, `lib/main.dart`).
4. The project now includes the Android Gradle configuration that was missing in the previous ZIP. Fetch dependencies / `flutter pub get`, then run or build an APK. If Klencod reports that the Gradle wrapper is missing, run `flutter create --platforms=android --org com.twopi.store .` once in the project terminal, then run `flutter pub get` again. If the IDE asks for GitHub authorization to build in the cloud, follow its own GitHub device-flow screen; do not paste access tokens into source files.
5. For a local-only visual trial, run without defines. The app clearly labels order creation as demo-only and does not charge money.

## Android build fix
The earlier archive did not include the `android/` platform folder, which caused the exact `android/app/build.gradle` missing-file error shown in Klencod. This archive includes Android Gradle files and a GitHub Actions workflow that regenerates the complete Android platform (including wrapper files) before building. The Flutter compiler was not available in this environment, so a successful APK build cannot be claimed until Klencod/GitHub runs it.

## Current working features
- Responsive Flutter UI for phone and tablet widths, Arabic RTL presentation, black/purple branding.
- Product grid, category filters, search, cart quantities, sample coupon `2PI10`, checkout form and input validation.
- Sign-up/sign-in screens wired to Supabase Auth when configuration is supplied.
- Optional order insertion to Supabase when configured; orders remain `pending` and `awaiting_payment`.
- Starter database schema and row-level security policies in `supabase/schema.sql`.

## Configure Supabase (test project first)
1. Create a Supabase project and review `supabase/schema.sql`; run it in the SQL editor of a **test** project.
2. Add the sample products to `public.products` manually before wiring the app to load catalogue data dynamically. The current catalogue is local sample data.
3. Run with compile-time configuration:

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Use only the Supabase publishable/anon key in a client app. NEVER put a `service_role` key, payment secret, email-provider secret, or other private key in Flutter source or app builds.

## Important gaps before real launch
This is a runnable **starter app**, not a complete production commerce system. Do not accept real payments or real customer orders yet. Specifically:
- Prices and the sample coupon are currently demo values in the app. A trusted server/Edge Function must calculate prices and validate coupons from the database; clients must not be trusted for totals.
- Card payments are not connected. Add a provider that legally supports the merchant's country and target countries, using its hosted checkout and signed server-side webhooks. Never collect card numbers in this app.
- Local transfers are not verified automatically. Keep orders pending until an authorized admin verifies the transfer through a protected back office.
- The admin panel, influencer/coupon management, payouts, order-history UI, email verification UX, password reset UX, CAPTCHA/anti-bot verification, rate limiting, audit workflows, refund handling, and privacy/terms pages still need server-backed implementation and testing.
- For mobile apps, web Turnstile is not a drop-in native CAPTCHA; select an appropriate mobile attestation / anti-abuse solution and verify it server-side.
- Supabase Auth is configured only when the two compile-time values are supplied. Email confirmation settings must be configured in Supabase.
- Add your real support email, store domain, legal business details, currency/localization rules, refund policy and privacy policy before release.

## Production checklist
- Server-authoritative order and coupon calculation.
- Admin role assigned only via trusted Supabase `app_metadata`, never from user-editable metadata.
- Signed payment webhook with replay protection and idempotency.
- Manual transfer review and auditable delivery state changes.
- Rate limiting, anti-bot validation, email confirmation, password reset and MFA for admins.
- RLS policy tests for every table; backup and monitoring plan.
- Test orders, refunds, duplicate webhook events, invalid coupons, and unauthorized admin attempts before launch.
