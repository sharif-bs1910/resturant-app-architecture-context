# Business and Tech Context — Noshitech Restaurant

Phase 3. Condensed version for AI sessions: [project-overview.md](../../.ai/context/project-overview.md). Decisions: [ADRs](adr/). Open questions: [PENDING-DECISIONS.md](PENDING-DECISIONS.md).

## Business context

**Not defined yet.** Business operations, personas, workflows and domain rules will be supplied later. Do not invent restaurant-operations narrative.

Confirmed product constraints for the foundation only:

- Display name "Noshitech Restaurant"; application id `com.noshitechinc.restaurant`.
- English only; light mode only.
- Market format defaults for the foundation: USD amounts, +1 (US) phone numbers, US address fields.
- Business features (menu, ordering, kitchen, payments, login UI, offline queueing) are out of scope until separately specified.

## Tech context

### Stack

| Area | Choice |
|---|---|
| Build | AGP 9.0.1 (built-in Kotlin), Kotlin 2.2.10, KSP, Gradle wrapper 9.2.1, JDK 21 |
| SDK | minSdk 25, targetSdk 36, compileSdk 36 |
| UI | Jetpack Compose (BOM 2025.07.00), Material3, core-splashscreen, activity-compose, lifecycle-runtime-compose; own `AdaptiveInfo` + `WidthClass` for adaptive layout |
| Architecture | MVVM: `UiState` + `LoadState` + Channel effects + `BaseViewModel.launchSubmit` (ADR-002) |
| DI | Hilt 2.56, hilt-navigation-compose |
| Navigation | Navigation Compose 2.8.5 with type-safe `@Serializable` routes |
| Network | Retrofit 2.11 + kotlinx.serialization converter, OkHttp 4.12 + logging-interceptor (ADR-004) |
| Storage | DataStore Preferences; tokens encrypted with an Android Keystore AES-GCM key |
| Images | Coil 3.3.0 (compose + network-okhttp) |
| Logging | Timber; Firebase BOM 34.1.0 with `firebase-crashlytics` (ADR-005) |
| Quality | ktlint-gradle 14.2.0 (ktlint 1.8.0); detekt deferred (PDR-005) |
| Tests | JUnit4, MockK, Turbine, kotlinx-coroutines-test, OkHttp MockWebServer, Compose ui-test-junit4 |

Full rationale and pinned versions: [ADR-001](adr/ADR-001-platform-and-stack.md).

### Environments

| Flavor | applicationId | App name | HTTP log | Crash reporting |
|---|---|---|---|---|
| `dev` | `com.noshitechinc.restaurant.dev` | Noshitech Restaurant (Dev) | BODY | off |
| `staging` | `com.noshitechinc.restaurant.staging` | Noshitech Restaurant (Staging) | HEADERS | on |
| `prod` | `com.noshitechinc.restaurant` | Noshitech Restaurant | NONE | on |

Non-secret values live in `config/env/{dev,staging,prod}.properties`; secrets come from `local.properties` or environment variables ([ADR-003](adr/ADR-003-build-flavors-and-config.md)).

### Integrations

| Integration | Status |
|---|---|
| Backend API | Not defined. Auth scheme open (PDR-001); base URLs are `.invalid` placeholders (PDR-003). Placeholder endpoint only: `api:auth:refresh` in [API-REGISTRY.md](API-REGISTRY.md). |
| Firebase Crashlytics | One project per environment expected (PDR-004). Until `app/src/<flavor>/google-services.json` exists, Firebase plugins are skipped and `NoOpCrashReporter` is used. |
| Figma | Brand tokens pending (PDR-002); placeholder token values keep the structure Figma-ready. |

## Foundation behaviour (engineering, not business)

These are delivered foundation mechanisms. They are not claims about how a restaurant operates.

| Behaviour | Mechanism |
|---|---|
| Duplicate-submit protection | `BaseViewModel.launchSubmit` + `AppButton(loading)` ignores taps while loading |
| Shared load / empty / error / offline UI | `LoadState`, design-system states, `ErrorState`, `OfflineBlockingState`, `AppScaffold` |
| No offline data queue in foundation | Connectivity loss shows a blocking overlay when `requiresNetwork` is set; no offline mode |
| Touch targets and long content | Tokens (`minTouchTarget`, button sizes), preview matrix, design-lint |
| Adaptive / orientation | `AdaptiveInfo`, `OrientationPolicy` (tablet landscape where the platform allows) |

## Non-functional requirements

| NFR | Target | Enforced by |
|---|---|---|
| Touch targets | Interactive elements ≥ 48dp (`AppTheme.sizes.minTouchTarget`); primary actions 56dp (`buttonLarge`) | Component APIs, previews, `review-change` skill |
| Font scale | Layouts work at font scale 1.0, 1.5 and 2.0 without clipping or overlap | `@ComponentPreviews` / `@ScreenPreviews` include font scale 2.0 |
| Long and translated content | Names ellipsize, prices never truncate, addresses wrap to 3 lines, buttons and chips grow; verified with `en-XA` pseudo-locale | FR-FOUND-020, `PreviewData` long samples |
| No duplicate submissions | A mutation cannot run twice for the same key while in flight | `BaseViewModel.launchSubmit`, `AppButton(loading)`, unit and UI tests |
| Orientation | Landscape on sw600dp+ where the platform allows; tablet layouts still work in portrait and multi-window (Android 16) | `OrientationPolicy`, ADR-006 |
| No secrets in repo | No keys, tokens, passwords, keystores or `google-services.json` committed | `.gitignore`, guard-secrets hook, `local.properties.example` |
| No sensitive logging | Tokens, personal data and request bodies outside dev are never logged; auth and cookie headers redacted | `HttpLoggingInterceptor` redaction, `CrashReportingTree`, ADR-005 |
| Consistent visuals | No hardcoded colours, dp/sp or user-facing strings outside theme and resources | Design-lint hook and `design-lint-check.sh` |
