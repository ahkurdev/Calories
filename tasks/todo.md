# Caloris Task List

Status: **Phase 1 complete — 2026-09-01**

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

