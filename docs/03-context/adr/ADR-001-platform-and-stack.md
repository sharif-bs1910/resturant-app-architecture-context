# ADR-001 — Platform and stack: Butterfly core stack with its gaps fixed

## Status

Accepted

## Date

2026-09-24

## Context

Noshitech Restaurant is a new native Android tablet POS (FR-FOUND-001). The team already runs a working Android project, Butterfly (`butterfly-mobile-android`), whose Gradle and plugin setup is proven on AGP 9 with built-in Kotlin. Reusing its core stack lowers risk, but Butterfly also carries libraries this project does not want: Room, Gson, dataBinding/viewBinding, a duplicate core-ktx, SDP/SSP dimension libraries and the deprecated security-crypto.

While writing the implementation plans, several versions had to be adjusted for compatibility (spec §14): detekt 1.x does not support Kotlin 2.2 / AGP 9, Crashlytics 20.x is needed for AGP 9 R8, the Firebase KTX modules were removed in BOM 34, and Coil 3.4+ pulls Compose versions newer than BOM 2025.07.

## Decision

Use the Butterfly core stack with its gaps fixed, in a single `:app` module with strict package layering (spec §4.1). All versions are pinned in `gradle/libs.versions.toml`:

| Area | Choice and version |
|---|---|
| Build | AGP 9.0.1 (built-in Kotlin), Kotlin 2.2.10, KSP 2.3.2, Gradle wrapper 9.2.1, JDK 21 |
| SDK | minSdk 25, targetSdk 36, compileSdk 36 |
| UI | Compose BOM 2025.07.00, Material3, material-icons-extended, core-splashscreen 1.0.1, activity-compose 1.9.3, lifecycle 2.8.7 (runtime-compose, viewmodel-compose) |
| DI | Hilt 2.56, hilt-navigation-compose 1.2.0 |
| Navigation | Navigation Compose 2.8.5 with type-safe `@Serializable` routes |
| Network | Retrofit 2.11.0 + kotlinx.serialization converter, OkHttp 4.12.0 + logging-interceptor, kotlinx.serialization JSON 1.8.0, coroutines 1.9.0 |
| Storage | DataStore Preferences 1.1.1; tokens encrypted with an Android Keystore AES-GCM key |
| Images | Coil 3.3.0 (compose + network-okhttp) |
| Logging | Timber 5.0.1; Firebase BOM 34.1.0 with `firebase-crashlytics` (no KTX); google-services plugin 4.4.2; Crashlytics plugin 3.0.8 |
| Quality | ktlint-gradle 14.2.0 with ktlint 1.8.0 (the format hook downloads the same CLI version); detekt `dev.detekt` 2.0.0-alpha.3 |
| Tests | JUnit 4.13.2, kotlin-test, MockK 1.13.13, Turbine 1.2.0, kotlinx-coroutines-test, OkHttp MockWebServer, Compose ui-test-junit4 |

Excluded from Butterfly: Room, Gson, dataBinding/viewBinding, duplicate core-ktx, SDP/SSP, security-crypto. Adaptive layout uses the project's own `AdaptiveInfo` instead of `material3-window-size-class` / `material3-adaptive` (see ADR-006).

**detekt pre-release risk.** detekt 2.0.0-alpha.3 is the first release that supports AGP 9 built-in Kotlin, and it is a pre-release. It is pinned deliberately. If it fails to resolve, configure or run on Kotlin 2.2.10, the plugin is removed from the build, ktlint + Android lint remain the static-analysis gate, and the outcome is recorded in PDR-005 until a Kotlin upgrade allows a stable detekt. If ktlint rules conflict with Compose conventions, only that rule is disabled in `.editorconfig` and the rule is listed here.

## Consequences

- The Gradle plugin setup can mirror Butterfly, which already works on AGP 9 built-in Kotlin (KSP, Hilt, serialization).
- Fewer dependencies: no ORM, no second JSON library, no view system bindings, no dimension libraries; dimensions come from design tokens instead.
- Coil and Firebase are held at versions compatible with Compose BOM 2025.07 and AGP 9; upgrading the Compose BOM requires revisiting both.
- The static-analysis gate depends on a pre-release tool; PDR-005 tracks the risk, and the definition of done allows running without detekt if PDR-005 records the fallback.
- A single module keeps builds simple; layering is enforced by package rules, the `architecture-mvvm` rule and review, not by Gradle module boundaries.

## Alternatives considered

- **Copy Butterfly unchanged** — rejected: brings deprecated security-crypto, Room and Gson that this app does not need, and SDP/SSP conflicts with token-based sizing.
- **Latest versions of every library** — rejected: Coil 3.4+ and newer Compose artifacts conflict with the pinned Compose BOM, and unproven AGP 9 combinations add risk without benefit for the foundation.
- **detekt 1.x** — rejected: does not support Kotlin 2.2 / AGP 9 built-in Kotlin.
- **No detekt at all** — kept only as the PDR-005 fallback; detekt adds complexity and style checks that ktlint does not cover.
- **Multi-module Gradle build** — rejected for the foundation: more build configuration than a small team needs now; can be revisited with a new ADR.
