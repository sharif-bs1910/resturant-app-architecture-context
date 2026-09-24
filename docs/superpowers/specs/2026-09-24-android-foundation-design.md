# Noshitech Restaurant — Android Foundation & AI-DLC Setup (Design)

- **Date:** 2026-09-24
- **Status:** Approved design, pending spec review
- **Scope:** AI-DLC context repo + Android project foundations (no business features)
- **Reference project:** `~/AndroidStudioProjects/butterfly-complete-project/butterfly-mobile-android` (Butterfly)
- **Playbook:** https://mirrayan.github.io/AI-DLC-playbook/

---

## 1. Goals and non-goals

### Goals

1. Set up AI-driven development following the AI-DLC playbook spine (context repo, stable IDs, context-loaded sessions, impact analysis, doc sync), with rules, skills and hooks for Cursor and Claude Code.
2. Create the Android project foundation: build environments, MVVM architecture, networking, logging/crash reporting, adaptive tablet layout, design tokens, shared components and shared states — covering the 20 foundation tasks (`FR-FOUND-001`…`FR-FOUND-020`, section 9).

### Non-goals

- Business features (menu, ordering, kitchen, payments, login UI).
- Dark mode and non-English languages (English-only, light-only by product decision; strings still live in resources so translation stays possible).
- Multi-module Gradle structure.
- Git initialization, remotes and CI (the user manages git).
- Real brand tokens (Figma values arrive later — PDR-002).

### Settled decisions

| Topic | Decision |
|---|---|
| Repos | Two sibling folders: `~/AndroidStudioProjects/resturant-app` (code) and `~/AndroidStudioProjects/resturant-app-architecture` (context). No git init. |
| App identity | `com.noshitechinc.restaurant`, display name "Noshitech Restaurant" |
| Devices | Tablet only; landscape always requested via OrientationPolicy; portrait and multi-window still required on Android 16 |
| Stack | Butterfly core stack with its gaps fixed (section 3) |
| Modules | Single `:app` module with strict package layering |
| Auth | Backend undefined → pluggable `AuthProvider`, Bearer + refresh default, placeholder URLs |
| Crash reporting | Firebase Crashlytics + Timber |
| Formats | USD currency, +1 (US) phone, US address fields |
| Tokens | Placeholder values, Figma-ready structure |
| App launch | Blank home screen; components verified through `@Preview` |
| MVVM state | UiState + `LoadState` + Channel effects + `BaseViewModel.launchSubmit` |
| AI tools | Cursor and Claude Code |
| Hooks | Secrets/dangerous-command guard, ktlint on edit, design lint on UI edit, doc-sync reminder on stop, hot-file injection on session start |
| Tests | Unit + ViewModel harness + Compose UI tests for key components |

---

## 2. AI-DLC setup

### 2.1 Context repo — `resturant-app-architecture`

```
resturant-app-architecture/
├── README.md                         # what this repo is, how to start a session
├── AGENTS.md                         # Tier-1: plan-before-act + doc-sync rules (tool-neutral)
├── PROJECT-INDEX.md                  # Tier-1: phase, status, decisions, open PDRs, links
├── .ai/
│   ├── AI-ASSISTANT-RULES.md         # Tier-1: project ALWAYS/NEVER rules + impact-analysis snippet
│   └── context/
│       └── project-overview.md       # Tier-1: condensed product + tech context
├── docs/
│   ├── 00-project-context/PROJECT-CONTEXT.md
│   ├── 01-concept/CONCEPT-NOTE.md               # short: restaurant tablet POS
│   ├── 02-specification/SPECIFICATION.md        # FR-FOUND-001..020 (section 9)
│   ├── 03-context/
│   │   ├── BUSINESS-TECH-CONTEXT.md
│   │   ├── PENDING-DECISIONS.md                 # PDR-001..004
│   │   ├── API-REGISTRY.md                      # api:{domain}:{slug}, empty
│   │   └── adr/
│   │       ├── ADR-001-platform-and-stack.md
│   │       ├── ADR-002-mvvm-architecture.md
│   │       ├── ADR-003-build-flavors-and-config.md
│   │       ├── ADR-004-networking-and-auth.md
│   │       ├── ADR-005-logging-and-crash-reporting.md
│   │       └── ADR-006-design-system-and-adaptive-layout.md
│   ├── 05-breakdown/
│   │   ├── modules/FOUND.md                     # module overview + FR → ticket map
│   │   └── sprints/sprint-0.md                  # FOUND-001..020 with status
│   ├── 06-development/
│   │   ├── TEST-CONTEXT.md                      # Android test strategy + hook verification log
│   │   └── impact-analyses/                     # IA-YYYY-MM-DD-<topic>.md
│   └── superpowers/
│       ├── specs/                               # this document
│       └── plans/                               # implementation plan
└── templates/
    ├── IMPACT-ANALYSIS-template.md
    └── ADR-template.md
```

