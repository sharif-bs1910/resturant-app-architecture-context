# Module FOUND — Android foundation

## Purpose

FOUND is the foundation module of Noshitech Restaurant. It delivers build environments, the MVVM contract, networking with auth and error handling, logging and crash reporting, adaptive tablet layout, design tokens, shared components and shared screen states. It contains no business features; the app launches to a blank home screen and components are verified through `@Preview`s and tests. Business domain and feature modules will be specified later.

- Requirements: [SPECIFICATION.md](../../02-specification/SPECIFICATION.md) (`FR-FOUND-001`…`FR-FOUND-020`)
- Tickets and status: [sprint-0.md](../sprints/sprint-0.md) (`FOUND-001`…`FOUND-020`)
- Test cases: [TEST-CONTEXT.md](../../06-development/TEST-CONTEXT.md) (`FOUND-QA-NNN`)
- Decisions: [ADR-001…ADR-006](../../03-context/adr/)

## Traceability

Paths are relative to the code repo `../resturant-app`:

- `SRC/` = `app/src/main/java/com/noshitechinc/restaurant/`
- `TEST/` = `app/src/test/java/com/noshitechinc/restaurant/`
- `ATEST/` = `app/src/androidTest/java/com/noshitechinc/restaurant/`

Code paths and test names come from Plan 2 (Android core foundation) and Plan 3 (design system and states). They are confirmed or corrected in the doc-sync step at the end of each plan.

