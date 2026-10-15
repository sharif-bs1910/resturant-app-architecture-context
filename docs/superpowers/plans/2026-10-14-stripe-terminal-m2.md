# Stripe Terminal (Reader M2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a reusable Stripe Terminal core, local stub, dev harness, and tests without wiring Checkout/Self-service, and without committing Stripe secrets.

**Architecture:** Hybrid `TerminalClient` (fake + Stripe SDK adapter); stub HTTP for connection tokens and PaymentIntents; harness feature for manual simulated-reader checks; unit tests on fakes/MockWebServer.

**Tech Stack:** Stripe Terminal Android SDK (~6.x) + optional ktx; Retrofit/OkHttp; Hilt; JUnit4/MockK/Turbine/MockWebServer; Node or Python stub.

## Global Constraints

- Package `com.noshitechinc.restaurant`; single `:app` module; MVVM Route/Screen split
- No secrets in git; `STRIPE_SECRET_KEY` only in stub env
- English strings in `strings.xml`; `AppTheme.*` tokens only
- Impact analysis `IA-2026-10-14-stripe-terminal` approved before Gradle/manifest/env edits
- Spec: `docs/superpowers/specs/2026-10-14-stripe-terminal-m2-design.md`
- Ticket/FR: FOUND-021 / FR-FOUND-021
- Never invent Checkout business flows; harness only

---

## File map

| Path | Responsibility |
|---|---|
| `gradle/libs.versions.toml`, `app/build.gradle.kts` | Stripe deps + Terminal BuildConfig fields |
| `config/env/{dev,staging,prod}.properties` | Terminal flags / URLs / location |
| `app/src/main/AndroidManifest.xml` | Location + Bluetooth (+ USB host feature optional) |
| `core/terminal/**` | Facade, models, fake, Stripe adapter |
| `data/remote/api/TerminalStubApi.kt`, `dto/terminal/**`, repositories | Stub HTTP |
| `di/TerminalModule.kt` | Hilt bindings; separate Retrofit for stub base URL |
| `feature/terminalharness/**` | Dev harness UI + VM |
| `navigation/Destinations.kt`, `AppNavHost` | Harness route (dev) |
| `feature/home/**` | Dev-only entry to harness |
| `app/RestaurantApplication.kt` | `TerminalApplicationDelegate` when enabled |
| `tools/stripe-terminal-stub/**` | Local stub + README + `.env.example` |
| `app/src/test/**` | Unit tests + JSON fixtures |
| Context-repo docs | FR, ADR, PDR, registry, sprint, IA (already drafted) |

---

## Task 1: Build config, manifest, stub skeleton

**Deliverable:** App builds with Terminal BuildConfig fields; stub script runnable with env key; no secret in repo.

- [ ] Add `stripeterminal` (+ `stripeterminal-ktx`) to version catalog and `app` dependencies
- [ ] Add env keys + BuildConfig fields for all flavors (staging/prod disabled)
- [ ] Manifest permissions for location + Bluetooth
- [ ] Create `tools/stripe-terminal-stub/` with `/connection_token` and `/payment_intents`, `.env.example`, README
- [ ] Verify: `ANDROID_HOME=$HOME/Android/Sdk ./gradlew assembleDevDebug`

## Task 2: Domain + data stub clients (TDD)

**Deliverable:** Token + PI repositories return `ApiResult`; MockWebServer tests green.

- [ ] Write failing tests for token/PI repository against MockWebServer fixtures
- [ ] Add DTOs, `TerminalStubApi`, repository impls, `safeApiCall`
- [ ] Register endpoints in `API-REGISTRY.md`
- [ ] Verify: `./gradlew testDevDebugUnitTest --tests '*Terminal*'`

## Task 3: `TerminalClient` facade + fake (TDD)

**Deliverable:** Fake drives discover/connect/pay/decline/cancel for ViewModel tests.

- [ ] Define `TerminalClient` + models
- [ ] Implement `FakeTerminalClient` with scripted outcomes
- [ ] Unit-test fake sequencing
- [ ] Verify unit tests green

## Task 4: Stripe adapter + Application init

**Deliverable:** Real SDK path initializes when `TERMINAL_ENABLED`; uses repository-backed `ConnectionTokenProvider`.

- [ ] `StripeTerminalClient` (discover simulated/physical Bluetooth, connect with locationId, process PI)
- [ ] Hilt: bind Stripe impl when enabled else Fake/NoOp
- [ ] `TerminalApplicationDelegate.onCreate` gated on enabled
- [ ] Map Stripe errors to domain failures; never log secrets

## Task 5: Harness feature + navigation

**Deliverable:** Dev harness screen with previews; entry from Home in `dev` only.

- [ ] UiState / ViewModel / Route / Screen + strings + previews
- [ ] Destination + AppNavHost; Home button when `BuildConfig.TERMINAL_ENABLED`
- [ ] Permission prompts for location (and Bluetooth on API 31+)
- [ ] ViewModel tests with `FakeTerminalClient`
- [ ] Design lint on touched UI paths

## Task 6: Doc sync + quality gate

**Deliverable:** Docs and quality checks pass.

- [ ] FR-FOUND-021, FOUND-021, ADR-007, PDR-006, PROJECT-INDEX, TEST-CONTEXT, FOUND.md, sprint-0
- [ ] `ktlintCheck` + `testDevDebugUnitTest`
- [ ] Manual note in README: run stub, set `STRIPE_SECRET_KEY`, use simulated reader

## Task 7: AI self-review

- [ ] Run `review-change` skill checklist; fix P0/P1

---

## Manual sandbox check (human)

1. Rotate leaked secret; set `STRIPE_SECRET_KEY` for stub  
2. Start stub on `:4242`  
3. Run `assembleDevDebug`, open harness  
4. Discover (simulated) → connect → pay $1.00 → confirm in Stripe Dashboard test Payments  
