# Sprint 0 — Foundation

**Goal:** deliver the Android foundation (`FR-FOUND-001`…`FR-FOUND-020`) so business modules can start on a stable base.

**Plans:**

- Plan 2 — [Android core foundation](../../superpowers/plans/2026-09-24-02-android-core-foundation.md) (Tasks 1–8; Task 8 runs static analysis, full verification and doc sync for Plan 2 tickets).
- Plan 3 — [Design system and states](../../superpowers/plans/2026-09-24-03-design-system-and-states.md) (Tasks 1–11; Task 11 runs the definition-of-done gate and final doc sync).

**Statuses:** `To do` → `In progress` → `Done`. Update the status in the same change that moves the work (doc-sync rule in [AGENTS.md](../../../AGENTS.md)).

## Board

| Ticket | Title | FR | Status | Plan/Task |
|---|---|---|---|---|
| FOUND-001 | Android project and environment configuration | FR-FOUND-001 | Done | Plan 2 Task 1 |
| FOUND-002 | Development, staging and production builds | FR-FOUND-002 | Done | Plan 2 Task 1 |
| FOUND-003 | Landscape tablet layout and screen-size rules | FR-FOUND-003 | Done | Plan 2 Task 6; Plan 3 Tasks 3, 9 |
| FOUND-004 | Networking, API authentication, common API error handling | FR-FOUND-004 | Done | Plan 2 Tasks 4–5 |
| FOUND-005 | Application logging and crash reporting | FR-FOUND-005 | Done | Plan 2 Task 3 |
| FOUND-006 | Colour, typography, spacing, radius and border tokens | FR-FOUND-006 | Done | Plan 3 Task 1 |
| FOUND-007 | Primary, secondary, outline and destructive buttons | FR-FOUND-007 | Done | Plan 3 Task 2 |
| FOUND-008 | Text, search, numeric, currency, phone, address and time inputs | FR-FOUND-008 | Done | Plan 3 Task 3 |
| FOUND-009 | Switches, segmented controls, filter chips, status badges | FR-FOUND-009 | Done | Plan 3 Task 4 |
| FOUND-010 | Quantity steppers and numeric keypads | FR-FOUND-010 | Done | Plan 3 Task 5 |
| FOUND-011 | Menu item, order line, order and kitchen status cards | FR-FOUND-011 | Done | Plan 3 Task 6 |
| FOUND-012 | Shared modal, confirmation and success dialogs | FR-FOUND-012 | Done | Plan 3 Task 7 |
| FOUND-013 | Common list rows and settings rows | FR-FOUND-013 | Done | Plan 3 Task 7 |
| FOUND-014 | Disabled, pressed, focused, loading and error variants | FR-FOUND-014 | Done | Plan 3 Tasks 2–7 |
| FOUND-015 | Common loading and progress states | FR-FOUND-015 | Done | Plan 3 Task 8 |
| FOUND-016 | Empty-list and no-search-result states | FR-FOUND-016 | Done | Plan 3 Task 8 |
| FOUND-017 | API error and retry states | FR-FOUND-017 | Done | Plan 3 Task 8; Plan 2 Task 4 |
| FOUND-018 | Service-unavailable and blocking offline states | FR-FOUND-018 | Done | Plan 3 Task 8; Plan 2 Task 6 |
| FOUND-019 | Prevent duplicate submissions while requests run | FR-FOUND-019 | Done | Plan 2 Task 7; Plan 3 Tasks 2, 10 |
| FOUND-020 | Long names, addresses, prices, translated content without layout breakage | FR-FOUND-020 | Done | Plan 3 Tasks 2–8; Plan 2 Task 1 (pseudo-locale) |

## Notes

- Code paths and tests per ticket: [modules/FOUND.md](../modules/FOUND.md).
- Compose UI tests (Plan 3 Task 10) need a device or emulator; device-run status is recorded in [TEST-CONTEXT.md](../../06-development/TEST-CONTEXT.md).
