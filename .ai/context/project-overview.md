# Project Overview — Noshitech Restaurant

Condensed **foundation** context for AI sessions. Source of truth: the [design spec](../../docs/superpowers/specs/2026-09-24-android-foundation-design.md) (section 14 amendments included).

**Business domain is not defined yet.** Do not invent restaurant operations, personas or feature workflows. Wait for shared business context.

## Product (foundation only)

Android app id `com.noshitechinc.restaurant`, display name "Noshitech Restaurant". English only and light mode only; strings live in resources. Format defaults used by foundation components: USD currency, +1 (US) phone numbers, US address fields. No business features yet; the app launches to a blank home screen.

## Devices

- Tablet only: landscape requested via `OrientationPolicy` (Android 16 may ignore the lock on large screens, so tablet layouts must also work in portrait and multi-window).
- Narrow multi-window widths use `WidthClass.Compact` (single pane); Medium/Expanded use two panes. Phones are not a supported product target.

## Current phase

Phase 6 — Development (Foundation), sprint 0. Scope is the 20 foundation tasks `FR-FOUND-001`…`FR-FOUND-020`: build environments, MVVM architecture, networking, logging and crash reporting, adaptive layout, design tokens, shared components and shared states. Components are verified through `@Preview` and tests.

## Tech stack

| Area | Choice |
|---|---|
| Build | AGP 9.0.1 (built-in Kotlin), Kotlin 2.2.10, KSP, Gradle wrapper 9.2.1, JDK 21 |
| SDK | minSdk 25, targetSdk 36, compileSdk 36 |
| UI | Compose BOM 2025.07.00, Material3, core-splashscreen, activity-compose, lifecycle-runtime-compose; adaptive layout via own `AdaptiveInfo` + `WidthClass` (no window-size-class or adaptive libraries) |
| DI | Hilt 2.56, hilt-navigation-compose |
| Navigation | Navigation Compose 2.8.5, type-safe `@Serializable` routes |
| Network | Retrofit 2.11 + kotlinx.serialization converter, OkHttp 4.12 + logging-interceptor, kotlinx.serialization JSON |
| Storage | DataStore Preferences; token encryption via Android Keystore AES-GCM |
| Images | Coil 3.3.0 (compose + network-okhttp) |
| Logging | Timber, Firebase BOM 34.1.0 + `firebase-crashlytics` (no KTX); google-services plugin 4.4.2, Crashlytics plugin 3.0.8 |
| Quality | ktlint-gradle 14.2.0 with ktlint 1.8.0; detekt deferred (PDR-005) |
| Tests | JUnit4, MockK, Turbine, kotlinx-coroutines-test, OkHttp MockWebServer, Compose ui-test-junit4 |

Excluded: Room, Gson, dataBinding/viewBinding, SDP/SSP, security-crypto. Single `:app` module with strict package layering.

## Architecture summary

Packages under `com.noshitechinc.restaurant`:

```
app/                RestaurantApplication, MainActivity
navigation/         Routes (@Serializable), AppNavHost
feature/home/       HomeRoute, HomeScreen, HomeViewModel, HomeUiState
domain/             model/, repository/ (interfaces), usecase/
data/               remote/api/, remote/dto/, mapper/, repository/ (…RepositoryImpl)
core/common/        AppDispatchers, ApiResult, AppError, UiText, MarketConfig, formatters/validators
core/ui/            BaseViewModel, LoadState, UiEffect, AppScaffold, ObserveEffects, state/ (error-aware states)
core/network/       NetworkModule, interceptors, TokenAuthenticator, SafeApiCall, ErrorMapper, ErrorBodyParser, NetworkMonitor
core/auth/          AuthProvider, TokenStore, KeystoreTokenStore, SessionManager
core/logging/       Timber trees, CrashReporter, CrashlyticsCrashReporter, NoOpCrashReporter
core/designsystem/  theme/ (tokens, AppTheme), component/, state/ (generic states), preview/
core/adaptive/      AdaptiveInfo, WidthClass, OrientationPolicy, adaptive containers
di/                 Hilt modules
```