Phase 4 (context directories) is skipped — the playbook marks it optional for small projects.

**Pending decisions** recorded at bootstrap:

| ID | Decision | Default until decided |
|---|---|---|
| PDR-001 | Backend auth scheme (token format, refresh endpoint, device pairing?) | Bearer + refresh via `AuthProvider` with placeholder endpoint |
| PDR-002 | Brand tokens from Figma | Placeholder palette, system font |
| PDR-003 | API base URLs per environment | `https://api.dev.example.invalid/` style placeholders |
| PDR-004 | Firebase projects per environment | Plugins skipped when `google-services.json` absent |

**ID schemes** (never renamed once published): `FR-FOUND-NNN` requirements, `FOUND-NNN` tickets, `FOUND-QA-NNN` test cases, `api:{domain}:{slug}` endpoints, `ADR-NNN`, `PDR-NNN`.

### 2.2 AI files in the code repo — `resturant-app`

```
resturant-app/
├── AGENTS.md                 # load ../resturant-app-architecture Tier-1 files first; code conventions
├── CLAUDE.md                 # thin: imports AGENTS.md
├── .ai/skills/               # canonical skills (single source)
│   ├── scaffold-screen/SKILL.md
│   ├── build-ui-component/SKILL.md
│   ├── add-api-endpoint/SKILL.md
│   ├── impact-analysis/SKILL.md
│   ├── review-change/SKILL.md
│   └── doc-sync/SKILL.md
├── .cursor/
│   ├── settings.json         # existing (superpowers plugin)
│   ├── rules/
│   │   ├── session-bootstrap.mdc     # alwaysApply
│   │   ├── impact-analysis.mdc       # alwaysApply
│   │   ├── architecture-mvvm.mdc     # globs: app/src/**/*.kt
│   │   ├── ui-design-system.mdc      # globs: **/core/designsystem/**, **/feature/**, **/core/ui/**
│   │   ├── networking.mdc            # globs: **/core/network/**, **/core/auth/**, **/data/**
│   │   └── testing.mdc               # globs: app/src/test/**, app/src/androidTest/**
│   ├── skills -> ../.ai/skills       # symlink
│   └── hooks.json
├── .claude/
│   ├── settings.json         # hooks + permissions (no secrets, no absolute user paths)
│   └── skills -> ../.ai/skills       # symlink
└── scripts/ai-hooks/         # shared bash scripts used by both tools
    ├── session-start.sh      # emits Tier-1 hot-file paths + "verify understanding" instruction
    ├── guard-secrets.sh      # denies reads/edits of secrets; denies dangerous shell commands
    ├── format-kotlin.sh      # ktlint --format on the edited .kt/.kts file
    ├── design-lint.sh        # flags hardcoded colors/dp/sp/strings, missing @Preview
    └── doc-sync-reminder.sh  # on stop: if contract files changed, remind to sync context docs
```

**Rule content** (summary):

- `session-bootstrap`: read the four Tier-1 files from `../resturant-app-architecture`, summarize understanding, confirm with the user, ask clarifying questions before implementing; one task per chat.
- `impact-analysis`: before changing API contracts, `ApiResult`/`AppError`, `BaseViewModel`, tokens, shared components' public parameters, build config or flavors → run the `impact-analysis` skill and get plan approval; execution order `API → clients → tests → docs`.
- `architecture-mvvm`: layering and dependency direction (section 4), Route/Screen split, no Android/Compose types in ViewModels, `launchSubmit` for mutations, use cases only for cross-repository or business logic.
- `ui-design-system`: tokens only, reuse components, previews for each variant, long-content rules, adaptive rules, `strings.xml` for all user-facing text.
- `networking`: `safeApiCall` only, DTO → domain mapping, register endpoints in `API-REGISTRY.md`, never log tokens.
- `testing`: test locations, fakes over mocks for repositories, Turbine for flows, `MainDispatcherRule`.