| FR ID | Ticket | Main code paths | Tests |
|---|---|---|---|
| FR-FOUND-001 | FOUND-001 | `gradle/libs.versions.toml`, `settings.gradle.kts`, `build.gradle.kts`, `app/build.gradle.kts`, `app/src/main/AndroidManifest.xml`, `SRC/app/RestaurantApplication.kt`, `SRC/app/MainActivity.kt`, `SRC/di/AppModule.kt`, `SRC/di/CoroutinesModule.kt` | Build: `./gradlew assembleDevDebug`; `./gradlew ktlintCheck` (detekt deferred — PDR-005) |
| FR-FOUND-002 | FOUND-002 | `config/env/{dev,staging,prod}.properties`, `local.properties.example`, `app/build.gradle.kts` (flavors, config loader, signing, conditional Firebase plugins), `app/proguard-rules.pro`, `.gitignore` | Build: `./gradlew assembleDevDebug assembleStagingDebug assembleProdRelease` without `google-services.json` |
| FR-FOUND-003 | FOUND-003 | `SRC/core/adaptive/OrientationPolicy.kt`, `SRC/core/adaptive/AdaptiveInfo.kt`, `SRC/app/MainActivity.kt`, `app/src/main/AndroidManifest.xml` (resizability property), `SRC/core/designsystem/component/input/AddressInput.kt`, `SRC/feature/home/`, `SRC/navigation/` | `AdaptiveInfoTest`, `HomeViewModelTest`; `@ScreenPreviews` (tablet landscape, tablet portrait) |
| FR-FOUND-004 | FOUND-004 | `SRC/core/common/ApiResult.kt`, `SRC/core/common/AppError.kt`, `SRC/core/network/SafeApiCall.kt`, `SRC/core/network/error/` (`ErrorBodyParser`, `MessageSanitizer`, `ErrorMapper`), `SRC/core/network/interceptor/` (`HeaderInterceptor`, `AuthInterceptor`), `SRC/core/network/TokenAuthenticator.kt`, `SRC/core/auth/` (`AuthProvider`, `TokenStore`, `KeystoreTokenStore`, `KeystoreTokenCipher`, `SessionManager`), `SRC/data/remote/api/AuthApi.kt`, `SRC/data/auth/RefreshTokenAuthProvider.kt`, `SRC/di/NetworkModule.kt` | `ApiResultTest`, `ErrorMapperTest`, `MessageSanitizerTest`, `SafeApiCallTest`, `TokenAuthenticatorTest`, `InterceptorsTest`, `KeystoreTokenStoreTest` |
| FR-FOUND-005 | FOUND-005 | `SRC/core/logging/` (`CrashReporter`, `CrashlyticsCrashReporter`, `CrashReportingTree`, `AppLogging`), `SRC/app/AppStartup.kt`, `SRC/di/LoggingModule.kt` | `CrashReportingTreeTest` (with `FakeCrashReporter`) |
| FR-FOUND-006 | FOUND-006 | `SRC/core/designsystem/theme/` (`AppColors`, `AppTypography`, `AppDimens`, `StatusTone`, `AppTheme`), `SRC/core/designsystem/interaction/InteractionVisuals.kt`, `SRC/core/designsystem/preview/` | `StatusToneTest`; design lint over `app/src/main` |
| FR-FOUND-007 | FOUND-007 | `SRC/core/designsystem/component/button/` (`AppButton`, `AppIconButton`) | `AppButtonTest` (FOUND-QA-005, FOUND-QA-006); previews |
| FR-FOUND-008 | FOUND-008 | `SRC/core/designsystem/component/input/` (`AppTextField`, `SearchField`, `NumericField`, `CurrencyField`, `PhoneField`, `AddressInput`, `TimeField`, `InputTransformations`), `SRC/core/common/model/TimeOfDay.kt`, `SRC/core/common/format/`, `SRC/core/common/validation/` | `InputTransformationsTest`, `CurrencyFormatterTest`, `UsPhoneFormatterTest`, `ValidatorsTest`; previews |
| FR-FOUND-009 | FOUND-009 | `SRC/core/designsystem/component/selection/` (`AppSwitch`, `SegmentedControl`, `FilterChipGroup`, `StatusBadge`) | Previews; `StatusToneTest` (tone colours) |
| FR-FOUND-010 | FOUND-010 | `SRC/core/designsystem/component/quantity/` (`QuantityStepper`, `NumericKeypad`, `KeypadReducer`) | `KeypadReducerTest`, `QuantityStepperTest` (FOUND-QA-001), `NumericKeypadTest` (FOUND-QA-002…004) |
| FR-FOUND-011 | FOUND-011 | `SRC/core/designsystem/component/card/` (`AppCard`, `MenuItemCard`, `OrderLineCard`, `OrderCard`, `KitchenTicketCard`, `ElapsedTone`) | `ElapsedToneTest`; previews |
| FR-FOUND-012 | FOUND-012 | `SRC/core/designsystem/component/dialog/` (`AppModal`, `ConfirmationDialog`, `SuccessDialog`) | Previews of the `*Layout` composables |
| FR-FOUND-013 | FOUND-013 | `SRC/core/designsystem/component/row/` (`ListRow`, `SettingsRow`) | Previews |
| FR-FOUND-014 | FOUND-014 | `SRC/core/designsystem/interaction/InteractionVisuals.kt` (`ForcedInteraction`, `rememberInteractionVisuals`, `focusRing`), all `SRC/core/designsystem/component/` groups | `AppButtonTest` (FOUND-QA-005, FOUND-QA-006); preview coverage check (Plan 3 Task 11) |
| FR-FOUND-015 | FOUND-015 | `SRC/core/designsystem/state/` (`StatusMessage`, `LoadingState`, `SkeletonList`), `SRC/core/ui/LoadState.kt`, `SRC/core/ui/state/LoadStateContent.kt` | `LoadStateTest`; previews |
| FR-FOUND-016 | FOUND-016 | `SRC/core/designsystem/state/EmptyState.kt` (`EmptyState`, `NoSearchResultsState`), `SRC/core/ui/state/LoadStateContent.kt` | Previews |
| FR-FOUND-017 | FOUND-017 | `SRC/core/ui/state/ErrorState.kt`, `SRC/core/ui/state/LoadStateContent.kt`, `SRC/core/ui/error/AppErrorText.kt`, `SRC/core/network/error/ErrorMapper.kt`, `SRC/core/network/error/MessageSanitizer.kt` | `ErrorMapperTest`, `MessageSanitizerTest`, `BaseViewModelTest` (`presentError`); previews |
| FR-FOUND-018 | FOUND-018 | `SRC/core/ui/state/ErrorState.kt` (`ServiceUnavailableState`), `SRC/core/ui/state/OfflineBlockingState.kt`, `SRC/core/ui/AppScaffold.kt` (`LocalIsOnline`), `SRC/core/network/NetworkMonitor.kt` | `OfflineBlockingTest` (FOUND-QA-007), `FakeNetworkMonitor`; previews |
| FR-FOUND-019 | FOUND-019 | `SRC/core/ui/BaseViewModel.kt` (`launchSubmit`, `submittingKeys`, `isSubmitting`), `SRC/core/ui/UiEffect.kt`, `SRC/core/ui/ObserveEffects.kt`, `SRC/core/designsystem/component/button/AppButton.kt` (`loading`) | `BaseViewModelTest`, `AppButtonTest.loadingButtonIgnoresTaps` (FOUND-QA-005) |
| FR-FOUND-020 | FOUND-020 | `SRC/core/designsystem/preview/PreviewData.kt`, `SRC/core/designsystem/preview/PreviewAnnotations.kt` (`@FontScalePreviews`, `@ComponentPreviews`, `@ScreenPreviews`), all component files, `app/build.gradle.kts` (`isPseudoLocalesEnabled` in debug) | Previews at font scale 1.0 / 1.5 / 2.0 with long samples; `en-XA` pseudo-locale check on device |
