# ADR-005 — Logging and crash reporting: Timber + Crashlytics behind a CrashReporter abstraction

## Status

Accepted

## Date

2026-09-24

## Context

The team needs readable logs during development and crash plus non-fatal reports from staging and production tablets (FR-FOUND-005). Firebase projects per environment are not decided yet (PDR-004), so the app must build and run without Firebase. Logs must never contain tokens or personal data. Code and tests should not depend on Firebase classes directly.

## Decision

- **Timber** is the only logging API in app code.
- **Trees per environment:** `dev` plants `Timber.DebugTree`. `staging` and `prod` plant `CrashReportingTree`: `WARN`/`ERROR` logs with a throwable go to `recordException`; other logs at `INFO` and above become Crashlytics log breadcrumbs; `DEBUG` and `VERBOSE` are dropped.
- **`CrashReporter` abstraction:** `interface CrashReporter { setUserId(id: String?); setKey(key: String, value: String); log(message: String); recordException(throwable: Throwable) }`. `CrashlyticsCrashReporter` is bound when Firebase is initialized and `BuildConfig.CRASH_REPORTING_ENABLED` is true; otherwise `NoOpCrashReporter` is bound. Tests use `FakeCrashReporter`.
- **Crashlytics collection is off in dev:** `CRASH_REPORTING_ENABLED=false` in `config/env/dev.properties` feeds the `crashlyticsCollectionEnabled` manifest placeholder; staging and prod enable it.
- **Firebase:** BOM 34.1.0 with `firebase-crashlytics` (no KTX); the google-services (4.4.2) and Crashlytics (3.0.8) Gradle plugins apply only when the flavor's `google-services.json` exists (ADR-003).
- **Startup keys:** `AppStartup` sets `environment`, `version` (name and code) and `device_class` (`tablet`).
- **Never log:** tokens, full request bodies outside dev, or personal data. HTTP logging redacts `Authorization` and cookie headers.

## Consequences

- Debug builds give full Logcat output; release environments send only what helps diagnose problems.
- Code and tests do not import Firebase; replacing Crashlytics later means one new `CrashReporter` implementation.
- Until PDR-004 is decided, staging and prod builds run with `NoOpCrashReporter` and report nothing.
- Breadcrumbs at `INFO` and above appear in crash reports, so `INFO` messages must be free of personal data like any other log.

## Alternatives considered

- **Crashlytics calls directly from app code** — rejected: couples features and tests to Firebase and breaks builds without `google-services.json`.
- **Sentry or another crash service** — rejected: Firebase Crashlytics was chosen at design time and matches the team's existing tooling.
- **`android.util.Log` without Timber** — rejected: no per-environment routing and no single place to drop debug logs from release.
- **Crashlytics enabled in dev** — rejected: development crashes would pollute production-grade dashboards.
