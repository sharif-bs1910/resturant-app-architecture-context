# ADR-002 — MVVM architecture: UiState + LoadState + Channel effects + launchSubmit

## Status

Accepted

## Date

2026-09-24

## Context

Every future feature needs the same screen contract so that AI sessions and humans produce consistent code. The contract must support screens with several independently loaded sections, one-off events (messages, dialogs, navigation after a result), protection against duplicate submissions (FR-FOUND-019), and ViewModels that are testable without Android (no `Context` or Compose types). Butterfly uses boolean loading/error flags per screen, which does not scale to multi-section screens.

## Decision

Approach A: **UiState + `LoadState` + Channel effects + `BaseViewModel.launchSubmit`** (spec §4.2 with §14 amendments).

- **Layering** (`com.noshitechinc.restaurant`): `feature` → `domain` ← `data`; `core/*` is usable by all; `domain` is pure Kotlin; `designsystem` never depends on `feature`, `data` or `domain`.
- **State:** `XxxUiState` is an immutable data class exposed as `StateFlow<XxxUiState>`. Each independently loaded section is a `LoadState<out T>`: `Idle`, `Loading`, `Content(data)`, `Empty`, `Error(error: AppError)`.
- **Text:** `UiText` is `Resource(@StringRes id, args)` or `Dynamic(value)` for sanitized server text. ViewModels never hold `Context` or Compose types.
- **Effects:** `BaseViewModel.effects: Flow<UiEffect>` backed by `Channel(Channel.BUFFERED)`. `UiEffect` is an open `interface` with base effects `ShowMessage(text, tone)` and `ShowErrorDialog(error)`, so features add their own effect types in their own packages.
- **Submissions:** `launchSubmit(key) { }` ignores the call while `key` is running, tracks running keys in `submittingKeys: StateFlow<Set<String>>`, releases the key in `finally` (success, failure, cancellation), and catches unexpected exceptions and presents them as `AppError.Unknown`. `isSubmitting(key): Boolean` drives button loading and disabled states.
- **Errors:** `presentError(error)` shows `NoInternet` and `Timeout` as a transient error message and other errors as an error dialog; session end is driven by `SessionManager`.
- **Screens:** `XxxRoute(viewModel = hiltViewModel(), onNavigate…)` collects state with `collectAsStateWithLifecycle()` and effects with a lifecycle-aware collector; `XxxScreen(state, onAction…)` is stateless and owns all previews. Navigation is triggered by Route callbacks; ViewModels emit navigation effects only when navigation depends on a result.
- **Data:** repository interfaces in `domain/repository`, `…RepositoryImpl` in `data/repository` bound with `@Binds`; DTOs in `data/remote/dto` mapped with `toDomain()`; repositories return `ApiResult<DomainModel>`; ViewModels translate results into `LoadState`. Use cases exist only for cross-repository or business logic.
- **Testing:** `MainDispatcherRule`, fakes in `test/.../fakes/`, Turbine for flows; `HomeViewModelTest` is the template used by the `scaffold-screen` skill.

## Consequences

- Multi-section screens get loading, empty and error handling per section, and `LoadStateContent` renders them uniformly.
- Effects are delivered once and are not replayed on configuration change; with a buffered channel, effects sent while the UI is stopped are delivered when it resumes.
- Duplicate taps on slow networks are ignored by construction, and keys cannot leak because release happens in `finally`.
- Changing `ApiResult`, `AppError`, `UiText`, `LoadState`, `UiEffect` or `BaseViewModel` affects every feature, so these are impact-analysis triggers.
- There is some boilerplate per screen (UiState, Route, Screen); the `scaffold-screen` skill generates it.

## Alternatives considered

- **B — Butterfly-style flags** (`isLoading`, `errorMessage` booleans/strings in one UiState): rejected; does not model several independently loaded sections, allows contradictory states, and has no built-in duplicate-submit protection.
- **C — MVI** (single intent stream, reducer, side-effect handlers): rejected for now; more ceremony per screen than the team needs, and the same guarantees are reached with `LoadState` + effects + `launchSubmit`. Can be revisited with a new ADR if screen logic grows complex.
- **`SharedFlow` for effects** — rejected: events emitted without a collector are lost, whereas a buffered `Channel` keeps them until the UI collects.
- **Sealed `UiEffect`** — rejected at plan time: sealed types cannot be extended from feature packages.
