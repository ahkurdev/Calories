# Caloris

**Track. Balance. Progress.**

Caloris is a Flutter application for calorie, food, weight, water, light
activity, schedule, reminder, and healthy-habit tracking. The product uses
Flutter, Riverpod, and Supabase. AI is limited to typed Caloris features and is
never a general chatbot or coding/file assistant.

## Current status

Phases 1–4 are implemented:

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

Phase 5 AI backend work is tracked in [`tasks/plan.md`](tasks/plan.md). Until it
is configured, production mode gives an honest manual-input fallback.

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

The URL scheme is registered in Android and iOS project files. For production,
prefer verified Android App Links and iOS Universal Links before release.

Google Sign-In is not exposed yet because it requires project-specific OAuth,
SHA, bundle ID, and callback configuration. This avoids a dead production
button. It can be enabled later when those credentials are available.

## AI and Edge Functions

Dual-provider AI is planned for Phase 5 and is not presented as active now. The
backend will use feature-specific Edge Functions such as `analyze-food` and
`recommend-meal`; there will be no `ask-ai` or general chat endpoint.

When those functions are implemented, store provider keys only as Edge Function
secrets:

```bash
supabase secrets set OPENROUTER_API_KEY=YOUR_KEY
supabase secrets set OPENCODE_API_KEY=YOUR_KEY
```

Do not commit these values, return them from an Edge Function, or place them in
Flutter. OpenRouter will be free-model-only by default, and OpenCode Zen will use
only a server-side model allowlist.

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

## Testing

```bash
flutter analyze
flutter test
```

The current tests cover configuration, calorie calculations, Auth, profile,
food aggregation, progress, schedule validation, scan schema bounds, the visible
estimate disclaimer, and the explicit mock label.

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

iOS must be built on macOS with a configured signing team:

```bash
flutter build ios --release --dart-define-from-file=.env
```

Release signing values and real `.env` files must remain outside Git.

## Architecture

```text
UI
  → Riverpod controller
    → repository interface
      → Supabase repository implementation
        → Supabase Auth / Data API / Storage / Edge Function
```

Domain code does not import Supabase. Widgets never issue SQL or provider API
requests. See [`tasks/plan.md`](tasks/plan.md) and [`tasks/todo.md`](tasks/todo.md)
for the architecture decisions, AI restrictions, migration plan, and phased
acceptance criteria.
