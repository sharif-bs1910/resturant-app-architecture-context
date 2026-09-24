# Specification — Foundation module (FOUND)

Phase 2. Functional requirements for the Android foundation, `FR-FOUND-001`…`FR-FOUND-020`. Each requirement maps to one ticket (`FOUND-NNN`) on the [sprint-0 board](../05-breakdown/sprints/sprint-0.md); code paths and tests are traced in [modules/FOUND.md](../05-breakdown/modules/FOUND.md).

"spec §N" refers to the [foundation design spec](../superpowers/specs/2026-09-24-android-foundation-design.md). Where the spec's section 14 amends an earlier section, the amended value is used here.

IDs are permanent. If an acceptance criterion changes, the text is updated under the same ID; a removed requirement keeps its ID and is marked withdrawn.

## Requirements

| FR ID | Ticket | Requirement | Design |
|---|---|---|---|
| FR-FOUND-001 | FOUND-001 | Android project and environment configuration | spec §3, §4.1, §14 |
| FR-FOUND-002 | FOUND-002 | Development, staging and production builds | spec §3.2, §3.3 |
| FR-FOUND-003 | FOUND-003 | Landscape tablet layout and screen-size rules | spec §8, §14 |
| FR-FOUND-004 | FOUND-004 | Networking, API authentication, common API error handling | spec §5 |
| FR-FOUND-005 | FOUND-005 | Application logging and crash reporting | spec §6 |
| FR-FOUND-006 | FOUND-006 | Colour, typography, spacing, radius and border tokens | spec §7.1, §14 |
| FR-FOUND-007 | FOUND-007 | Primary, secondary, outline and destructive buttons | spec §7.2 |
| FR-FOUND-008 | FOUND-008 | Text, search, numeric, currency, phone, address and time inputs | spec §7.2, §14 |
| FR-FOUND-009 | FOUND-009 | Switches, segmented controls, filter chips, status badges | spec §7.2, §14 |
| FR-FOUND-010 | FOUND-010 | Quantity steppers and numeric keypads | spec §7.2 |
| FR-FOUND-011 | FOUND-011 | Menu item, order line, order and kitchen status cards | spec §7.2 |
| FR-FOUND-012 | FOUND-012 | Shared modal, confirmation and success dialogs | spec §7.2 |
| FR-FOUND-013 | FOUND-013 | Common list rows and settings rows | spec §7.2 |
| FR-FOUND-014 | FOUND-014 | Disabled, pressed, focused, loading and error variants | spec §7.2, §7.5 |
| FR-FOUND-015 | FOUND-015 | Common loading and progress states | spec §7.3 |
| FR-FOUND-016 | FOUND-016 | Empty-list and no-search-result states | spec §7.3 |
| FR-FOUND-017 | FOUND-017 | API error and retry states | spec §5.3, §7.3, §14 |
| FR-FOUND-018 | FOUND-018 | Service-unavailable and blocking offline states | spec §5.3, §7.3, §14 |
| FR-FOUND-019 | FOUND-019 | Prevent duplicate submissions while requests run | spec §4.2, §7.2, §14 |
| FR-FOUND-020 | FOUND-020 | Long names, addresses, prices, translated content without layout breakage | spec §7.4 |

## Details

### FR-FOUND-001 — Android project and environment configuration
- **Requirement:** Provide a buildable single-module Android project with pinned toolchain and libraries and the agreed package layering.
- **Acceptance:** Single `:app` module with application ID base `com.noshitechinc.restaurant` and display name "Noshitech Restaurant"; AGP 9.0.1 with built-in Kotlin 2.2.10, KSP, Gradle wrapper 9.2.1, JDK 21; minSdk 25, targetSdk 36, compileSdk 36; every library version pinned in `gradle/libs.versions.toml` (Compose BOM 2025.07.00, Hilt 2.56, Navigation Compose 2.8.5, Retrofit 2.11, OkHttp 4.12, Coil 3.3.0, Firebase BOM 34.1.0, ktlint-gradle 14.2.0 with ktlint 1.8.0, detekt 2.0.0-alpha.3 per PDR-005); Room, Gson, dataBinding/viewBinding, SDP/SSP and security-crypto are absent; packages follow spec §4.1 (`app`, `navigation`, `feature`, `domain`, `data`, `core/*`, `di`) with `domain` free of Android imports; `RestaurantApplication` is the Hilt application and `MainActivity` hosts Compose; the launcher icon is a vector adaptive icon with a layer-list fallback for API 25; `./gradlew assembleDevDebug` succeeds.
- **Ticket:** FOUND-001 · **Design:** spec §3.1, §4.1, §14