**Hook behaviour**:

| Hook | Cursor event | Claude Code event | Behaviour |
|---|---|---|---|
| session-start | `sessionStart` | `SessionStart` | Injects hot-file paths and bootstrap instruction as context |
| guard-secrets | `beforeReadFile`, `beforeShellExecution` | `PreToolUse` (Read/Edit/Write/Bash) | Deny: `local.properties`, `google-services.json`, `*.jks`, `*.keystore`, `*.env`, `secrets.*`; `git push --force`, `--no-verify`, `git reset --hard`, `rm -rf` outside `build/` |
| format-kotlin | `afterFileEdit` | `PostToolUse` (Edit/Write) | `ktlint --format <file>` for `.kt`/`.kts`; silent on success |
| design-lint | `afterFileEdit` | `PostToolUse` (Edit/Write) | For UI Kotlin files: report `Color(0x…)`, raw `.dp`/`.sp` literals outside theme, string literals in `Text(`, `@Composable` public functions in component/screen files without a `@Preview` in the same file; feedback returned to the agent |
| doc-sync-reminder | `stop` | `Stop` | If files under `data/remote/`, `core/network/`, `core/auth/`, `app/build.gradle.kts`, `config/env/` changed in the session, remind to update `API-REGISTRY.md`, ADRs, `PROJECT-INDEX.md` |

Exact hook event names and payload formats are verified against current Cursor and Claude Code documentation during implementation (Cursor `create-hook` skill). Scripts depend only on `bash`, `jq` and `ktlint` (ktlint via the Gradle wrapper fallback if the CLI is absent).

---

## 3. Build and environments

### 3.1 Toolchain and libraries

Versions follow Butterfly unless noted; exact versions pinned in `gradle/libs.versions.toml`.

| Area | Choice |
|---|---|
| Build | AGP 9.0.1 (built-in Kotlin), Kotlin 2.2.10, KSP, Gradle wrapper 9.2.1, JDK 21 |
| SDK | minSdk 25, targetSdk 36, compileSdk 36 |
| UI | Compose BOM 2025.07.00, Material3, material3-window-size-class, material3-adaptive, core-splashscreen, activity-compose, lifecycle-runtime-compose |
| DI | Hilt 2.56, hilt-navigation-compose |
| Navigation | Navigation Compose 2.8.5, type-safe `@Serializable` routes |
| Network | Retrofit 2.11 + kotlinx.serialization converter, OkHttp 4.12 + logging-interceptor, kotlinx.serialization JSON |
| Storage | DataStore Preferences; token encryption via Android Keystore AES-GCM |
| Images | Coil 3 (compose + network-okhttp) |
| Logging | Timber, Firebase BOM + Crashlytics |
| Quality | ktlint (Gradle plugin), detekt |
| Tests | JUnit4, MockK, Turbine, kotlinx-coroutines-test, OkHttp MockWebServer, Compose ui-test-junit4 |

Excluded from Butterfly: Room, Gson, dataBinding/viewBinding, duplicate core-ktx, SDP/SSP, security-crypto (deprecated).

detekt compatibility with Kotlin 2.2 is verified while writing the plan; if only a pre-release supports it, that version is pinned and noted in ADR-001.

### 3.2 Flavors

One dimension `environment`:

| Flavor | applicationId | App name | HTTP log | Crashlytics |
|---|---|---|---|---|
| `dev` | `com.noshitechinc.restaurant.dev` | Noshitech Restaurant (Dev) | BODY | off |
| `staging` | `com.noshitechinc.restaurant.staging` | Noshitech Restaurant (Staging) | HEADERS | on |
| `prod` | `com.noshitechinc.restaurant` | Noshitech Restaurant | NONE | on |

Build types: `debug`, `release` (R8 minify + resource shrinking, keep rules for kotlinx.serialization and Retrofit).

### 3.3 Configuration

