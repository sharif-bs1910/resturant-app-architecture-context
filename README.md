# resturant-app-architecture — Noshitech Restaurant context repo

This repo is the AI-DLC context repo for **Noshitech Restaurant** (`com.noshitechinc.restaurant`), currently foundations-only. It holds project context, specification, architecture decisions, open decisions, the API registry, the sprint board and the test strategy. Business domain details will be added later — do not invent them. The Android code lives in the sibling repo `../resturant-app`.

The process follows the [AI-DLC playbook](https://mirrayan.github.io/AI-DLC-playbook/).

## How to start an AI session

1. Open the workspace:
   - **Cursor:** open `noshitech-restaurant.code-workspace`. It loads the code repo and this context repo side by side.
   - **Claude Code:** run it from `../resturant-app`.
2. The session-start hook in the code repo injects the Tier-1 file list automatically. You do not need to paste it.
3. The AI reads the four Tier-1 files, summarizes the phase, task and constraints, and waits for you to confirm.
4. Confirm or correct the summary, then give the task. Use one task per chat.

The Tier-1 files are:

- [`AGENTS.md`](AGENTS.md) — plan-before-act and doc-sync rules
- [`PROJECT-INDEX.md`](PROJECT-INDEX.md) — phase, status, decisions and links
- [`.ai/context/project-overview.md`](.ai/context/project-overview.md) — condensed product and tech context
- [`.ai/AI-ASSISTANT-RULES.md`](.ai/AI-ASSISTANT-RULES.md) — ALWAYS/NEVER rules and impact-analysis triggers

## Folder map

```
resturant-app-architecture/
├── README.md                         # what this repo is, how to start a session
├── AGENTS.md                         # Tier-1: plan-before-act + doc-sync rules (tool-neutral)
├── PROJECT-INDEX.md                  # Tier-1: phase, status, decisions, open PDRs, links
├── noshitech-restaurant.code-workspace  # multi-root workspace: code + context repos
├── .ai/
│   ├── AI-ASSISTANT-RULES.md         # Tier-1: project ALWAYS/NEVER rules + impact-analysis snippet
│   └── context/
│       └── project-overview.md       # Tier-1: condensed product + tech context
├── docs/
│   ├── 00-project-context/PROJECT-CONTEXT.md
│   ├── 01-concept/CONCEPT-NOTE.md               # short: restaurant tablet POS
│   ├── 02-specification/SPECIFICATION.md        # FR-FOUND-001..020
│   ├── 03-context/
│   │   ├── BUSINESS-TECH-CONTEXT.md
│   │   ├── PENDING-DECISIONS.md                 # PDR-001..005
│   │   ├── API-REGISTRY.md                      # api:{domain}:{slug}
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
│       ├── specs/                               # approved design specs
│       └── plans/                               # implementation plans
└── templates/
    ├── IMPACT-ANALYSIS-template.md
    └── ADR-template.md
```

Phase 4 (context directories) is skipped; the playbook marks it optional for small projects.

## ID schemes

IDs are permanent: never renamed, renumbered or reused once published.

| Scheme | Used for |
|---|---|
| `FR-FOUND-NNN` | Functional requirements |
| `FOUND-NNN` | Tickets |
| `FOUND-QA-NNN` | Test cases |
| `api:{domain}:{slug}` | API endpoints |
| `ADR-NNN` | Architecture decision records |
| `PDR-NNN` | Pending decision records |

## Related

- Code repo: `../resturant-app`
- Playbook: [https://mirrayan.github.io/AI-DLC-playbook/](https://mirrayan.github.io/AI-DLC-playbook/)
- Current status: [PROJECT-INDEX.md](PROJECT-INDEX.md)
