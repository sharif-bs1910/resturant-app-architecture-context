# Pending Decisions (PDRs)

Open questions that block or shape future work. Each has a safe default the code uses until a decision is made. When a PDR is decided, record the outcome here, write an ADR if it changes architecture, and update [PROJECT-INDEX.md](../../PROJECT-INDEX.md). PDR IDs are permanent and never reused.

Owners are roles, not people (see [PROJECT-CONTEXT.md](../00-project-context/PROJECT-CONTEXT.md#stakeholders)).

| ID | Question | Default until decided | Owner | Needed by |
|---|---|---|---|---|
| PDR-001 | Backend auth scheme: token format, refresh endpoint and payload, whether devices are paired to a restaurant | Bearer access token + refresh token through the pluggable `AuthProvider`; placeholder endpoint `api:auth:refresh` (`POST auth/refresh`) | Backend lead + Architect | Before the first authenticated feature (login) |
| PDR-002 | Brand tokens still missing from Noshi Brand Library v1.0: status colours (success, warning, info, destructive), spacing steps 20/28/40/56/64/80, pill button shape, and the library’s 44px touch target | Mapped colours, Fraunces/Inter/JetBrains Mono, and radius MD/LG/XL applied per IA-2026-10-01-brand-tokens. Status colours stay on the previous palette. Touch target stays 48dp. Buttons stay on `radius.md`. | Designer + Product owner | Before status colours or pill buttons are required |
| PDR-003 | API base URLs per environment | `https://api.dev.example.invalid/` style placeholders in `config/env/*.properties` | Backend lead | Before the first real API integration |
| PDR-004 | Firebase projects per environment (dev, staging, prod) | Google Services and Crashlytics plugins skipped when `app/src/<flavor>/google-services.json` is absent; `NoOpCrashReporter` used | Dev lead + Product owner | Before the first staging build handed to testers |
| PDR-005 | detekt stability on Kotlin 2.2.10 | detekt `dev.detekt` 2.0.0-alpha.3 (pre-release); if it fails to run, remove the plugin and keep ktlint + Android lint only until the Kotlin upgrade | Architect + Dev lead | End of Plan 2 (static-analysis verification) |

## Outcomes

| ID | Decided | Decision | ADR |
|---|---|---|---|
| PDR-005 | 2026-09-24 | detekt deferred until Kotlin ≥ 2.3. `:app:detekt` hung indefinitely (>12 min, no progress) on Kotlin 2.2.10 with `dev.detekt` 2.0.0-alpha.3. Plugin removed from `build.gradle.kts` / `app/build.gradle.kts`; catalog entry kept. Active static analysis: ktlint + Android lint. | — |