- Non-secret values in committed `config/env/{dev,staging,prod}.properties`: `API_BASE_URL`, `HTTP_LOG_LEVEL`, `CRASH_REPORTING_ENABLED`, `CONNECT_TIMEOUT_SECONDS`, `READ_TIMEOUT_SECONDS`.
- One loader function in `app/build.gradle.kts` maps each file into `BuildConfig` fields for its flavor (no per-flavor copy-paste).
- Secrets (signing, future API keys) from `local.properties` or environment variables; `local.properties.example` documents keys.
- Release signing is configured only when all four signing values are present; otherwise the release build is unsigned.
- Google Services and Crashlytics Gradle plugins are applied only when `app/src/<flavor>/google-services.json` exists; `.gitignore` excludes those files.

### 3.4 Commands (README)

- `./gradlew assembleDevDebug`
- `./gradlew assembleDevDebug assembleStagingDebug assembleProdRelease`
- `./gradlew ktlintCheck detekt testDevDebugUnitTest`
- `./gradlew connectedDevDebugAndroidTest`

---

## 4. Architecture (MVVM)

### 4.1 Package layout — `com.noshitechinc.restaurant`

```
app/                RestaurantApplication, MainActivity
navigation/         Routes (@Serializable), AppNavHost
feature/home/       HomeRoute, HomeScreen, HomeViewModel, HomeUiState
domain/             model/, repository/ (interfaces), usecase/
data/               remote/api/, remote/dto/, mapper/, repository/ (…RepositoryImpl)
core/common/        AppDispatchers, ApiResult, AppError, UiText, MarketConfig, formatters/validators
core/ui/            BaseViewModel, LoadState, UiEffect, AppScaffold, UiEffectsHandler
core/network/       NetworkModule, interceptors, TokenAuthenticator, safeApiCall, ErrorMapper, ErrorBodyParser, NetworkMonitor
core/auth/          AuthProvider, TokenStore, KeystoreTokenStore, SessionManager
core/logging/       Timber trees, CrashReporter, CrashlyticsCrashReporter, NoOpCrashReporter
core/designsystem/  theme/ (tokens, AppTheme), component/, state/, preview/
core/adaptive/      WindowSizeClass provider, OrientationPolicy, adaptive containers
di/                 Hilt modules
```

**Dependency direction:** `feature` → `domain` ← `data`; `core/*` is usable by all; `domain` is pure Kotlin (no Android imports); `designsystem` never depends on `feature`, `data` or `domain`.

### 4.2 Screen contract

- `XxxUiState`: immutable data class, exposed as `StateFlow<XxxUiState>`.
- `LoadState<out T>`: `Idle`, `Loading`, `Content(data: T)`, `Empty`, `Error(error: AppError)`. Used for each independently loaded section.
- `UiText`: `Resource(@StringRes id, args)` or `Dynamic(value)` (server text that passed sanitizing). ViewModels never hold `Context` or Compose types.
- `BaseViewModel`:
  - `effects: Flow<UiEffect>` backed by `Channel(Channel.BUFFERED)`; base effects `ShowMessage(text, tone)` and `ShowErrorDialog(error)`; features add their own sealed effect types.
  - `launchSubmit(key: String, block: suspend () -> Unit)`: ignores the call if `key` is running; tracks running keys in `StateFlow<Set<String>>`; releases the key in `finally` (success, failure, cancellation).
  - `isSubmitting(key): StateFlow<Boolean>` for button loading/disabled states.
  - `presentError(error: AppError)`: maps an error to the right effect (transient message vs dialog vs session end).
- Screens: `XxxRoute(viewModel = hiltViewModel(), onNavigate…)` collects state with `collectAsStateWithLifecycle()` and effects in a lifecycle-aware collector; `XxxScreen(state, onAction…)` is stateless and owns all previews.
- Navigation is triggered by callbacks from the Route; ViewModels emit navigation effects only when navigation depends on a result.

### 4.3 Data layer

- Repository interfaces in `domain/repository`, implementations `…RepositoryImpl` in `data/repository`, bound with `@Binds`.
- DTOs in `data/remote/dto` (`@Serializable`), mapped with `toDomain()` extensions in `data/mapper`.
- Repositories return `ApiResult<DomainModel>`; ViewModels translate to `LoadState`.

