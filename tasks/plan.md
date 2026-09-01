# Caloris — Product and Implementation Plan

## 1. Requirement Summary

Caloris is a multi-user Flutter application for calorie, food, weight, water,
light activity, weekly schedule, reminder, and progress tracking. Its primary
experience is daily calorie awareness and healthy weight management; it is not
a bodybuilding product. The mobile client uses Dart, Riverpod, Material 3, and
Supabase. All user-owned records are isolated in PostgreSQL with Row Level
Security (RLS).

AI is a constrained supporting capability. A user can photograph food, review
an editable estimate, and explicitly save the corrected result. OpenRouter is
the first provider and must use compatible free models only; OpenCode Zen is a
server-configured fallback. Provider secrets exist only in Supabase Edge
Function secrets. The AI surface has no free chat, arbitrary prompt, tool use,
filesystem access, coding assistance, or autonomous database writes.

Phase 1 delivers the project foundation, theming, routing, Supabase bootstrap,
email/password authentication, password recovery, session persistence,
onboarding, editable profile, the complete initial database migration, RLS,
and private food-scan storage policies. Google sign-in remains disabled until
provider credentials and platform callback configuration are supplied, so the
UI never presents a dead production action.

## 2. System Architecture

The mobile application uses feature-first Clean Architecture with this request
path:

```text
Widget/Page
  -> Riverpod controller/provider
    -> repository interface
      -> Supabase repository implementation
        -> Supabase Auth / Data API / Storage / Edge Function
```

Pure domain models and services do not import Flutter or Supabase. Repository
interfaces form the boundary between domain/application code and infrastructure.
Supabase exceptions are mapped to application failures before reaching widgets.

Runtime composition is centralized in Riverpod providers. `GoRouter` observes
authentication and profile-completion state and applies route guards:

```text
boot -> unauthenticated -> /login
     -> recovery event -> /reset-password
     -> authenticated + incomplete profile -> /onboarding
     -> authenticated + complete profile -> /home
```

Environment values are supplied at build time with
`--dart-define-from-file=.env`; only the public Supabase URL and publishable/anon
key are accepted by the mobile client.

## 3. Flutter Folder Structure

```text
lib/
  app/                    # app root and bootstrap
  core/
    config/               # build-time environment validation
    errors/               # application failure types/mapping
    routing/              # routes, guards, refresh notifier
    services/             # cross-feature pure services
    theme/                # Material 3 light/dark themes and tokens
    utils/                # validation and date helpers
  shared/
    widgets/              # reusable loading/error/form primitives
  features/
    auth/
      data/               # Supabase implementation
      domain/             # auth repository contract and state
      presentation/       # controller and pages
    onboarding/
      presentation/
    profile/
      data/
      domain/
      presentation/
    dashboard/
      presentation/
  main.dart               # minimal bootstrap only
```

Later phases add the feature folders specified in the master requirement without
moving business logic into `main.dart`.

## 4. Supabase Database Design

All identifiers are UUIDs. Every user-owned table has a `user_id` foreign key to
`auth.users(id)` with cascading deletion, except `profiles`, whose primary key
is itself the authenticated user ID. Numeric constraints reject negative or
implausible health values. Enumerated business values use `CHECK` constraints
to keep the Data API contract stable without requiring PostgreSQL enum migrations.

Initial tables:

| Table | Ownership | Important fields / behavior |
| --- | --- | --- |
| `profiles` | `id = auth.uid()` | identity, onboarding data, editable water target, timestamps |
| `food_logs` | `user_id` | meal, portion, nutrients, cooking method, logged time |
| `weight_logs` | `user_id` | weight, note, logged time |
| `water_logs` | `user_id` | milliliters, logged time |
| `activities` | `user_id` | type, duration, optional distance/burn estimate |
| `schedules` | `user_id` | weekday, time range, category, busyness |
| `reminders` | `user_id` | type, local time, enabled, repeated ISO weekdays |
| `scan_history` | `user_id` | validated AI JSON, optional private object path |
| `favorite_meals` | `user_id` | name and structured meal JSON |

Indexes begin with `user_id` and then the dominant sort/filter column (for
example `logged_at desc`). The profile row is created explicitly after
onboarding rather than by trusting mutable auth user metadata in authorization.

## 5. SQL Migration Plan

The project uses imperative, versioned migrations in `supabase/migrations/`.
The initial migration is intentionally atomic and ordered as follows:

1. Create the shared `set_updated_at()` trigger function with an explicit empty
   search path.
2. Create all nine tables, foreign keys, defaults, and validation constraints.
3. Create user/time and schedule indexes.
4. Attach update-time triggers to mutable tables.
5. Revoke implicit public/anonymous access and grant only needed CRUD operations
   to `authenticated`.
6. Enable RLS and create operation-specific ownership policies.
7. Create the private `food-scans` bucket and object policies scoped to the first
   path segment (`{auth.uid()}/{scan_id}/image.jpg`).
8. Add pgTAP RLS assertions in a later verification migration/test file when a
   local Docker-backed Supabase stack is available.