### FR-FOUND-002 — Development, staging and production builds
- **Requirement:** Provide dev, staging and prod builds with per-environment configuration and no secrets in the repo.
- **Acceptance:** One flavor dimension `environment` with `dev` (`com.noshitechinc.restaurant.dev`, "Noshitech Restaurant (Dev)", HTTP log BODY, crash reporting off), `staging` (`com.noshitechinc.restaurant.staging`, "Noshitech Restaurant (Staging)", HEADERS, on) and `prod` (`com.noshitechinc.restaurant`, "Noshitech Restaurant", NONE, on); build types `debug` and `release`, with release using R8 minify and resource shrinking plus keep rules for kotlinx.serialization and Retrofit; non-secret values (`API_BASE_URL`, `HTTP_LOG_LEVEL`, `CRASH_REPORTING_ENABLED`, `CONNECT_TIMEOUT_SECONDS`, `READ_TIMEOUT_SECONDS`) live in committed `config/env/{dev,staging,prod}.properties` and one loader function maps them into `BuildConfig` fields (plus `ENVIRONMENT`); secrets come from `local.properties` or environment variables and `local.properties.example` documents the keys; release signing is configured only when all four signing values are present, otherwise release is unsigned; Google Services and Crashlytics plugins are applied only when `app/src/<flavor>/google-services.json` exists and those files are git-ignored; `./gradlew assembleDevDebug assembleStagingDebug assembleProdRelease` succeeds with no `google-services.json` present.
- **Ticket:** FOUND-002 · **Design:** spec §3.2, §3.3

### FR-FOUND-003 — Landscape tablet layout and screen-size rules
- **Requirement:** Lock tablets to landscape where the platform allows it and adapt layouts to the available width.
- **Acceptance:** `OrientationPolicy.requestedOrientation(smallestScreenWidthDp)` always returns `SCREEN_ORIENTATION_SENSOR_LANDSCAPE`, applied in `MainActivity` (tablet-only product); the manifest declares `android.window.PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY`; `AdaptiveInfo` and `WidthClass` are computed from `LocalConfiguration` (no window-size-class or adaptive libraries) with Compact < 600dp (narrow multi-window), Medium 600–839dp, Expanded ≥ 840dp; Compact uses a single pane, Medium and Expanded use two panes; card grids use 2 / 3 / 4 columns for Compact / Medium / Expanded; forms and dialogs respect max content widths from `AppTheme.sizes`; because Android 16 ignores the orientation lock on sw600dp+ displays, tablet layouts render correctly in tablet portrait and multi-window; screen previews cover tablet landscape (1280×800dp) and tablet portrait (800×1280dp).
- **Ticket:** FOUND-003 · **Design:** spec §8, §14

### FR-FOUND-004 — Networking, API authentication, common API error handling
- **Requirement:** Provide one HTTP client with authentication, token refresh and a common error model for every API call.
- **Acceptance:** The OkHttp chain is `HeaderInterceptor` (`Accept: application/json`, `Accept-Language: en`, `X-App-Version`, `X-Platform: android`) → `AuthInterceptor` (adds `Authorization: Bearer <token>` from the in-memory token cache, skips and strips requests marked `X-No-Auth`) → `HttpLoggingInterceptor` (level from `BuildConfig.HTTP_LOG_LEVEL`, `Authorization` and cookie headers redacted), with `TokenAuthenticator` installed as the `Authenticator`; on 401 the authenticator takes a `Mutex`, retries with the new token if another request already refreshed it, otherwise refreshes once through `AuthProvider`, retries each request at most once (`priorResponse` check) and calls `SessionManager.endSession()` when refresh fails; parallel 401s trigger exactly one refresh; tokens are stored in DataStore encrypted with an Android Keystore AES-GCM key and hydrated into memory off the main thread at startup; the default `AuthProvider` calls placeholder endpoint `api:auth:refresh` through a separate client without the authenticator (PDR-001); `safeApiCall { }` returns `ApiResult.Success` or `ApiResult.Failure(AppError)` and rethrows `CancellationException`; errors map to `NoInternet`, `Timeout`, `ServiceUnavailable` (502/503/504), `SessionExpired` (401 after refresh failure), `Forbidden` (403), `NotFound` (404), `Validation(message, fieldErrors)` (400/422), `Server(code, message)` (other 5xx) and `Unknown(cause)`; the replaceable `ErrorBodyParser` reads `{ "message", "code", "errors": { field: [String] } }`; server messages are shown only when non-blank, ≤ 280 characters and free of stack traces, HTML and SQL-like text, otherwise the string resource for the error kind is used; tokens are never logged.
- **Ticket:** FOUND-004 · **Design:** spec §5

