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

### Security

- Provider secrets remain server-only and are never included in Flutter builds.
- AI endpoints require JWTs, reject unrelated/coding requests, and never mutate
  user data autonomously.
- Android release builds require an explicit private signing configuration and
  cannot silently use the debug key.
- Email confirmation and password recovery use separate Android callback hosts;
  hosted Auth enforces confirmed email, 8-character letter+digit passwords, and
  password-change reauthentication.

### Deployment notes

- Live provider keys and allowlists are configured as Supabase Edge Function
  secrets and remain outside Git and mobile artifacts.
- Android upload signing and production Auth URLs are configured on the release
  workstation/project. Store metadata remains a release-owner responsibility;
  iOS is deferred.
