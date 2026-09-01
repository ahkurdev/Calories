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

### Deployment notes

- Live provider keys and allowlists are configured as Supabase Edge Function
  secrets and remain outside Git and mobile artifacts.
- Android store signing, production Auth URLs, and store metadata remain
  environment-specific release-owner responsibilities; iOS is deferred.