### FR-FOUND-005 — Application logging and crash reporting
- **Requirement:** Log consistently in every build and report crashes and non-fatal errors from staging and prod.
- **Acceptance:** `dev` plants `Timber.DebugTree`; `staging` and `prod` plant `CrashReportingTree`, which sends `WARN`/`ERROR` logs with a throwable to `recordException`, sends other logs at `INFO` and above as Crashlytics breadcrumbs, and drops `DEBUG`/`VERBOSE`; code depends only on the `CrashReporter` interface (`setUserId`, `setKey`, `log`, `recordException`); `CrashlyticsCrashReporter` is used when Firebase is initialized and `CRASH_REPORTING_ENABLED` is true, otherwise `NoOpCrashReporter`; Crashlytics collection is disabled in `dev` through the manifest placeholder; custom keys `environment`, `version` (name and code) and `device_class` (`tablet`) are set at startup; tokens, request bodies outside dev and personal data are never logged; the app builds and runs with no Firebase configuration (PDR-004).
- **Ticket:** FOUND-005 · **Design:** spec §6

### FR-FOUND-006 — Colour, typography, spacing, radius and border tokens
- **Requirement:** Provide a single light theme whose values come only from design tokens.
- **Acceptance:** `core/designsystem/theme/` defines `AppColors` (primary, onPrimary, primaryContainer, secondary, onSecondary, background, surface, surfaceVariant, outline, outlineVariant, textPrimary, textSecondary, textDisabled, destructive, onDestructive, success, warning, info, focusRing, scrim), `AppTypography` (displayLarge…labelSmall on `FontFamily.Default` plus numeric styles with tabular figures `tnum` for prices and quantities), `AppSpacing` (none 0, xxs 2, xs 4, sm 8, md 12, lg 16, xl 24, xxl 32, xxxl 48 dp), `AppRadius` (none 0, xs 4, sm 8, md 12, lg 16, xl 24, pill), `AppBorder` (thin 1, medium 1.5, thick 2, focus 2 dp) and `AppSizes` (minTouchTarget 48dp, posButtonHeight 56dp, icon sizes, dialogMaxWidth 560dp, content max widths); tokens are exposed as `AppTheme.colors`, `.typography`, `.spacing`, `.radius`, `.border`, `.sizes` through CompositionLocals and mapped into Material3 `lightColorScheme`, `Typography` and `Shapes`; `StatusTone { Neutral, Info, Success, Warning, Danger }` provides container and content colours for badges and cards; values are placeholders structured for Figma replacement (PDR-002); only a light scheme exists; no colour, dp or sp literal appears outside `theme/` and preview code.
- **Ticket:** FOUND-006 · **Design:** spec §7.1, §14

### FR-FOUND-007 — Buttons
- **Requirement:** Provide primary, secondary, outline and destructive buttons.
- **Acceptance:** `AppButton` supports variants Primary/Secondary/Outline/Destructive and sizes Small/Medium/Large; shows disabled, pressed, focused and loading visuals; loading blocks clicks; labels wrap instead of truncating; previews cover every variant × state. `AppIconButton` is square, at least `AppTheme.sizes.minTouchTarget` (48dp), and requires a content description.
- **Ticket:** FOUND-007 · **Design:** spec §7.2

### FR-FOUND-008 — Inputs
- **Requirement:** Provide text, search, numeric, currency, phone, address and time inputs formatted for the US market.
- **Acceptance:** `AppTextField` supports label, placeholder, helper text, error text, enabled, disabled, focused and read-only states; `SearchField` has a search placeholder, clear action and IME search action; `NumericField` accepts digits only up to `maxDigits`; `CurrencyField` holds the value as cents in a `Long` and displays USD (for example `$1,234.56`) with the cursor kept at the end; `PhoneField` holds up to 10 digits and displays `+1 (XXX) XXX-XXXX`; `AddressInput` has street (up to 3 lines), unit, city, state (2 upper-case letters) and ZIP (digits and dash, up to 10 characters) fields, shows an error on each field reported invalid by `UsAddressValidator`, stacks all fields on compact width and places city, state and ZIP in one row on two-pane widths; `TimeField` opens the Material3 time picker and returns `TimeOfDay(hour, minute)` (hour 0–23, minute 0–59) formatted with `java.util.Calendar` (no `java.time` on minSdk 25); every input meets the 48dp touch target and has previews for each state including long labels and font scale 2.0.
- **Ticket:** FOUND-008 · **Design:** spec §7.2, §14