---

## 5. Networking, auth and error handling

### 5.1 OkHttp chain

1. `HeaderInterceptor`: `Accept: application/json`, `Accept-Language: en`, `X-App-Version`, `X-Platform: android`.
2. `AuthInterceptor`: adds `Authorization: Bearer <token>` from `TokenStore`'s in-memory cache (hydrated at startup off the main thread); skips requests annotated as unauthenticated.
3. `HttpLoggingInterceptor`: level from `BuildConfig.HTTP_LOG_LEVEL`; `Authorization` and cookie headers redacted.

`TokenAuthenticator` is installed as the OkHttp `Authenticator`.

### 5.2 Auth

- `AuthProvider` interface: `suspend fun refresh(refreshToken: String): TokenPair?`. Default implementation calls a placeholder refresh endpoint via a separate Retrofit instance without the authenticator (PDR-001).
- `TokenStore`: stores access and refresh tokens in DataStore encrypted with an Android Keystore AES-GCM key; exposes the in-memory cache for the interceptor.
- `TokenAuthenticator`: on 401, takes a `Mutex`; if the token changed since the failed request, retries with the new token; otherwise refreshes once; gives up after one retry per request (`priorResponse` check); on refresh failure calls `SessionManager.endSession()`.
- `SessionManager`: clears tokens and emits `sessionEnded: SharedFlow<Unit>` observed by the app shell (routes to home until a login exists).

### 5.3 Errors

- `safeApiCall { }` returns `ApiResult.Success(data)` or `ApiResult.Failure(error: AppError)`; rethrows `CancellationException`.
- `AppError`: `NoInternet`, `Timeout`, `ServiceUnavailable` (HTTP 502/503/504), `SessionExpired` (401 after refresh failure), `Forbidden` (403), `NotFound` (404), `Validation(message, fieldErrors)` (400/422), `Server(code, message)` (other 5xx), `Unknown(cause)`.
- `ErrorBodyParser`: replaceable; default parses `{ "message": String?, "code": String?, "errors": { field: [String] }? }`.
- Server messages are shown only if they pass sanitizing (non-blank, ≤ 280 chars, no stack traces/HTML/SQL-like text); otherwise a string resource for the error kind is used.
- `NetworkMonitor`: `StateFlow<Boolean>` from a `ConnectivityManager` network callback, shared in an application scope.
- `AppScaffold(requiresNetwork = true)` shows `OfflineBlockingState` over the content while offline.

---

## 6. Logging and crash reporting

- `dev`: `Timber.DebugTree`.
- `staging`/`prod`: `CrashReportingTree` — `WARN`/`ERROR` with throwable → `recordException`; other levels ≥ `INFO` → Crashlytics log breadcrumbs; `DEBUG`/`VERBOSE` dropped.
- `CrashReporter` interface: `setUserId`, `setKey`, `log`, `recordException`. `CrashlyticsCrashReporter` when Firebase is initialized and `CRASH_REPORTING_ENABLED`; otherwise `NoOpCrashReporter`.
- Custom keys set at startup: environment, version name/code, device class (tablet).
- Never log tokens, full request bodies outside dev, or personal data.

---

## 7. Design system

### 7.1 Tokens (`core/designsystem/theme/`, light only, placeholder values — PDR-002)

| Token set | Contents |
|---|---|
| `AppColors` | primary, onPrimary, primaryContainer, secondary, onSecondary, background, surface, surfaceVariant, outline, outlineVariant, textPrimary, textSecondary, textDisabled, destructive, onDestructive, success, warning, info, focusRing, scrim; status tones new / preparing / ready / served / cancelled |
| `AppTypography` | displayLarge…labelSmall scale on `FontFamily.Default`, plus `numeric` styles with tabular figures (`tnum`) for prices and quantities |
| `AppSpacing` | none 0, xxs 2, xs 4, sm 8, md 12, lg 16, xl 24, xxl 32, xxxl 48 (dp) |
| `AppRadius` | none 0, xs 4, sm 8, md 12, lg 16, xl 24, pill |
| `AppBorder` | thin 1, medium 1.5, thick 2, focus 2 (dp) |
| `AppSizes` | minTouchTarget 48, posButtonHeight 56, iconSm/Md/Lg, dialogMaxWidth 560, content max widths |

