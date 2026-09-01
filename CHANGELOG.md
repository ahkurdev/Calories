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

### Security

- Provider secrets remain server-only and are never included in Flutter builds.
- AI endpoints require JWTs, reject unrelated/coding requests, and never mutate
  user data autonomously.
- Android release builds require an explicit private signing configuration and
  cannot silently use the debug key.

### Deployment notes

- Live AI requires owner-supplied Supabase Edge Function secrets.
- Android/iOS store signing, production Auth URLs, and store metadata remain
  environment-specific release-owner responsibilities.
