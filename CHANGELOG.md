# Changelog

## [Unreleased] - 1.0.0 candidate

### Added

- Complete calorie, food, weight, water, light activity, weekly schedule,
  reminder, scan correction, and progress flows.
- Authenticated Supabase backend with owner-only RLS and private scan storage.
- Free-only OpenRouter routing, explicit OpenCode Zen allowlists, strict AI
  scope/output validation, fallback, timeout, circuit breaker, and rate limit.
- Deterministic daily/weekly statistics plus optional scoped meal, activity, and
  summary insights.
- Per-user SQLite profile/diary cache and an idempotent food mutation outbox.
- Capability-aware rotating model pools with ordered fallback across the
  configured OpenRouter and OpenCode Zen allowlists.
- OpenCode Responses API support for Muse Spark 1.2 Contributor Free.
- Indonesian-only food assistant with separate foods-to-choose and
  foods-to-limit guidance, bounded food conversation history, and nearby-place
  context.
- Caloris logo and Android launcher icons.
- Foreground walking sessions with step, duration, speed, and estimated calorie
  totals; vehicle-speed and lost-GPS events pause accepted steps.
- JWT-protected nearby-food lookup with Google Maps/place links and an honest
  Maps fallback when Google Places is not configured.

### Security

- Provider secrets remain server-only and are never included in Flutter builds.
- AI endpoints require JWTs, reject unrelated/coding requests, and never mutate
  user data autonomously.
- Android release builds require an explicit private signing configuration and
  cannot silently use the debug key.
- Email confirmation and password recovery use separate Android callback hosts;
  hosted Auth enforces confirmed email, 8-character letter+digit passwords, and
  password-change reauthentication.
- Foreground location is requested only from user-triggered nearby/walking
  actions. Coordinates and routes are not stored, and Maps/provider keys never
  enter the APK.

### Fixed

- Current Supabase `invalid_credentials` and `email_not_confirmed` responses now
  show actionable Indonesian messages instead of the generic account fallback.
- Successful registration now explicitly asks the user to confirm their email
  before signing in.

### Deployment notes

- Live provider keys and allowlists are configured as Supabase Edge Function
  secrets and remain outside Git and mobile artifacts.
- Android upload signing and production Auth URLs are configured on the release
  workstation/project. Store metadata remains a release-owner responsibility;
  iOS is deferred.
- Nearby Google Places lookup requires a server-only `GOOGLE_PLACES_API_KEY`;
  until configured, the app exposes a direct Google Maps search fallback.