Exposed through `AppTheme.colors`, `AppTheme.typography`, `AppTheme.spacing`, `AppTheme.radius`, `AppTheme.border`, `AppTheme.sizes` (CompositionLocals), and mapped into Material3 `lightColorScheme`, `Typography` and `Shapes`.

### 7.2 Components (`core/designsystem/component/`)

| Group | Components | Variants/states |
|---|---|---|
| Buttons | `AppButton(variant = Primary/Secondary/Outline/Destructive, size = Small/Medium/Large)`, `AppIconButton` | enabled, disabled, pressed, focused, loading (spinner, click blocked) |
| Inputs | `AppTextField`, `SearchField`, `NumericField`, `CurrencyField` (USD, value in cents `Long`), `PhoneField` (`+1 (XXX) XXX-XXXX`), `AddressInput` (street, unit, city, state, ZIP), `TimeField` (Material3 time picker) | enabled, disabled, focused, error + helper text, read-only |
| Selection | `AppSwitch`, `SegmentedControl`, `FilterChipGroup`, `StatusBadge(tone)` | selected, unselected, disabled, focused |
| Quantity | `QuantityStepper(min, max)`, `NumericKeypad(mode = Integer/Decimal/Currency/Pin)` | bounds disabled, pressed keys, disabled |
| Cards | `MenuItemCard`, `OrderLineCard`, `OrderCard`, `KitchenTicketCard` | normal, unavailable/disabled, selected, elapsed-time warning/overdue |
| Dialogs | `AppModal`, `ConfirmationDialog` (normal/destructive), `SuccessDialog` | confirm loading, dismiss disabled while loading |
| Rows | `ListRow`, `SettingsRow` (navigation, switch, value, destructive) | enabled, disabled, pressed, focused |

### 7.3 States (`core/designsystem/state/`)

`LoadingState`, `AppLinearProgress`, `AppCircularProgress`, `SkeletonList`, `EmptyState`, `NoSearchResultsState(query)`, `ErrorState(error, onRetry)` (copy chosen by `AppError` kind), `ServiceUnavailableState(onRetry)`, `OfflineBlockingState(onRetry)` (dismisses when connectivity returns).

### 7.4 Long-content rules

- Names: `maxLines` + ellipsis; prices never truncated (price measured first, name takes remaining width).
- Addresses wrap up to 3 lines.
- Buttons and chips grow in height instead of truncating labels.
- Verified at font scale 1.0, 1.5, 2.0 and with the `en-XA` pseudo-locale (`pseudoLocalesEnabled` in debug).

### 7.5 Previews (`core/designsystem/preview/`)

- Multipreview annotations: `@TabletLandscapePreview` (1280×800 dp), `@TabletPortraitPreview` (800×1280 dp), `@FontScalePreviews` (1.0/1.5/2.0), `@ComponentPreviews` (combined).
- `PreviewSurface { }` applies `AppTheme` and a surface background.
- `PreviewData`: sample menu items, orders, addresses including extra-long variants.
- Pressed/focused visuals shown via a preview-only `PreviewInteractionSource` helper.
- Every component and screen file ends with previews covering each variant and state.

---

## 8. Adaptive layout and orientation

- `WindowSizeClass` computed in `MainActivity` and provided via `LocalWindowSizeClass`; preview override helper for previews.
- Compact width (< 600 dp): single-pane narrow multi-window layout. Medium/Expanded: two-pane layouts, grid columns by width (compact 2 / medium 3 / expanded 4 for cards), max content widths for forms and dialogs.
- `OrientationPolicy` in `MainActivity`: `smallestScreenWidthDp >= 600` → `SCREEN_ORIENTATION_SENSOR_LANDSCAPE`; otherwise `UNSPECIFIED`.
- Android 16 (targetSdk 36) ignores orientation and resizability restrictions on sw600dp+ displays. The manifest opt-out property `android.window.PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY` is added (effective for targetSdk 36 only). Tablet layouts must therefore still work in portrait and multi-window. Recorded in ADR-006.

---

## 9. Requirements traceability

