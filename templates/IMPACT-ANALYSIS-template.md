# IA-YYYY-MM-DD-<topic>

<!--
Copy to docs/06-development/impact-analyses/IA-YYYY-MM-DD-<topic>.md.
Required before changing any trigger listed in .ai/AI-ASSISTANT-RULES.md#impact-analysis.
No file covered by this analysis is edited until a human fills in the Approval section.
-->

## Change summary

<!-- What changes and why, with the ticket or FR ID (for example FOUND-004 / FR-FOUND-004). -->

## Trigger (which rule)

<!-- The impact-analysis trigger that applies, for example "Public parameters of shared components in core/designsystem". -->

## Consumers found (search commands + results)

<!-- Every search run and what it found. Example:

    rg -n "AppButton\(" app/src
    → 14 matches in 9 files (list them)
-->

| Search command | Files / matches |
|---|---|
| | |

## Blast radius

<!-- Files, screens, tests, docs and endpoints affected, directly and indirectly. -->

## Risk (Low/Medium/High + why)

<!-- One level and the reason, for example "Medium — 9 call sites, all covered by previews but only 2 by tests". -->

## Plan (ordered `API → clients → tests → docs`)

1. API — <!-- contract, DTO or shared interface change -->
2. Clients — <!-- call sites, repositories, ViewModels, screens -->
3. Tests — <!-- tests to add or update, and the command that proves them -->
4. Docs — <!-- API-REGISTRY.md, ADRs, SPECIFICATION.md, FOUND.md, sprint board, PROJECT-INDEX.md -->

## Rollback

<!-- How to undo the change safely, including data or configuration that must be restored. -->

## Approval (name/date)

<!-- Filled in by the human approver, never by the AI. -->

| Approver | Date | Decision |
|---|---|---|
| | | |
