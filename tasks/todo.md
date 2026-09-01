# Caloris Task List

Status: **Phase 7 implementation complete — 2026-09-01**

## Phase 2: Daily calorie and food loop

- [x] BMI, BMR, TDEE, and safe calorie targets are calculated in a pure service.
- [x] Dashboard, food diary, manual input, meal builder, favorites, and quick add work through repositories/controllers.
- [x] Phase 2 analysis and tests pass; green checkpoints are pushed.

## Phase 3: Progress, schedule, and habits

- [x] Weight history, target progress, and chart are connected to Supabase.
- [x] Water shortcuts and editable profile target are connected to Supabase.
- [x] Light/custom activity entries remain separate from calorie allowance.
- [x] Weekly schedule supports add, edit, delete, category, and busyness.
- [x] Reminder supports type, time, days, enabled state, local scheduling, and deletion.
- [x] Notification permission is requested only from a user-triggered reminder action.
- [x] Android notification receivers/desugaring and iOS foreground delegate are configured.
- [x] `flutter analyze`, 21 tests, and Android debug APK build pass.

## Phase 4: Editable food scan

- [x] Camera and gallery selection are scoped to food photos with lost-data recovery.
- [x] Preview, analyze, rescan, manual fallback, add/remove/edit components, and Diary confirmation work.
- [x] Development mock is disabled by default and visibly labelled when enabled.
- [x] Photos are not uploaded by default; optional retention uses the private owner path.
- [x] Corrected structured results are stored in scan history through a repository.
- [x] Bottom navigation now exposes the requested Home, Diary, Scan, Progress, and Profile destinations.
- [x] `flutter analyze`, 24 tests, and Android debug APK build pass.

## Phase 5: Secured dual-provider AI backend

- [x] Five feature-specific Edge Functions accept only exact Caloris task types.
- [x] Generated Supabase auth wrappers and gateway configuration require JWTs.
- [x] OpenRouter discovers compatible zero-cost models dynamically and can be
      narrowed with a server allowlist.
- [x] OpenCode Zen is disabled unless a server key and explicit model allowlist
      are configured; vision models require a second explicit allowlist.
- [x] Provider retries, timeout, priority fallback, and circuit breaking are
      bounded and end in an honest manual-input response.
- [x] Scope, schema, prompt-injection, executable-output, and size validation run
      before or after provider dispatch as appropriate.
- [x] Flutter calls `analyze-food` only when Supabase is configured; development
      mock mode remains explicit, labelled, and disabled by default.
- [x] All five functions are deployed with `verify_jwt = true`; an unauthenticated
      live request is rejected with HTTP 401.
- [x] `flutter analyze`, 25 Flutter tests, 13 Deno tests, Edge Function type-check,
      remote advisors, and Android debug APK build pass.

## Phase 6: Recommendations, summaries, and statistics

- [x] Daily and seven-day statistics are computed deterministically before AI.
- [x] Meal recommendation uses remaining calories, goal, meal type, minimized
      history, preference, and practical-food mode.
- [x] Activity recommendation receives only the selected day's structured
      schedule without record/user IDs.
- [x] Daily and weekly summaries use exact typed statistics and neutral UI copy.
- [x] Flutter parsers distinguish validated AI content from honest fallback.
- [x] Exact nested request/output schemas reject identity fields and unexpected
      provider content.

## Phase 7: Resilience, hardening, and release preparation

- [x] Profile and diary reads have a per-user SQLite cache.
- [x] Offline food mutations use a persistent outbox and idempotent client UUIDs.
- [x] Pending sync is visible; cache is retained for at most 90 days and removed
      for the owner after successful logout.
- [x] AI functions enforce a configurable per-user worker rate limit.
- [x] Local Auth defaults require confirmation, secure password changes, and
      letter+digit passwords of at least eight characters.
- [x] Android release cannot silently use debug signing; a safe template and
      release/rollback runbook are included.
- [x] Version 1.0.0 candidate changelog and external production configuration
      checklist are documented.
- [x] OpenRouter and OpenCode keys plus exact model allowlists are stored as
      server-only Supabase secrets; direct provider credential/model smoke tests
      pass with bounded 429/503 fallback behavior.
- [x] Model starts rotate independently for text and vision while preserving an
      ordered three-model fallback window; Muse uses OpenCode Responses API.
- [x] Final automated gate includes 37 Flutter tests and 23 Deno tests.
- [x] Authenticated Edge Function smoke test returns HTTP 200/success with a
      temporary confirmed user; its session is revoked and user is deleted.
