# Concept Note — Noshitech Restaurant

Phase 1 (short form). Full project context: [PROJECT-CONTEXT.md](../00-project-context/PROJECT-CONTEXT.md).

## Concept

Noshitech Restaurant is an Android app (application id `com.noshitechinc.restaurant`) currently in a **foundations-only** phase. The foundation provides build environments, MVVM architecture, networking/auth/error handling, logging, adaptive tablet layout, design tokens, shared UI components and shared screen states. The app launches to a blank home screen; components are verified through `@Preview`s and tests.

Confirmed product constraints for this phase: English only, light mode only, tablet only, US market format defaults (USD, +1 phone, US address fields).

**Business domain, personas, workflows and feature modules are not defined yet** and must not be invented. They will be specified later with their own FR IDs.

## Out of scope for the foundation

- All business features and flows (to be specified later).
- Real backend integration (auth scheme, endpoints and base URLs: PDR-001, PDR-003).
- Final brand visuals (placeholder tokens until PDR-002).
- Dark mode, other languages, multi-module Gradle structure, CI (team-managed).