**Dependency direction:** `feature` → `domain` ← `data`; `core/*` is usable by all; `domain` is pure Kotlin (no Android imports); `designsystem` never depends on `feature`, `data` or `domain`. Error-aware states (`ErrorState`, `ServiceUnavailableState`, `OfflineBlockingState`, `LoadStateContent`) and `AppScaffold` live in `core/ui` because `designsystem` must not depend on `AppError` mapping.

## Environments

| Flavor | applicationId | App name | HTTP log | Crashlytics |
|---|---|---|---|---|
| `dev` | `com.noshitechinc.restaurant.dev` | Noshitech Restaurant (Dev) | BODY | off |
| `staging` | `com.noshitechinc.restaurant.staging` | Noshitech Restaurant (Staging) | HEADERS | on |
| `prod` | `com.noshitechinc.restaurant` | Noshitech Restaurant | NONE | on |

Non-secret values live in `config/env/{dev,staging,prod}.properties`. Secrets come from `local.properties` or environment variables. Firebase plugins apply only when `app/src/<flavor>/google-services.json` exists.

## Key conventions

- **UiState:** `XxxUiState` is an immutable data class exposed as `StateFlow<XxxUiState>`.
- **LoadState:** `Idle`, `Loading`, `Content(data)`, `Empty`, `Error(error: AppError)`, one per independently loaded section.
- **UiText:** `Resource(@StringRes id, args)` or `Dynamic(value)` for sanitized server text. ViewModels never hold `Context` or Compose types.
- **Effects:** `BaseViewModel.effects: Flow<UiEffect>` backed by `Channel(Channel.BUFFERED)`. `UiEffect` is an open interface with base effects `ShowMessage` and `ShowErrorDialog`; features add their own effect types.
- **Submissions:** `launchSubmit(key) { }` ignores re-entry while `key` runs, tracks keys in `submittingKeys: StateFlow<Set<String>>`, always releases the key, and presents unexpected exceptions as `AppError.Unknown`.
- **Errors:** `presentError(error)` chooses a transient message or a dialog.
- **Screens:** `XxxRoute` / `XxxScreen` split; Route owns ViewModel and effects; Screen is stateless with previews.
- **Data:** repositories return `ApiResult<DomainModel>`; DTOs map to domain with `toDomain()`.
- **Tokens:** colors, typography, spacing, radius, border and sizes only through `AppTheme.*`; placeholder values until Figma (PDR-002).
- **Previews:** every component and screen file ends with previews for each variant and state, covering tablet landscape, tablet portrait and font scale 2.0.
- **Long content:** names use `maxLines` + ellipsis; prices are never truncated; addresses wrap up to 3 lines; buttons and chips grow in height.

## Open decisions

- **PDR-001** — Backend auth scheme; default: Bearer + refresh via `AuthProvider` with a placeholder endpoint.
- **PDR-002** — Figma brand tokens; default: placeholder palette and system font.
- **PDR-003** — API base URLs per environment; default: `.invalid` placeholders in `config/env/*.properties`.
- **PDR-004** — Firebase projects per environment; default: Firebase plugins skipped when `google-services.json` is absent.
- **PDR-005** — detekt deferred until Kotlin ≥ 2.3; ktlint + Android lint active.

## Links

- [Design spec](../../docs/superpowers/specs/2026-09-24-android-foundation-design.md)
- [Plan 1 — AI-DLC setup](../../docs/superpowers/plans/2026-09-24-01-ai-dlc-setup.md)
- [Plan 2 — Android core foundation](../../docs/superpowers/plans/2026-09-24-02-android-core-foundation.md)
- [Plan 3 — Design system and states](../../docs/superpowers/plans/2026-09-24-03-design-system-and-states.md)
- [ADRs](../../docs/03-context/adr/)
- [Pending decisions](../../docs/03-context/PENDING-DECISIONS.md)
- [Project index](../../PROJECT-INDEX.md)