| FR ID | Ticket | Requirement | Design section |
|---|---|---|---|
| FR-FOUND-001 | FOUND-001 | Android project and environment configuration | 3 |
| FR-FOUND-002 | FOUND-002 | Development, staging and production builds | 3.2, 3.3 |
| FR-FOUND-003 | FOUND-003 | Landscape tablet layout and screen-size rules | 8 |
| FR-FOUND-004 | FOUND-004 | Networking, API authentication, common API error handling | 5 |
| FR-FOUND-005 | FOUND-005 | Application logging and crash reporting | 6 |
| FR-FOUND-006 | FOUND-006 | Colour, typography, spacing, radius and border tokens | 7.1 |
| FR-FOUND-007 | FOUND-007 | Primary, secondary, outline and destructive buttons | 7.2 |
| FR-FOUND-008 | FOUND-008 | Text, search, numeric, currency, phone, address and time inputs | 7.2 |
| FR-FOUND-009 | FOUND-009 | Switches, segmented controls, filter chips, status badges | 7.2 |
| FR-FOUND-010 | FOUND-010 | Quantity steppers and numeric keypads | 7.2 |
| FR-FOUND-011 | FOUND-011 | Menu item, order line, order and kitchen status cards | 7.2 |
| FR-FOUND-012 | FOUND-012 | Shared modal, confirmation and success dialogs | 7.2 |
| FR-FOUND-013 | FOUND-013 | Common list rows and settings rows | 7.2 |
| FR-FOUND-014 | FOUND-014 | Disabled, pressed, focused, loading and error variants | 7.2, 7.5 |
| FR-FOUND-015 | FOUND-015 | Common loading and progress states | 7.3 |
| FR-FOUND-016 | FOUND-016 | Empty-list and no-search-result states | 7.3 |
| FR-FOUND-017 | FOUND-017 | API error and retry states | 5.3, 7.3 |
| FR-FOUND-018 | FOUND-018 | Service-unavailable and blocking offline states | 5.3, 7.3 |
| FR-FOUND-019 | FOUND-019 | Prevent duplicate submissions while requests run | 4.2, 7.2 |
| FR-FOUND-020 | FOUND-020 | Long names, addresses, prices, translated content without layout breakage | 7.4 |

---

## 10. Testing

| Level | Location | Coverage |
|---|---|---|
| Unit | `app/src/test` | `ErrorMapper` (each status/exception → `AppError`, sanitizing); `safeApiCall` rethrows cancellation; `TokenAuthenticator` (single refresh for parallel 401s via MockWebServer, session end on failure, max one retry); currency/phone/address formatters and validators; `BaseViewModel.launchSubmit` (ignore re-entry, release on success/failure/cancel) |
| ViewModel harness | `app/src/test` | `MainDispatcherRule`, fakes in `test/.../fakes/`, example `HomeViewModelTest` used as the template by `scaffold-screen` |
| Compose UI | `app/src/androidTest` | `QuantityStepper` bounds, `NumericKeypad` modes, `AppButton` loading blocks second tap, `OfflineBlockingState` show/dismiss |

`TEST-CONTEXT.md` in the context repo replaces the playbook's Playwright guidance with this Android strategy and holds the hook verification log.

---

## 11. Definition of done

1. `./gradlew assembleDevDebug assembleStagingDebug assembleProdRelease` succeeds without any `google-services.json`.
2. `./gradlew ktlintCheck detekt testDevDebugUnitTest` passes.
3. Every component and screen file has previews covering its variants (tablet landscape, tablet portrait, font scale 2.0).
4. No hardcoded colors, dp/sp values or user-facing strings outside token and resource files; `scripts/ai-hooks/design-lint.sh` run over `app/src/main` reports nothing.
5. `SPECIFICATION.md`, `modules/FOUND.md` and `sprints/sprint-0.md` trace all 20 FR IDs to tickets, code and tests; `PROJECT-INDEX.md` shows the foundation complete with PDR-001…004 open.
6. Each hook triggered at least once in Cursor (secrets guard blocks reading `local.properties`; format and design lint run on edit; session-start and stop fire), results recorded in `TEST-CONTEXT.md`.

## 12. Build order

