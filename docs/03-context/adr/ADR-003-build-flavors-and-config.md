# ADR-003 — Build flavors and configuration: dev/staging/prod with committed non-secret config

## Status

Accepted

## Date

2026-09-24

## Context

The app needs separate development, staging and production builds that can be installed side by side, with different API base URLs, HTTP logging and crash reporting (FR-FOUND-002). The backend URLs and Firebase projects are not decided yet (PDR-003, PDR-004), secrets must never be committed, and every build must succeed on a fresh checkout without any secret or Firebase file. Copy-pasting `buildConfigField` lines per flavor drifts over time.

## Decision

- **Flavors:** one dimension `environment`:

| Flavor | applicationId | App name | `HTTP_LOG_LEVEL` | `CRASH_REPORTING_ENABLED` |
|---|---|---|---|---|
| `dev` | `com.noshitechinc.restaurant.dev` | Noshitech Restaurant (Dev) | BODY | false |
| `staging` | `com.noshitechinc.restaurant.staging` | Noshitech Restaurant (Staging) | HEADERS | true |
| `prod` | `com.noshitechinc.restaurant` | Noshitech Restaurant | NONE | true |

- **Build types:** `debug` (pseudo-locales enabled for `en-XA` checks) and `release` (R8 minify + resource shrinking, keep rules for kotlinx.serialization and Retrofit).
- **Non-secret config:** committed `config/env/{dev,staging,prod}.properties` with `API_BASE_URL`, `HTTP_LOG_LEVEL`, `CRASH_REPORTING_ENABLED`, `CONNECT_TIMEOUT_SECONDS`, `READ_TIMEOUT_SECONDS`. One loader function in `app/build.gradle.kts` maps each file into `BuildConfig` fields for its flavor, plus `ENVIRONMENT` (`dev|staging|prod`) and the `crashlyticsCollectionEnabled` manifest placeholder. Base URLs are `.invalid` placeholders until PDR-003 is decided.
- **Secrets:** read from `local.properties` or environment variables, never from committed files. `local.properties.example` documents the keys. Release signing is configured only when all four values (`KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`) are present; otherwise the release build is unsigned.
- **Conditional Firebase plugins:** the Google Services and Crashlytics Gradle plugins are applied only when `app/src/<flavor>/google-services.json` exists. Those files are git-ignored and protected by the guard-secrets hook.
- **Agents and the SDK:** AI agents run Gradle with `ANDROID_HOME=$HOME/Android/Sdk` and never read or write `local.properties`.

## Consequences

- `./gradlew assembleDevDebug assembleStagingDebug assembleProdRelease` works on a fresh checkout with no secrets and no Firebase files.
- All three environments install side by side on one test tablet.
- Adding a config key means one line per properties file plus one line in the loader; changes to flavors, `config/env/*.properties` or the version catalog are impact-analysis triggers.
- An unsigned release build is produced when signing values are missing, so CI or a release manager must supply them for distributable builds.
- Crashlytics stays inactive until PDR-004 provides `google-services.json` per environment.

## Alternatives considered

- **Per-flavor `buildConfigField` blocks** — rejected: duplicated lines drift between flavors.
- **Only build types (debug/release) with runtime environment switching** — rejected: staging and prod could not be installed side by side, and a runtime switch risks shipping a prod build pointed at staging.
- **Committed `google-services.json`** — rejected: environment-specific project files are treated as secrets and are not committed.
- **Gradle properties file for secrets** — rejected in favour of `local.properties` and environment variables, which are already git-ignored and CI-friendly.