- [x] A private ignored upload keystore signs the Android App Bundle for the
      permanent `com.caloris.caloris` application ID; signature verification passes.
- [ ] iOS release work is explicitly deferred until after Android.

## Task 1: Bootstrap Flutter foundation

**Description:** Create the Android/iOS application, dependency manifest, strict
lint configuration, environment loader, and minimal bootstrap.

- [x] `main.dart` only initializes configuration, Supabase, Riverpod, and app.
- [x] Public Supabase configuration uses compile-time defines and fails safely.
- [x] Dependencies resolve and `pubspec.lock` is present for version control.
- [x] `flutter pub get` and `flutter analyze` pass.

## Task 2: Implement Material 3 theme and shared UI

**Description:** Add friendly light/dark themes and reusable UI primitives.

- [x] Light and dark schemes use Material 3.
- [x] Forms expose labels and consistent validation/error feedback.
- [x] Loading, retry, and unconfigured states are explicit.
- [x] Application widget test and analyze pass.

**Dependencies:** Task 1

## Task 3: Implement authentication slice

**Description:** Build repository, controller, and pages for registration, login,
password recovery/reset, logout, and persisted session observation.

- [x] Widgets call a Riverpod controller/repository, never Supabase directly.
- [x] Supabase Auth errors map to friendly Indonesian messages.
- [x] Recovery events are guarded and route to password reset.
- [x] Controller/repository contract success and failure tests pass.

**Dependencies:** Tasks 1–2

## Checkpoint: Auth foundation

- [x] `flutter analyze` is clean.
- [x] `flutter test` passes.
- [x] Client audit finds no service-role or AI provider secrets.

## Task 4: Implement profile and onboarding slice

**Description:** Add profile model, repository, controller, onboarding creation,
profile updates, and health-input validation.

- [x] Birth date drives computed age; age is not stored redundantly.
- [x] Client and database share realistic height/weight/age/water bounds.
- [x] Repository replaces any supplied profile ID with the current Auth user ID.
- [x] Model mapping and validation tests pass.

**Dependencies:** Task 3

## Task 5: Implement guarded navigation and Phase 1 pages

**Description:** Route users by session/profile state and expose real Home/Profile
screens without pretending later-phase features are functional.

- [x] Unauthenticated users cannot enter protected routes.
- [x] Authenticated users without profiles are sent to onboarding.
- [x] Completed users can view/edit profile and log out.
- [x] Missing Supabase configuration has a tested honest setup route.

**Dependencies:** Task 4

## Task 6: Create and deploy complete Supabase migration

**Description:** Create all requested tables, constraints, indexes, triggers,
grants, RLS policies, private food-scan bucket policies, and security hardening.

- [x] All nine tables use UUID ownership and requested fields.
- [x] `anon` has no user-table access; each table has four ownership policies.
- [x] UPDATE policies have both `USING` and `WITH CHECK`.
- [x] Remote policy expressions were queried and verified against `auth.uid()`.
- [x] `food-scans` is private and scoped to the authenticated owner folder.
- [x] Both migrations are applied to linked project `ndsydoqvzsmegnpvgpfr`.
- [x] Remote security and performance advisors report no issues.

**Dependencies:** Task 4

## Task 7: Document and verify Phase 1

**Description:** Document setup and run all static, unit/widget, remote database,
and platform build checks available on this Windows host.

- [x] README covers Flutter, Supabase, migration, RLS, Storage, Auth, AI secret
      boundaries, future camera permissions, testing, and Android/iOS builds.
- [x] `.env.example` contains placeholders; real environment files are ignored.
- [x] `flutter analyze`: no issues.
- [x] `flutter test`: 8 tests passed.
- [x] Android debug APK builds successfully.
- [x] iOS source project is generated; actual iOS build is correctly deferred to
      macOS/Xcode signing.
- [x] Git repository is initialized and `origin` points to
      `https://github.com/ahkurdev/Calories.git`.

**Dependencies:** Tasks 1–6

## Checkpoint: Phase 1 complete

- [x] Auth, onboarding, and profile use repository boundaries.
- [x] Migration/RLS match the mobile contracts and are deployed.
- [x] Flutter analysis, tests, and Android debug build pass.
- [x] Remaining requirements are preserved in `tasks/plan.md` Phases 2–7.
- [x] No commit or push was performed without explicit user authorization.
