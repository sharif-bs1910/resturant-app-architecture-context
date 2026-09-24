# Test Context — Noshitech Restaurant (Android)

Android test strategy for the code repo `../resturant-app`. This replaces the playbook's Playwright guidance: the app is native Android, so tests are JVM unit tests, ViewModel tests and Compose UI tests, plus the bash test suite for the AI hooks. It also holds the hook verification log.

## Test levels

| Level | Location | Coverage |
|---|---|---|
| Unit | `app/src/test` | `ErrorMapper` (each status and exception → `AppError`, message sanitizing); `safeApiCall` rethrows cancellation; `TokenAuthenticator` (single refresh for parallel 401s via MockWebServer, session end on failure, at most one retry); currency and phone formatters and US phone/address validators; `BaseViewModel.launchSubmit` (ignores re-entry, releases the key on success, failure and cancellation) |
| ViewModel harness | `app/src/test` | `MainDispatcherRule` in `testing/`, fakes in `fakes/` (`FakeTokenStore`, `FakeAuthProvider`, `FakeTokenCipher`, `FakeCrashReporter`, `FakeNetworkMonitor`); `HomeViewModelTest` is the template used by the `scaffold-screen` skill |
| Compose UI | `app/src/androidTest` | `QuantityStepper` bounds, `NumericKeypad` modes, `AppButton` loading blocks a second tap, `OfflineBlockingState` show and dismiss |
| Hooks | `scripts/ai-hooks/tests/run-tests.sh` | Secrets and dangerous-command guard, session-start context, design lint, edit tracking and doc-sync reminder, for both Cursor and Claude Code payloads |

**Conventions:** fakes over mocks for repositories and stores; Turbine for flows; `kotlinx-coroutines-test` with `MainDispatcherRule`; MockWebServer for HTTP behaviour; test tags come from the component (`QuantityStepperTags`, `NumericKeypadTags`, `StateTags`) rather than string literals in tests.

## Commands

Run from `../resturant-app`. Agents prefix Gradle commands with `ANDROID_HOME=$HOME/Android/Sdk`.

| Purpose | Command |
|---|---|
| Unit and ViewModel tests | `./gradlew testDevDebugUnitTest` |
| Compose UI tests (device or emulator required) | `./gradlew connectedDevDebugAndroidTest` |
| Hook test suite | `scripts/ai-hooks/tests/run-tests.sh` |
| Static analysis | `./gradlew ktlintCheck` (detekt deferred — PDR-005) |
| Design lint | `scripts/ai-hooks/design-lint-check.sh app/src/main` |

## Test cases (FOUND-QA)

IDs are permanent. Unit tests are traced per requirement in [modules/FOUND.md](../05-breakdown/modules/FOUND.md); the cases below are the UI-level and hook checks.

| QA ID | Test | Verifies | FR |
|---|---|---|---|
| FOUND-QA-001 | `QuantityStepperTest.stepperRespectsMinAndMax` | Decrement disabled at min, increment disabled at max, value updates between bounds | FR-FOUND-010 |
| FOUND-QA-002 | `NumericKeypadTest.integerTypingAndBackspace` | Integer mode typing and backspace | FR-FOUND-010 |
| FOUND-QA-003 | `NumericKeypadTest.decimalAllowsSingleSeparator` | Decimal mode accepts one separator only | FR-FOUND-010 |
| FOUND-QA-004 | `NumericKeypadTest.currencyDoubleZero` | Currency mode double-zero key | FR-FOUND-010 |
| FOUND-QA-005 | `AppButtonTest.loadingButtonIgnoresTaps` | A loading button ignores taps and accepts them again after loading ends | FR-FOUND-007, FR-FOUND-019 |
| FOUND-QA-006 | `AppButtonTest.disabledButtonIgnoresTaps` | A disabled button ignores taps | FR-FOUND-007, FR-FOUND-014 |
| FOUND-QA-007 | `OfflineBlockingTest.blockingStateFollowsConnectivity` | `AppScaffold(requiresNetwork = true)` shows the offline overlay while offline and removes it when online | FR-FOUND-018 |
| FOUND-QA-008 | `run-tests.sh` guard-secrets cases | Secret file reads (`local.properties`, `google-services.json`) and dangerous commands (force push, `--no-verify`, `rm -rf` outside `build/`) are denied; safe commands and `local.properties.example` are allowed (Cursor and Claude payloads) | Spec §2.2 hooks |
| FOUND-QA-009 | `run-tests.sh` session-start cases | Session start injects the Tier-1 file list for Cursor and Claude; the Claude config is skipped when running inside Cursor | Spec §2.2 hooks |
| FOUND-QA-010 | `run-tests.sh` design-lint and doc-sync cases | Design lint flags hardcoded colours, raw dp/sp, string literals and missing previews and passes a clean file; edits are recorded per session; the stop hook reminds once about doc sync and stays silent when docs were edited | Spec §2.2 hooks, spec §11 item 4 |

## Device-run status

Compose UI tests are compiled with `./gradlew assembleDevDebugAndroidTest` and run with `./gradlew connectedDevDebugAndroidTest` on a connected device or emulator. The result of each run is recorded here with its date.

| Date | Device / AVD | Command | Result |
|---|---|---|---|
| 2026-09-24 | Medium_Tablet (AVD, API 15 label / Android 15) | `./gradlew connectedDevDebugAndroidTest` | Pass — 7/7 (`QuantityStepperTest`, `NumericKeypadTest` ×3, `AppButtonTest` ×2, `OfflineBlockingTest`) |
## Hook verification log

Live checks of each hook in Cursor and Claude Code (spec §11 item 6). One row per check.

| Date | Tool | Hook | Action | Result |
|---|---|---|---|---|
| 2026-09-24 | bash | All hook scripts | `scripts/ai-hooks/tests/run-tests.sh` | Pass (32/32) |
| 2026-09-24 | Cursor | guard-secrets (`preToolUse` Write) | Agent tried to write `local.properties` | Pass — blocked with "local.properties is a secret file" |
| 2026-09-24 | Cursor | guard-secrets (`beforeShellExecution`) | Agent ran `git push --force origin main` | Pass — blocked with "force push" |
| 2026-09-24 | Cursor | design-lint (`postToolUse` Write) | Agent wrote a probe composable with a hex colour, `16.dp`, a string literal and no preview | Pass — all four issues fed back to the agent; probe deleted |
| 2026-09-24 | Cursor | format-kotlin edit tracking (`afterFileEdit`) | Same probe write | Pass — path recorded in `.ai/.session/<conversation>.log` |
| 2026-09-24 | Cursor | session-start (`sessionStart`) | Needs a new chat in `resturant-app`: ask "what context were you given?" | Pending user check |
| 2026-09-24 | Cursor | guard-secrets (`beforeReadFile`) | Needs an existing secret file (create `local.properties` manually, then ask the agent to read it) | Pending user check |
| 2026-09-24 | Claude Code | All hooks | Claude Code session in `resturant-app` | Not run |