Future changes append migrations; committed migrations are never edited after
deployment.

## 6. Row Level Security Plan

RLS is enabled on every `public` table. `anon` receives no table privileges.
`authenticated` receives only `select`, `insert`, `update`, and `delete` on the
user-facing tables. Each operation has a named policy:

- SELECT/DELETE: `using ((select auth.uid()) = owner_column)`.
- INSERT: `with check ((select auth.uid()) = owner_column)`.
- UPDATE: both `using` and `with check` prevent ownership reassignment; the
  corresponding SELECT policy is always present.
- Profiles compare `auth.uid()` to `id`; other tables compare it to `user_id`.

Storage is private. Object SELECT/DELETE/UPDATE policies require both the
`food-scans` bucket and a first folder segment equal to `auth.uid()::text`.
INSERT applies the same path constraint. No service-role key is shipped to the
app. RLS never relies on editable `user_metadata`.

## 7. Dual AI Provider Architecture

```text
feature-specific Flutter request
  -> authenticated Supabase Edge Function
    -> request/schema/task validator
      -> AIScopeValidator
        -> AIProviderRouter
          -> AIModelRouter
            -> OpenRouterAIProvider
            -> OpenCodeZenAIProvider
        -> AIResponseNormalizer
      -> internal Caloris JSON response
  -> editable Flutter preview
  -> explicit user confirmation
  -> repository write
```

`AIProvider` exposes a provider-neutral structured task API. `AIProviderConfig`
is loaded server-side and carries enabled state, priority, allowlisted models,
vision requirement, timeout, retry count, fallback flag, and cost policy.
`AIErrorMapper` translates raw provider errors into the fixed Caloris error set.

## 8. OpenRouter Free Model Strategy

`OpenRouterModelService` refreshes the provider model catalog with a bounded
cache, selects only models whose effective prompt/completion/image pricing is
zero, filters for required vision/input capabilities, and ranks candidates by
task compatibility and recent health. A short server-side allow/deny list can
further constrain candidates. One free model is never hardcoded as the sole
choice. Paid candidates are rejected rather than silently used. Exhausting
compatible free candidates advances to OpenCode Zen.

## 9. OpenCode Zen Provider Strategy

OpenCode Zen is disabled unless a backend secret and explicit server-side model
allowlist are present. `OpenCodeZenAIProvider` implements the same neutral
interface and normalizes its response through the shared Caloris schema. The
router only selects a model allowed for the task and cost policy; expensive
models are never enabled implicitly. Flutter is unaware of provider or model.

## 10. AI Provider Fallback Strategy

For a vision task, the bounded sequence is compatible OpenRouter free model A,
compatible OpenRouter free model B (if configured), then an allowed OpenCode Zen
vision model, then manual input. Each attempt has a timeout and at most the
configured small retry count. Rate limiting, provider/model unavailability,
invalid response, unsupported vision, timeout, and network failures are
classified before fallback. A simple in-memory circuit breaker temporarily
deprioritizes a provider after repeated recent failures. There are no loops and
no cross-request unbounded retries.

## 11. AI Scope Restriction Architecture

Defense is layered rather than prompt-only:

1. Flutter exposes only typed Caloris feature actions and never a free prompt.
2. Edge Functions are feature-specific (`analyze-food`, `recommend-meal`,
   summaries, activity/schedule recommendations).
3. A server allowlist accepts only the six specified task identifiers.
4. Typed input schemas permit only data required by that task.
5. `AIScopeValidator` rejects coding, unrelated topics, non-food imagery, and
   arbitrary file inputs before provider dispatch where possible.
6. A server-owned system prompt repeats the boundary for both providers.
7. JSON schemas and semantic validators reject unexpected or executable output.
8. AI responses are previews and cannot call repositories or mutate data.

## 12. Prompt Injection Protection Plan

Image text, food names, notes, and user-supplied strings are quoted as untrusted
data fields, never concatenated into system instructions. Server system prompts
are immutable from the client. Requests carry a known task enum and validated
fields; unknown keys and oversized inputs are rejected. Responses have markdown
fences stripped, then must parse as JSON and satisfy exact schemas, numeric
ranges, string length limits, food-domain semantics, and maximum byte size.
Executable/code-shaped content and instruction leakage are rejected. Logs omit
secrets and image/base64 payloads.

## 13. Navigation Flow

```text
Splash/bootstrap
  |-- no session --> Login <--> Register
  |                   |--> Forgot password --> email deep link --> Reset password
  |-- session + no profile --> Onboarding (single guarded flow)
  |-- session + profile --> Main shell
                              |-- Home
                              |-- Diary
                              |-- Scan (prominent center action)
                              |-- Progress
                              `-- Profile --> Edit profile / Logout