### FR-FOUND-009 — Selection controls
- **Requirement:** Provide switches, segmented controls, filter chips and status badges.
- **Acceptance:** `AppSwitch`, `SegmentedControl`, `FilterChipGroup` and `StatusBadge(text, tone)` exist in `component/selection`; switch, segments and chips show selected, unselected, disabled and focused visuals and meet the 48dp touch target; `SegmentedControl` labels allow two lines; `FilterChipGroup` wraps chips onto new rows and shows an optional count per option; `StatusBadge` colours come from `StatusTone` (Neutral, Info, Success, Warning, Danger) with an optional icon and a one-line label that ellipsizes; order and kitchen statuses are mapped to tones in features, not in the design system; previews cover every tone and state with long labels.
- **Ticket:** FOUND-009 · **Design:** spec §7.2, §14

### FR-FOUND-010 — Quantity steppers and numeric keypads
- **Requirement:** Provide a bounded quantity stepper and a numeric keypad with input modes.
- **Acceptance:** `QuantityStepper(quantity, onQuantityChange, min = 0, max = 99)` disables decrement at `min` and increment at `max`; `NumericKeypad` supports modes Integer, Decimal, Currency and Pin with a 4 × 3 key grid (left key is Decimal in Decimal mode, 00 in Currency mode, Clear in Integer and Pin modes) plus Backspace; `KeypadReducer` limits input to 9 characters, trims leading zeros except in Pin mode, allows one decimal separator with at most two fraction digits in Decimal mode, and ignores keys that do not apply to the current mode; pressed and disabled keys have distinct visuals; keys meet the touch-target size; Compose UI tests cover stepper bounds and each keypad mode.
- **Ticket:** FOUND-010 · **Design:** spec §7.2

### FR-FOUND-011 — Cards
- **Requirement:** Provide menu item, order line, order and kitchen ticket cards.
- **Acceptance:** All cards build on `AppCard` (normal, selected, pressed, focused, disabled); `MenuItemCard` shows optional image, name (2 lines), description (2 lines), price that is never truncated, an add action, and an unavailable state with disabled text and badge; `OrderLineCard` shows quantity, name, line total, modifiers, note, optional `QuantityStepper` (min 1) and remove action; `OrderCard` shows order number, status badge, title, item count, elapsed minutes and total, with a selected state; `KitchenTicketCard` shows ticket number, title, status, elapsed time with a header tinted by `ElapsedTone` (OnTime below the warning threshold, Warning from 10 minutes, Overdue from 20 minutes by default), toggleable item rows with struck-through done items, and an optional large action button with loading; previews include long names, long prices and a 4-column tablet grid.
- **Ticket:** FOUND-011 · **Design:** spec §7.2

### FR-FOUND-012 — Dialogs
- **Requirement:** Provide shared modal, confirmation and success dialogs.
- **Acceptance:** `AppModal` renders a title, scrollable content and wrapping actions at most `dialogMaxWidth` (560dp) wide; `ConfirmationDialog` has normal and destructive confirm styles; while `confirmLoading` is true the confirm button shows a spinner and ignores taps, the dismiss button is disabled, and back press and outside taps do not dismiss; `SuccessDialog` shows a success icon with content description, title, message and a full-width primary action; stateless `*Layout` variants carry the previews (normal, destructive, loading, long title and message at font scale 2.0).
- **Ticket:** FOUND-012 · **Design:** spec §7.2

### FR-FOUND-013 — List rows and settings rows
- **Requirement:** Provide common list rows and settings rows.
- **Acceptance:** `ListRow` supports title, subtitle, leading icon, trailing text, trailing content, chevron, enabled, disabled, pressed, focused and destructive states, with a minimum row height at or above the touch target; titles and subtitles wrap to 2 lines and trailing text is never truncated; `SettingsNavigationRow`, `SettingsSwitchRow` (the whole row toggles the switch), `SettingsValueRow` and `SettingsDestructiveRow` delegate to `ListRow`; previews cover each variant with long titles and values and the disabled state.
- **Ticket:** FOUND-013 · **Design:** spec §7.2

### FR-FOUND-014 — Interaction and state variants
- **Requirement:** Every interactive component shows disabled, pressed, focused, loading and error variants consistently.
- **Acceptance:** Interactive components accept `enabled` and an optional `interactionSource` and derive pressed and focused visuals from `rememberInteractionVisuals`; focus is shown as a `focusRing` using `AppTheme.colors.focusRing` and `AppTheme.border.focus`; disabled content uses `textDisabled` and disabled container colours; components with a loading state show a spinner and block input; inputs show error text in the destructive colour; previews show pressed and focused states through the preview-only `ForcedInteraction` helper; every component file ends with `@ComponentPreviews` covering each variant × applicable state.
- **Ticket:** FOUND-014 · **Design:** spec §7.2, §7.5

