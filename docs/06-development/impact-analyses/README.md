# Impact analyses

An impact analysis is written and approved by a human before any change to a trigger listed in [AI-ASSISTANT-RULES.md](../../../.ai/AI-ASSISTANT-RULES.md#impact-analysis): API contracts or DTOs; `ApiResult`, `AppError`, `UiText`, `LoadState`, `UiEffect` or `BaseViewModel`; design tokens; public parameters of shared components; Gradle flavors, `config/env/*.properties` or the version catalog; the Android manifest.

## Naming

`IA-YYYY-MM-DD-<topic>.md`, stored in this folder.

- `YYYY-MM-DD` is the date the analysis is written.
- `<topic>` is a short kebab-case description, for example `IA-2026-10-02-apperror-add-conflict.md`.
- If two analyses share a date and topic, add a suffix: `-2`, `-3`.
- Files are never renamed or deleted; a rejected analysis stays with its approval section recording the rejection.

## How to write one

1. Copy [templates/IMPACT-ANALYSIS-template.md](../../../templates/IMPACT-ANALYSIS-template.md) into this folder with the name above (the `impact-analysis` skill in the code repo does this).
2. Fill in every section: change summary, trigger, consumers found with the search commands used, blast radius, risk, the ordered plan `API → clients → tests → docs`, and rollback.
3. Stop and ask a human to review. Edits covered by the analysis start only after the approval section is filled in by that human.