1. Context repo and Tier-1 hot files, phase docs, ADRs, PDRs.
2. Code repo AI files: `AGENTS.md`, `CLAUDE.md`, rules, skills, hook scripts and configs.
3. Gradle skeleton, version catalog, flavors, config loader, manifest.
4. Core: common, logging, network, auth, adaptive.
5. Tokens and theme.
6. Components in task order (buttons → inputs → selection → quantity → cards → dialogs → rows).
7. State components and `AppScaffold`.
8. Blank home screen and navigation.
9. Tests.
10. Doc sync: index, sprint board, traceability, test context.

## 13. Risks

| Risk | Mitigation |
|---|---|
| detekt may not support Kotlin 2.2.10 on a stable release | Verify during planning; pin pre-release or defer detekt with a PDR |
| AGP 9 built-in Kotlin changes plugin setup (KSP, Hilt, serialization) | Mirror Butterfly's working plugin configuration |
| Hook event names/payloads differ between tool versions | Verify against current docs; scripts accept both payload shapes |
| Orientation lock ignored on Android 16+ tablets | Opt-out property + layouts tested in tablet portrait |
| Placeholder tokens diverge from Figma | All values in token files only; design lint enforces no literals elsewhere |

---

## 14. Plan-time amendments (2026-09-24)

Verified facts and refinements found while writing the implementation plans. Where this section conflicts with earlier sections, this section wins.

| Topic | Amendment | Reason |
|---|---|---|
| detekt | `dev.detekt` 2.0.0-alpha.3 (first release supporting AGP 9 built-in Kotlin); fallback: remove detekt, keep ktlint + Android lint, record PDR-005 | detekt 1.x does not support Kotlin 2.2 / AGP 9 |
| ktlint | ktlint-gradle 14.2.0 with ktlint 1.8.0; the same CLI version is auto-downloaded by the format hook | Built-in Kotlin support arrived in 14.1.0 |
| Firebase | BOM 34.1.0 (`firebase-crashlytics`, no KTX), google-services plugin 4.4.2, Crashlytics plugin 3.0.8 | Crashlytics 20.x needed for AGP 9 R8; KTX modules removed in BOM 34 |
| Coil | 3.3.0 | 3.4+ pulls Compose versions newer than BOM 2025.07 |
| Adaptive | Own `AdaptiveInfo` + `WidthClass` from `LocalConfiguration` (no `material3-window-size-class` / `material3-adaptive` dependencies) | Works in previews without providers; fewer dependencies |
| `UiEffect` | Open `interface UiEffect` (base effects `ShowMessage`, `ShowErrorDialog`) so features add their own effect types | Sealed types cannot be extended from other packages |
| Submitting state | `BaseViewModel.submittingKeys: StateFlow<Set<String>>` + `isSubmitting(key): Boolean`; `launchSubmit` also catches unexpected exceptions and presents `AppError.Unknown` | Avoids per-call flows; submit keys always released |
| Error-aware states | `ErrorState`, `ServiceUnavailableState`, `OfflineBlockingState`, `LoadStateContent`, `AppScaffold` live in `core/ui/state` / `core/ui`; generic states stay in `core/designsystem/state` | `designsystem` must not depend on `AppError` mapping |
| Status tones | `StatusTone { Neutral, Info, Success, Warning, Danger }`; order/kitchen statuses map to tones in features | Keeps domain concepts out of the design system |
| Time input | `TimeOfDay(hour, minute)` + `java.util.Calendar` formatting | `java.time` needs desugaring on minSdk 25 |
| Skills location | Canonical `.cursor/skills/`; `.claude/skills` → symlink `../.cursor/skills` | Cursor is the primary tool; one hop for Claude |
| Hooks | Scripts take `cursor|claude` argument; Claude-config hooks skip non-permission work when running inside Cursor (third-party hooks) to avoid duplicates; edits are tracked in `.ai/.session/<id>.log` because repos have no git | Cursor can load `.claude/settings.json`; no git diff available |
| Local SDK | Agents run Gradle with `ANDROID_HOME=$HOME/Android/Sdk`; `local.properties` is never read or written by agents | Guard hook blocks secret files |
| Launcher icon | Vector adaptive icon in `drawable-anydpi-v26` + layer-list fallback in `drawable` | minSdk 25 predates adaptive icons |
