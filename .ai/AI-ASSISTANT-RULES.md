# AI Assistant Rules — Noshitech Restaurant

Project-specific rules for every AI session. They add to the process rules in [`AGENTS.md`](../AGENTS.md). When a rule here conflicts with a general habit of the tool, this file wins.

## ALWAYS

- Load the Tier-1 files first: `AGENTS.md`, `PROJECT-INDEX.md`, `.ai/context/project-overview.md`, `.ai/AI-ASSISTANT-RULES.md`.
- Follow the MVVM contract: split every screen into a stateful `XxxRoute` and a stateless `XxxScreen`; expose an immutable `XxxUiState` with a `LoadState` for each independently loaded section; send one-off events as effects through `BaseViewModel`.
- Use design tokens through `AppTheme.*` (`colors`, `typography`, `spacing`, `radius`, `border`, `sizes`).
- Put every user-facing string in `res/values/strings.xml`.
- Add `@Preview`s for every variant and state of every component and screen, covering tablet landscape, tablet portrait and font scale 2.0.
- Wrap network calls in `safeApiCall` and return `ApiResult` from repositories.
- Use `launchSubmit` for every mutation, so duplicate taps are ignored while a request runs.
- Register every endpoint in `docs/03-context/API-REGISTRY.md` with an `api:{domain}:{slug}` ID.
- Update the affected docs in the same change (see the doc-sync table in `AGENTS.md`).
- Ask the human when a requirement is ambiguous instead of guessing.
- Do not invent business operations, personas or feature workflows. Business context will be shared later; foundation work only.

## NEVER

- Read or print secrets: `local.properties`, `google-services.json`, keystores (`*.jks`, `*.keystore`), `.env` files.
- Hardcode colors, dp, sp or user-facing strings outside the theme token files and resources.
- Put `Context` or Compose types in ViewModels.
- Call Retrofit services outside repositories.
- Use `runBlocking` on the main thread.
- Log tokens or personal data.
- Use `--no-verify`, force push or `git reset --hard`.
- Rename or reuse a published ID.
- Invent API contracts. If the backend contract is unknown, record a PDR in `docs/03-context/PENDING-DECISIONS.md` instead.

## Impact analysis

The playbook rule: *"Schema / API / shared-interface changes get a blast-radius analysis + approved plan before any edit."*

### Triggers in this project

An impact analysis is required before changing any of:

- API contracts or DTOs.
- `ApiResult`, `AppError`, `UiText`, `LoadState`, `UiEffect` or `BaseViewModel`.
- Design tokens.
- Public parameters of shared components in `core/designsystem` or `core/ui`.
- Gradle flavors, `config/env/*.properties` or the version catalog.
- The Android manifest.

### Required output

Create `docs/06-development/impact-analyses/IA-YYYY-MM-DD-<topic>.md` from `templates/IMPACT-ANALYSIS-template.md`. It must list:

1. The consumers found by search, with the search commands used.
2. The risk level and the reason for it.
3. The execution order `API → clients → tests → docs`.
4. The rollback steps.

Wait for human approval of the analysis before editing any file it covers.
