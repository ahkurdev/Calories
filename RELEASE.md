# Caloris 1.0 Release Runbook

## External configuration required

- Set `SUPABASE_URL` and a publishable/legacy anon key in the untracked `.env`.
- Set at least one backend provider key with `supabase secrets set`; never put it
  in Flutter, `.env`, or Git.
- For OpenCode Zen, explicitly set `OPENCODE_ALLOWED_MODELS` and, for food scan,
  `OPENCODE_VISION_MODELS`.
- In hosted Supabase Auth, require email confirmation, minimum 8-character
  letter+digit passwords, secure password changes, and allow
  `caloris://reset-password`.
- Confirm the permanent Android application ID and iOS bundle ID before the
  first store upload; changing them later creates a different application.
- Create private Android upload signing material and iOS distribution signing.

## Android signing

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Replace every placeholder with the private upload-key values.
3. Keep `key.properties`, `.jks`, and `.keystore` files outside Git and back them
   up in an approved secret store.
4. Build with:

```bash
flutter build appbundle --release --dart-define-from-file=.env
```

Release builds intentionally fail if `android/key.properties` is absent.

## Pre-launch gate

```bash
flutter pub get
flutter analyze
flutter test
npx --yes deno fmt --check supabase/functions
npx --yes deno test --allow-env supabase/functions/_shared/tests
supabase db advisors --linked --type security --level warn --fail-on error
supabase db advisors --linked --type performance --level warn --fail-on error
```

Also verify all five functions are active with JWT verification, perform an
authenticated smoke test with the configured provider, test offline add/sync on
a physical device, and test camera/notification permissions on Android and iOS.

Current toolchain note: `flutter_timezone` still applies the legacy Kotlin
Gradle plugin. The present debug build succeeds, but update the plugin when it
adds Built-in Kotlin support before adopting a Flutter release that enforces the
new requirement.

## Staged rollout

1. Internal test build with mock AI clearly enabled or production AI secrets in
   a non-production Supabase project.
2. Closed beta with production AI enabled for a small tester group.
3. Advance only when error rate stays within 10% of baseline and p95 AI latency
   stays within 20%; hold above those thresholds.
4. Roll back if errors exceed twice baseline, latency rises over 50%, security
   issues appear, or data integrity is affected.

Monitor Edge Function error/rate-limit counts, provider latency, database
advisor findings, crash-free sessions, and SQLite outbox depth. Do not log image
base64, provider keys, email, or health payloads.

## Rollback

- Mobile: halt store rollout and restore the previous signed artifact.
- Edge Functions: redeploy the previous known-good Git commit with `--use-api`.
- AI emergency stop: set `OPENROUTER_ENABLED=false` and
  `OPENCODE_ENABLED=false`; clients retain manual fallback.
- Database: do not edit applied migrations. Add a reviewed forward-fix migration
  and preserve user records unless deletion is explicitly required.