### FR-FOUND-015 — Loading and progress states
- **Requirement:** Provide common loading and progress states.
- **Acceptance:** `LoadingState` (centered spinner with optional message), `AppCircularProgress`, `AppLinearProgress` (determinate when `progress` is set, indeterminate otherwise) and `SkeletonList` (animated placeholder rows with an accessibility loading description) exist in `core/designsystem/state`; `LoadStateContent` shows the loading slot for `LoadState.Loading` and nothing for `Idle`; states scroll rather than clip at font scale 2.0; previews cover each state.
- **Ticket:** FOUND-015 · **Design:** spec §7.3

### FR-FOUND-016 — Empty and no-results states
- **Requirement:** Provide empty-list and no-search-result states.
- **Acceptance:** `EmptyState` has a default title, message and icon from resources and an optional action; `NoSearchResultsState(query)` includes the query in its title (limited to 3 lines so long queries do not break layout) and offers an optional clear-search action; `LoadStateContent` shows the caller's empty slot for `LoadState.Empty`; previews include long queries and font scale 2.0.
- **Ticket:** FOUND-016 · **Design:** spec §7.3

### FR-FOUND-017 — API error and retry states
- **Requirement:** Show API errors with an appropriate message and a retry action.
- **Acceptance:** `ErrorState(error, onRetry)` in `core/ui/state` picks icon, title and message by `AppError` kind (offline icon for `NoInternet`, cloud-off for `ServiceUnavailable`, error icon otherwise), uses the sanitized server message when present and the kind's string resource otherwise, and shows a retry button that can show loading; `LoadStateContent` shows `ErrorState` for `LoadState.Error` (except `ServiceUnavailable`); `BaseViewModel.presentError` shows `NoInternet` and `Timeout` as a transient error message and other errors as an error dialog; error-aware states live in `core/ui` so `designsystem` does not depend on `AppError`; unit tests cover status and exception mapping and message sanitizing.
- **Ticket:** FOUND-017 · **Design:** spec §5.3, §7.3, §14

### FR-FOUND-018 — Service-unavailable and blocking offline states
- **Requirement:** Show a service-unavailable state and block network-dependent screens while offline.
- **Acceptance:** `ServiceUnavailableState(onRetry)` is shown for `AppError.ServiceUnavailable` (HTTP 502/503/504); `NetworkMonitor` exposes `isOnline: StateFlow<Boolean>` from a `ConnectivityManager` callback shared in the application scope and provided to the UI as `LocalIsOnline`; `AppScaffold(requiresNetwork = true)` overlays `OfflineBlockingState` on the content while offline, the overlay consumes all touches and offers retry, and it disappears automatically when connectivity returns; a Compose UI test covers show and dismiss.
- **Ticket:** FOUND-018 · **Design:** spec §5.3, §7.3, §14

### FR-FOUND-019 — Duplicate-submission prevention
- **Requirement:** Prevent duplicate submissions while requests run.
- **Acceptance:** `BaseViewModel.launchSubmit(key) { }` ignores a call while the same key is running, tracks running keys in `submittingKeys: StateFlow<Set<String>>`, releases the key in `finally` on success, failure and cancellation, and presents unexpected exceptions as `AppError.Unknown`; `isSubmitting(key)` drives button `loading` and `enabled`; `AppButton(loading = true)` ignores taps; `ConfirmationDialog` and `KitchenTicketCard` actions block while loading; unit tests cover re-entry, release on success, failure and cancellation, and a Compose UI test shows a loading button ignores taps.
- **Ticket:** FOUND-019 · **Design:** spec §4.2, §7.2, §14

### FR-FOUND-020 — Long and translated content
- **Requirement:** Long names, addresses, prices and translated content never break layouts.
- **Acceptance:** Names use `maxLines` with ellipsis; prices and amounts are never truncated (laid out at intrinsic width, the name takes the remaining width); addresses wrap up to 3 lines; buttons and chips grow in height instead of truncating labels; `PreviewData` provides extra-long names, descriptions, prices, addresses and translated-length labels used in component previews; layouts are verified at font scale 1.0, 1.5 and 2.0 and with the `en-XA` pseudo-locale (`pseudoLocalesEnabled` in debug builds).
- **Ticket:** FOUND-020 · **Design:** spec §7.4