```

Phase 1 implements guarded Auth, Onboarding, Home foundation, and Profile. Diary,
Scan, and Progress become real routes only in their owning phases; no fake primary
buttons are displayed before implementation.

## 14. Dependency List

Phase 1 runtime dependencies are deliberately small:

- `flutter_riverpod`: state composition and controllers.
- `go_router`: declarative navigation and auth/onboarding guards.
- `supabase_flutter`: Auth, session persistence, Data API, and later Storage/
  Edge Functions.
- `intl`: locale-safe dates and labels.

Development dependencies:

- `flutter_test` and `flutter_lints`.
- `mocktail` for repository/controller/widget isolation.

Later phases may add `image_picker`, local notification/timezone packages,
charting, connectivity, and a local persistence/outbox package only when their
features are implemented. All versions are resolved and pinned in
`pubspec.lock`; no AI provider SDK is added to Flutter.

## 15. Implementation Roadmap

### Phase 1 — Foundation and identity

- Bootstrap Flutter/platform projects, linting, environment loading, Material 3
  light/dark themes, Riverpod composition, and guarded routing.
- Implement register, login, logout, forgot/reset password, session restoration,
  onboarding, profile read/update, validation, and friendly states.
- Add complete initial SQL schema, constraints, indexes, grants, RLS, triggers,
  private storage bucket/policies, setup documentation, and Phase 1 tests.
- Gate: `flutter analyze` and `flutter test` pass.

### Phase 2 — Daily calorie and food loop

- Implement pure calorie engine (BMI/BMR/TDEE/moderate target) with tests.
- Add dashboard aggregates, diary, manual food, meal builder, favorites, and
  quick-add vertical slices.
- Gate: calculation, repository, form, and dashboard widget tests pass.

### Phase 3 — Habits and schedule

- Add weight, water, activity, weekly schedule, and local reminder slices.
- Keep exercise burn separate from automatic meal allowance.
- Gate: CRUD isolation, schedule validation, notifications, and progress tests.

### Phase 4 — Editable camera scan with mock boundary

- Add food-only camera/picker, preview, opt-in retention, mock analyzer, editable
  result, user confirmation, scan history, and manual fallback.
- Gate: no fake AI state; scan result correction widget tests pass.

### Phase 5 — Secured dual-provider AI backend

- Build feature-specific Edge Functions, provider/model routers, free model
  policy, OpenCode allowlist, validation/normalization, scope controls, circuit
  breaker, timeouts, and error mapping.
- Gate: parser, fallback, scope, prompt-injection, malformed-response, and secret
  exposure tests pass.
- Status: complete and deployed on 2026-09-01. All five functions require JWTs;
  provider secrets remain an external deployment configuration.

### Phase 6 — Recommendations and summaries

- Compute statistics deterministically, then request scoped meal/activity/
  schedule recommendations and neutral daily/weekly summaries.
- Gate: structured input minimization and non-judgmental output checks pass.
- Status: complete on 2026-09-01. Statistics are deterministic and every AI
  action uses a feature-specific endpoint with a minimal payload.

### Phase 7 — Resilience and release

- Add read cache and idempotent client-UUID outbox, conflict/sync handling,
  performance tuning, accessibility, security review, build signing guidance,
  and release checks for Android/iOS.
- Gate: full analyze/test/build, RLS multi-user verification, and final master
  requirement checklist pass.
- Status: Android release checkpoint complete on 2026-09-01. Hosted Auth values,
  live provider/JWT smoke tests, private upload signing, and a verified signed AAB
  are complete; physical-device/store checks remain external rollout gates. iOS
  is intentionally deferred.

## Architecture Decisions

- Email/password is the complete Phase 1 auth path. Google sign-in is deferred
  until provider/platform credentials exist, avoiding a dead production action.
- Build-time `dart-define` is used for public mobile configuration. Secrets stay
  in Edge Function secrets.
- The initial migration contains the complete requested data model so later
  phases do not require manual table creation.
- No database trigger copies auth `user_metadata` into authorization decisions;
  onboarding explicitly writes validated profile data through RLS.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Supabase Data API default exposure changed in 2026 | Client tables may return permission errors | Migration explicitly revokes and grants required operations; README calls out Data API exposure settings. |
| Mobile deep links vary by bundle/platform | Confirmation or password recovery callback can fail | Register the documented `caloris://auth-callback` and `caloris://reset-password` callbacks in hosted Auth and Android. |
| Health inputs can be unrealistic | Invalid calorie targets and poor UX | Shared client validation plus database constraints; moderate deficit only. |
| AI model catalogs/costs change | Paid use or failed scans | Server-side refreshed catalog, zero-cost checks, allowlists, bounded fallback, and manual mode. |
| Docker is intentionally not used on this host | Local Supabase integration tests are unavailable | Use versioned migrations, linked-project advisors, API-based function deploys, live JWT rejection checks, and report the exact verification boundary. |

## Open Configuration (not product ambiguity)

- A Supabase project URL and publishable/legacy anon key are required to run
  connected flows.
- Google OAuth remains off until the user configures the provider, SHA keys,
  iOS URL scheme, and callback URLs.
- Android upload signing is configured privately on the release workstation;
  iOS signing remains deferred.
- OpenRouter/OpenCode provider keys and the explicit OpenCode model allowlists are
  supplied through Supabase secrets; without them, AI endpoints safely request
  manual input.
