# AGENTS.md — Noshitech Restaurant

This is the AI-DLC context repo for Noshitech Restaurant, an Android app in a foundations-only phase (`com.noshitechinc.restaurant`). It holds the project's shared memory: phase docs, specification, decisions (ADRs), open decisions (PDRs), the API registry and the sprint board. Application code lives in the sibling code repo `../resturant-app`. Business domain details are not defined yet — do not invent them. These rules apply to every AI tool (Cursor, Claude Code) and every human working with one. The process follows the [AI-DLC playbook](https://mirrayan.github.io/AI-DLC-playbook/).

## Session start (every chat)

1. Read the four Tier-1 files, in this order:
   - `AGENTS.md` (this file)
   - `PROJECT-INDEX.md`
   - `.ai/context/project-overview.md`
   - `.ai/AI-ASSISTANT-RULES.md`
2. When the task involves code, also read `../resturant-app/AGENTS.md` for code-level conventions.
3. Summarize back to the human: the current phase, the task you were given (with its ticket ID), and the constraints that apply to it.
4. Wait for the human to confirm the summary before doing any work.
5. Work on one task per chat. Start a new chat for the next task.
6. If the human says the summary is wrong, stop, reload the Tier-1 files and summarize again. Do not continue on a wrong understanding.

## Plan before act

Every change follows this sequence:

1. **State intent** — say what you will change and why, naming the ticket or requirement ID.
2. **Impact analysis when risky** — if the change touches a trigger listed in [`.ai/AI-ASSISTANT-RULES.md#impact-analysis`](.ai/AI-ASSISTANT-RULES.md#impact-analysis), write the impact analysis first.
3. **Human approves the plan** — no edits before approval.
4. **Implement** — only what the approved plan covers.
5. **AI self-review** — check the change against the plan, the rules and the doc-sync table below.
6. **Human review** — the human accepts or requests changes.

The AI never approves its own plan. Approval always comes from a human.

## Doc sync (same change)

Docs are updated in the same change as the code or decision they describe, never in a later one.

| Change type | Doc to update |
|---|---|
| New or changed endpoint | `docs/03-context/API-REGISTRY.md` |
| Architecture or technology decision | New ADR in `docs/03-context/adr/` |
| Decision still open | `docs/03-context/PENDING-DECISIONS.md` |
| Ticket status | `docs/05-breakdown/sprints/sprint-0.md` |
| Phase or project status change | `PROJECT-INDEX.md` |
| New requirement | `docs/02-specification/SPECIFICATION.md` with a new FR ID |

## IDs

IDs are permanent. Never renumber or reuse an ID, even after the item it names is removed or superseded.

| Scheme | Used for | Example |
|---|---|---|
| `FR-FOUND-NNN` | Functional requirements (foundation module) | `FR-FOUND-007` |
| `FOUND-NNN` | Tickets | `FOUND-007` |
| `FOUND-QA-NNN` | Test cases | `FOUND-QA-001` |
| `api:{domain}:{slug}` | API endpoints | `api:auth:refresh` |
| `ADR-NNN` | Architecture decision records | `ADR-004` |
| `PDR-NNN` | Pending decision records | `PDR-001` |

## Where things go

| Artifact | Location |
|---|---|
| Design specs | `docs/superpowers/specs/` |
| Implementation plans | `docs/superpowers/plans/` |
| Impact analyses | `docs/06-development/impact-analyses/` |
