# Project Context — Noshitech Restaurant

Phase 0 of the [AI-DLC playbook](https://mirrayan.github.io/AI-DLC-playbook/). Source of truth for design details: the [foundation design spec](../superpowers/specs/2026-09-24-android-foundation-design.md) (section 14 amendments override earlier sections).

## Problem

Before product features can be built consistently (including with AI assistance), the Android project needs a shared foundation: build environments, an agreed MVVM architecture, networking with authentication and error handling, logging and crash reporting, adaptive tablet layout, design tokens, shared components and shared screen states.

Business domain details are **not defined yet** and will be supplied later.

## Goals

1. Set up AI-driven development that follows the AI-DLC spine: a context repo with stable IDs, context-loaded AI sessions, impact analysis before risky changes, and docs updated in the same change as the code. Rules, skills and hooks are provided for Cursor and Claude Code.
2. Deliver the Android foundation as 20 tracked requirements (`FR-FOUND-001`…`FR-FOUND-020`, see [SPECIFICATION.md](../02-specification/SPECIFICATION.md)).

## Non-goals

- Business features and domain workflows (to be specified later).
- Dark mode and languages other than English (product decision for foundation; strings still live in resources so translation stays possible).
- A multi-module Gradle structure (single `:app` module with strict package layering instead).
- Git remotes and CI (managed by the team outside this setup).
- Final brand tokens (Figma values arrive later, see PDR-002).

## Users

**Not defined yet.** Device targets for the foundation are technical:

- Tablet-only layouts (landscape preferred; portrait and multi-window still required on Android 16).
- No business roles or personas until the business context is shared.

## Constraints

| Constraint | Detail |
|---|---|
| Device | Tablet only. `OrientationPolicy` always requests sensor landscape. Android 16 may ignore the lock on large screens, so tablet layouts must also work in portrait and multi-window. Narrow multi-window uses `WidthClass.Compact` (single pane). |
| Language | English only. All user-facing text lives in `res/values/strings.xml`. |
| Theme | Light mode only. |
| Market formats | USD currency (amounts held as cents in `Long`), +1 (US) phone numbers formatted `+1 (XXX) XXX-XXXX`, US address fields (street, unit, city, state, ZIP). |
| Platform | minSdk 25, targetSdk 36, compileSdk 36; single `:app` module; app ID `com.noshitechinc.restaurant`, display name "Noshitech Restaurant". |
| Backend | Not yet defined. Auth, base URLs and Firebase projects are open decisions (PDR-001, PDR-003, PDR-004); placeholders are used until they are decided. |
| Security | No secrets, tokens or personal credentials in either repo. Secrets come from `local.properties` or environment variables. |
| Business | Do not invent operations, personas or feature flows. Wait for shared business context. |

## Stakeholders

Roles are hats, not people: one person may wear several at once (for example architect + dev lead + Doc DRI).

| Role | Responsibility |
|---|---|
| Product owner | Owns scope, priorities and acceptance of the foundation requirements; decides open product questions. |
| Architect | Owns ADRs, the MVVM contract, dependency direction and approval of impact analyses. |
| Dev lead | Owns the code repo, reviews AI and human changes, keeps the sprint board current. |
| Doc DRI | Directly responsible for the context repo staying in sync with the code (doc-sync rule). |
| Designer | Supplies Figma brand tokens and component designs (PDR-002). |
| Backend lead | Supplies the auth scheme, API contracts and base URLs (PDR-001, PDR-003). |
| QA | Owns `FOUND-QA-NNN` test cases and the test strategy in [TEST-CONTEXT.md](../06-development/TEST-CONTEXT.md). |

## Success criteria

The foundation is done when all of the following hold (spec section 11):

1. `./gradlew assembleDevDebug assembleStagingDebug assembleProdRelease` succeeds without any `google-services.json`.
2. `./gradlew ktlintCheck testDevDebugUnitTest` passes (detekt deferred — PDR-005).
3. Every component and screen file has previews covering its variants (tablet landscape, tablet portrait, font scale 2.0).
4. No hardcoded colors, dp/sp values or user-facing strings outside token and resource files; `scripts/ai-hooks/design-lint-check.sh app/src/main` reports nothing.
5. `SPECIFICATION.md`, `modules/FOUND.md` and `sprints/sprint-0.md` trace all 20 FR IDs to tickets, code and tests; `PROJECT-INDEX.md` shows the foundation complete with the remaining PDRs open.
6. Each hook has been triggered at least once in Cursor (secrets guard blocks reading `local.properties`; format and design lint run on edit; session-start and stop fire), with results recorded in [TEST-CONTEXT.md](../06-development/TEST-CONTEXT.md).
