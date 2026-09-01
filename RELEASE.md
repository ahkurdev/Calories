# Caloris 1.0 Android Release Runbook

iOS distribution is intentionally deferred. The current release track and its
required gates cover Android only; shared Flutter/iOS source remains preserved.

## External configuration required

- Set `SUPABASE_URL` and a publishable/legacy anon key in the untracked `.env`.
- Confirm both backend provider keys remain configured using the Supabase secret
  listing command; never put their values in Flutter, `.env`, or Git.
- For OpenCode Zen, explicitly set `OPENCODE_ALLOWED_MODELS`. Set
  `OPENCODE_VISION_MODELS` only after the catalog verifies image support; it is
  currently omitted and Android food scan uses vision-capable OpenRouter models.
- In hosted Supabase Auth, require email confirmation, minimum 8-character
  letter+digit passwords, secure password changes, and allow
  `caloris://reset-password`.
- Confirm the permanent Android application ID before the first Play Store
  upload; changing it later creates a different application.
- Create private Android upload signing material.

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
authenticated function smoke test with a real test account, test offline
add/sync on a physical Android device, and test camera/notification permissions.

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
