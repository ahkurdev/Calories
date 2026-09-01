# Caloris

**Track. Balance. Progress.**

Caloris is a Flutter application for calorie, food, weight, water, light
activity, schedule, reminder, and healthy-habit tracking. The product uses
Flutter, Riverpod, and Supabase. AI is limited to typed Caloris features and is
never a general chatbot or coding/file assistant.

## Current status

Phases 1–7 are implemented:

- Android/iOS Flutter project and feature-first architecture
- Material 3 light/dark themes
- Riverpod controllers and repository boundaries
- guarded navigation based on Auth and onboarding state
- register, login, logout, session persistence, forgot/reset password
- onboarding and editable profile
- complete initial PostgreSQL schema for all planned features
- explicit Data API grants, RLS, indexes, constraints, and update triggers
- private `food-scans` Storage bucket and owner-folder policies
- remote Supabase migration/advisor verification
- calorie dashboard, diary, manual food, meal builder, favorites, and quick add
- weight, water, activity, weekly schedule, and local reminder tracking
- food-only camera/gallery flow, preview, editable estimates, confirmation,
  private optional photo retention, and scan history
- explicit development mock mode that is visibly labelled and disabled by default
- authenticated, feature-specific Supabase Edge Functions for food analysis,
  meal/activity recommendations, and daily/weekly summaries
- dual-provider routing with dynamic OpenRouter free-model selection, an explicit
  OpenCode Zen allowlist, bounded retry/timeout, circuit breaking, and safe
  manual fallback
- strict task/input/output validation, prompt-injection rejection, and no
  provider secret exposure to Flutter
- deterministic daily/weekly statistics and scoped meal/activity/summary UI
- per-user SQLite profile/diary cache, idempotent food mutation outbox, visible
  pending-sync state, bounded cache retention, and logout cleanup
- release-safe Android signing configuration, changelog, rollout, monitoring,
  and rollback runbook

All five AI functions are deployed to the linked Supabase project with JWT
verification and per-user worker rate limiting enabled. Provider keys are
intentionally not committed. Until at least one provider is configured through
Edge Function secrets, authenticated requests return an honest manual-input
fallback.

## Requirements

- Flutter 3.47.2 or compatible stable version
- Dart 3.13.2 or compatible version
- Supabase CLI 2.115.0 or newer
- Android Studio/SDK for Android builds
- Xcode and CocoaPods on macOS for iOS builds
- a Supabase project

No Firebase service is used.

## Flutter setup

```bash
flutter pub get
cp .env.example .env
```

Set the public client values in `.env`:

```text
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=sb_publishable_your_key
CALORIS_USE_MOCK_AI=false
```

The variable name follows the master requirement; the value can be a current
publishable key or a compatible legacy anon key. These public keys are protected
by RLS and are not service-role secrets. Never put a service-role/secret key,
`OPENROUTER_API_KEY`, or `OPENCODE_API_KEY` in this file.

Run the application:

```bash
flutter run --dart-define-from-file=.env
```

Without these build-time values, Caloris shows an honest setup screen and does
not simulate connected behavior.

## Supabase setup

Initialize and link the repository once:

```bash
supabase login
supabase init
supabase link --project-ref YOUR_PROJECT_REF
```

This repository is already initialized. Apply versioned migrations to the linked
project:

```bash
supabase db push --linked --dry-run --skip-vault
supabase db push --linked --skip-vault
supabase migration list
```

The initial migration is
[`supabase/migrations/20260831163404_initial_caloris_schema.sql`](supabase/migrations/20260831163404_initial_caloris_schema.sql).
It creates all requested tables so none need to be created manually.

### Data API and grants

Supabase changed new-table Data API exposure behavior in 2026. The migration
therefore revokes implicit `anon` access and explicitly grants the required CRUD
operations to `authenticated`. If the project has disabled the Data API entirely,
enable it for the `public` schema in **Integrations → Data API**. RLS still decides
which rows an authenticated user may access.

### Row Level Security

Every user table has RLS enabled and four operation-specific policies:

- SELECT and DELETE use `(select auth.uid()) = id/user_id`
- INSERT uses the same ownership predicate in `WITH CHECK`
- UPDATE uses ownership checks in both `USING` and `WITH CHECK`

`anon` has no table privileges. Authorization never relies on editable Auth
`user_metadata`. Verify the linked project:

```bash
supabase db advisors --linked --type security --level warn --fail-on error
supabase db advisors --linked --type performance --level warn --fail-on error
```

### Storage

The private bucket is `food-scans`. Expected object paths are:

```text
{user_id}/{scan_id}/image.jpg
```

Storage policies compare the first folder segment to `auth.uid()`. The bucket
accepts JPEG, PNG, and WebP up to 10 MB. Food scans do not upload the selected
photo by default. A photo is uploaded only after the user explicitly disables
“Jangan simpan foto setelah analisis” and confirms saving the corrected result.

## Authentication configuration

Enable Email/Password in Supabase Auth. Add this redirect URL to the project's
Auth URL allowlist:

```text
caloris://reset-password
```

For production, configure hosted Auth to require email confirmation, passwords
of at least eight characters containing letters and digits, secure password
changes, and an appropriate email resend interval. The checked-in local config
uses those defaults, but it is not pushed wholesale because its site URL is a
local development address.

The URL scheme is registered in Android and iOS project files. For production,
prefer verified Android App Links and iOS Universal Links before release.

Google Sign-In is not exposed yet because it requires project-specific OAuth,
SHA, bundle ID, and callback configuration. This avoids a dead production
button. It can be enabled later when those credentials are available.

## AI and Edge Functions

Phase 5 exposes only these authenticated, feature-specific functions:

- `analyze-food` (`food_scan`)
- `recommend-meal` (`food_recommendation`)
- `generate-daily-summary` (`daily_summary`)
- `generate-weekly-summary` (`weekly_summary`)
- `recommend-activity` (`schedule_recommendation`)

There is no `ask-ai`, free prompt, general chat, tool execution, filesystem
access, or direct database mutation. Flutter sends typed feature data and treats
every result as an editable preview.

Store provider keys only as Edge Function secrets:

```bash
supabase secrets set OPENROUTER_API_KEY=YOUR_KEY
supabase secrets set OPENCODE_API_KEY=YOUR_KEY
```

Do not commit these values, return them from an Edge Function, or place them in
Flutter. OpenRouter dynamically queries its catalog and accepts only compatible
models with zero prompt/completion pricing; `OPENROUTER_ALLOWED_MODELS` can
further narrow that set. OpenCode Zen remains disabled until
`OPENCODE_ALLOWED_MODELS` explicitly lists compatible chat-completion model IDs.
Vision-capable Zen IDs must also appear in `OPENCODE_VISION_MODELS` before they
can receive food photos.

Optional server-only configuration:

```text
OPENROUTER_ENABLED=true
OPENROUTER_PRIORITY=1
OPENROUTER_ALLOWED_MODELS=model-a,model-b
OPENCODE_ENABLED=true
OPENCODE_PRIORITY=2
OPENCODE_ALLOWED_MODELS=model-c
OPENCODE_VISION_MODELS=model-c
AI_TIMEOUT_MS=20000
AI_MAX_RETRIES=1
AI_CIRCUIT_FAILURE_THRESHOLD=3
AI_CIRCUIT_COOLDOWN_MS=60000
AI_RATE_LIMIT_PER_MINUTE=12
```

Deploy all functions through the Supabase API without Docker:

```bash
supabase functions deploy analyze-food recommend-meal generate-daily-summary generate-weekly-summary recommend-activity --use-api --project-ref YOUR_PROJECT_REF --jobs 2
supabase functions list --project-ref YOUR_PROJECT_REF
```

The gateway and generated function wrappers both require an authenticated user.
Missing keys, provider failures, rate limits, invalid responses, and exhausted
fallbacks return a bounded manual-input response instead of fabricated food data.

## Camera permissions and development mock

The food-only scan flow uses `image_picker`. Android declares an optional camera
feature and camera permission; iOS includes these purpose strings:

Android `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

iOS `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Caloris menggunakan kamera hanya untuk memindai makanan.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Caloris menggunakan foto yang kamu pilih hanya untuk analisis makanan.</string>
```

To test the visibly labelled deterministic development result without claiming
that production AI is active, set `CALORIS_USE_MOCK_AI=true`. Keep it `false`
for production builds.

## Offline behavior

Caloris caches the authenticated profile and recently viewed food-diary days in
a per-user SQLite store. Food additions/deletions that fail because the network
is unavailable are queued with client-generated UUIDs and retried on later diary
operations. The UI shows the pending mutation count. Food-day cache entries are
retained for at most 90 days, and the current owner's cache/outbox is deleted on
successful logout. Provider responses and scan images are not cached there.

## Testing

```bash
flutter analyze
flutter test
npx --yes deno fmt --check supabase/functions
npx --yes deno test --allow-env supabase/functions/_shared/tests
npx --yes deno check --config supabase/functions/analyze-food/deno.json supabase/functions/analyze-food/index.ts
npx --yes deno check --config supabase/functions/recommend-meal/deno.json supabase/functions/recommend-meal/index.ts
npx --yes deno check --config supabase/functions/generate-daily-summary/deno.json supabase/functions/generate-daily-summary/index.ts
npx --yes deno check --config supabase/functions/generate-weekly-summary/deno.json supabase/functions/generate-weekly-summary/index.ts
npx --yes deno check --config supabase/functions/recommend-activity/deno.json supabase/functions/recommend-activity/index.ts
```

The current gate includes 34 Flutter tests and 18 Deno tests. They cover
configuration, calorie calculations, Auth, profile,
food aggregation, progress, schedule validation, scan schema bounds, the visible
estimate disclaimer, the explicit mock label, mobile function response parsing,
AI scope enforcement, free-model filtering, provider fallback, timeouts, circuit
breaking, per-user rate limiting, response normalization, prompt-injection
rejection, image media-signature validation, deterministic statistics, minimized
recommendation payloads, and offline cache/outbox behavior.

Remote database verification without Docker:

```bash
supabase migration list
supabase db advisors --linked --type security --fail-on error
supabase db advisors --linked --type performance --fail-on error
```

## Builds

Android debug APK:

```bash
flutter build apk --debug --dart-define-from-file=.env
```

Android App Bundle:

```bash
flutter build appbundle --release --dart-define-from-file=.env
```

Release builds intentionally fail until `android/key.properties` is created
from `android/key.properties.example` with private values kept outside Git.

iOS must be built on macOS with a configured signing team:

```bash
flutter build ios --release --dart-define-from-file=.env
```

Release signing values and real `.env` files must remain outside Git.
See [`RELEASE.md`](RELEASE.md) for the full external-configuration checklist,
staged rollout thresholds, monitoring, and rollback procedure. Release history
is recorded in [`CHANGELOG.md`](CHANGELOG.md).

## Architecture

```text
UI
  → Riverpod controller
    → repository interface
      → offline-first repository where applicable
        → per-user SQLite cache/outbox
        → Supabase repository implementation
          → Supabase Auth / Data API / Storage / Edge Function
```

Domain code does not import Supabase. Widgets never issue SQL or provider API
requests. See [`tasks/plan.md`](tasks/plan.md) and [`tasks/todo.md`](tasks/todo.md)
for the architecture decisions, AI restrictions, migration plan, and phased
acceptance criteria.
