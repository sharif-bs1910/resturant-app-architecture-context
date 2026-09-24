# PROJECT-INDEX — Noshitech Restaurant

Single entry point for project status, decisions and documents. Update this file whenever the phase, sprint status or a decision changes.

## Current state

- **Phase:** 6 — Development (Foundation)
- **Sprint:** sprint-0
- **Status:** Foundation complete
- **Last updated:** 2026-09-24 (tablet-only amendment: IA-2026-09-24-tablet-only)

## Plan progress

| Plan | Status | Notes |
|---|---|---|
| Plan 1 — AI-DLC setup | Done | Context repo, rules, skills and hooks live in Cursor and Claude Code config; 32/32 hook tests pass. Two live checks need a user action (see TEST-CONTEXT hook log) |
| Plan 2 — Android core foundation | Done | FOUND-001/002/004/005 Done; FOUND-003/019 In progress (UI in Plan 3); PDR-005 deferred detekt |
| Plan 3 — Design system and states | Done | FOUND-006…020 Done; Compose UI tests compiled (device run recorded in TEST-CONTEXT) |

## Phase status

| Phase | Name | Status | Document |
|---|---|---|---|
| 0 | Project context | Done | [PROJECT-CONTEXT.md](docs/00-project-context/PROJECT-CONTEXT.md) |
| 1 | Concept | Done (short) | [CONCEPT-NOTE.md](docs/01-concept/CONCEPT-NOTE.md) |
| 2 | Specification | Done | [SPECIFICATION.md](docs/02-specification/SPECIFICATION.md) |
| 3 | Business and tech context | Done | [BUSINESS-TECH-CONTEXT.md](docs/03-context/BUSINESS-TECH-CONTEXT.md) |
| 4 | Context directories | Skipped (optional) | Optional for small projects per the playbook |
| 5 | Breakdown | Done | [FOUND.md](docs/05-breakdown/modules/FOUND.md), [sprint-0.md](docs/05-breakdown/sprints/sprint-0.md) |
| 6 | Development | In progress | [TEST-CONTEXT.md](docs/06-development/TEST-CONTEXT.md) |

## Decisions

| ID | Title | Status |
|---|---|---|
| [ADR-001](docs/03-context/adr/ADR-001-platform-and-stack.md) | Platform and stack | Accepted |
| [ADR-002](docs/03-context/adr/ADR-002-mvvm-architecture.md) | MVVM architecture | Accepted |
| [ADR-003](docs/03-context/adr/ADR-003-build-flavors-and-config.md) | Build flavors and configuration | Accepted |
| [ADR-004](docs/03-context/adr/ADR-004-networking-and-auth.md) | Networking and auth | Accepted |
| [ADR-005](docs/03-context/adr/ADR-005-logging-and-crash-reporting.md) | Logging and crash reporting | Accepted |
| [ADR-006](docs/03-context/adr/ADR-006-design-system-and-adaptive-layout.md) | Design system and adaptive layout | Accepted |

## Open decisions

Details and owners in [PENDING-DECISIONS.md](docs/03-context/PENDING-DECISIONS.md).

| ID | Decision | Default until decided |
|---|---|---|
| PDR-001 | Backend auth scheme | Bearer + refresh via `AuthProvider` with a placeholder endpoint |
| PDR-002 | Figma brand tokens | Placeholder palette, system font |
| PDR-003 | API base URLs per environment | `https://api.dev.example.invalid/` style placeholders |
| PDR-004 | Firebase projects per environment | Firebase plugins skipped when `google-services.json` is absent |
| PDR-005 | detekt stability on Kotlin 2.2.10 | detekt 2.0.0-alpha.3; ktlint + Android lint only if it fails to run |

## Key documents

**Tier-1 (load every session)**

- [AGENTS.md](AGENTS.md) — plan-before-act and doc-sync rules
- [PROJECT-INDEX.md](PROJECT-INDEX.md) — this file
- [.ai/context/project-overview.md](.ai/context/project-overview.md) — condensed product and tech context
- [.ai/AI-ASSISTANT-RULES.md](.ai/AI-ASSISTANT-RULES.md) — ALWAYS/NEVER rules and impact-analysis triggers

**Phase docs and context**

- [README.md](README.md) — repo purpose and how to start a session
- [PROJECT-CONTEXT.md](docs/00-project-context/PROJECT-CONTEXT.md) — Phase 0
- [CONCEPT-NOTE.md](docs/01-concept/CONCEPT-NOTE.md) — Phase 1
- [SPECIFICATION.md](docs/02-specification/SPECIFICATION.md) — Phase 2, `FR-FOUND-001`…`FR-FOUND-020`
- [BUSINESS-TECH-CONTEXT.md](docs/03-context/BUSINESS-TECH-CONTEXT.md) — Phase 3
- [PENDING-DECISIONS.md](docs/03-context/PENDING-DECISIONS.md) — PDR-001…PDR-005
- [API-REGISTRY.md](docs/03-context/API-REGISTRY.md) — `api:{domain}:{slug}` endpoints
- [ADRs](docs/03-context/adr/) — ADR-001…ADR-006

**Breakdown and development**

- [FOUND.md](docs/05-breakdown/modules/FOUND.md) — module overview, FR → ticket → code → test map
- [sprint-0.md](docs/05-breakdown/sprints/sprint-0.md) — ticket board `FOUND-001`…`FOUND-020`
- [TEST-CONTEXT.md](docs/06-development/TEST-CONTEXT.md) — Android test strategy and hook verification log
- [Impact analyses](docs/06-development/impact-analyses/README.md) — how to file `IA-YYYY-MM-DD-<topic>.md`

**Templates and tools**

- [IMPACT-ANALYSIS-template.md](templates/IMPACT-ANALYSIS-template.md)
- [ADR-template.md](templates/ADR-template.md)
- `scripts/check-context.sh` — validates required files, placeholder markers, FR traceability and ADR/PDR references; run after editing this repo

**Design and plans**

- [Design spec](docs/superpowers/specs/2026-09-24-android-foundation-design.md) — approved foundation design
- [Plan 1 — AI-DLC setup](docs/superpowers/plans/2026-09-24-01-ai-dlc-setup.md)
- [Plan 2 — Android core foundation](docs/superpowers/plans/2026-09-24-02-android-core-foundation.md)
- [Plan 3 — Design system and states](docs/superpowers/plans/2026-09-24-03-design-system-and-states.md)

**Workspace**

- [noshitech-restaurant.code-workspace](noshitech-restaurant.code-workspace) — opens the code and context repos together

## Repos

| Repo | Path (relative to this repo) | Contents |
|---|---|---|
| Context | `.` | This repo: AI-DLC docs, decisions, registry, sprint board |
| Code | `../resturant-app` | Android app (`com.noshitechinc.restaurant`), AI tool entry points, rules, skills and hooks |
