# Stripe Terminal (Reader M2) — Design

**Status:** Approved in brainstorming (2026-10-14)  
**Ticket / FR:** FOUND-021 / FR-FOUND-021 (to be registered in SPECIFICATION + sprint board in the same change)  
**Repos:** `../resturant-app` (Android), stub under `tools/stripe-terminal-stub/`

## 1. Goals and scope

### Goal

Add a reusable Stripe Terminal layer for Stripe Reader M2 (Bluetooth/USB), proven without physical hardware, without wiring Checkout or Self-service yet.

### In scope

- `core/terminal` facade: interfaces, Stripe SDK adapter, fakes
- Local stub server for connection tokens and PaymentIntents (`STRIPE_SECRET_KEY` from env only)
- `dev` config: stub base URL, location ID, simulated-reader default
- Dev-only Terminal harness screen (discover → connect → test pay → disconnect)
- Automated tests: unit (fakes + MockWebServer) + instrumented harness tags where practical
- Doc sync: FR/ticket, API registry, ADR, PDR for production backend replacement

### Out of scope

- Checkout / Self-service payment wiring (follow-up)
- Physical M2 as a hard CI requirement (supported via same path; default = simulated)
- Committing secret or publishable keys
- Offline Terminal mode, on-receipt tipping, Stripe Connect multi-account

### Decisions locked

| Topic | Choice |
|---|---|
| Integration surface | Core module + harness first (not Checkout/Self-service) |
| SDK strategy | Hybrid: fakes for CI; real SDK when Terminal enabled + stub URL configured |
| Token source | In-repo local stub (option A) |
| Manual + automated exercise | Harness screen + tests (option C) |
| Location ID (non-secret) | `tml_GswQ1QXT3Sx1ZW` in `config/env/dev.properties` |

### Security

- Never put `sk_test_` / `sk_live_` in the Android app, committed JSON, or git
- Rotate any secret that was pasted into chat before using the stub
- Publishable key optional and gitignored if needed later
- Redact token secrets from HTTP logs

## 2. Architecture

Single `:app` module. Packages under `com.noshitechinc.restaurant`:

```
core/terminal/
  TerminalClient                 // facade
  TerminalConfig                 // enabled, locationId, stubBaseUrl, useSimulatedReader
  model/                         // ReaderInfo, PaymentRequest, PaymentOutcome, TerminalFailure
  fake/FakeTerminalClient
  stripe/StripeTerminalClient    // real SDK
  stripe/AppConnectionTokenProvider

data/remote/api/TerminalStubApi
data/remote/dto/terminal/…
data/repository/TerminalTokenRepositoryImpl, TerminalPaymentRepositoryImpl
domain/repository/TerminalTokenRepository, TerminalPaymentRepository

feature/terminalharness/         // Route, Screen, ViewModel, UiState
tools/stripe-terminal-stub/      // Node or Python stub + README + .env.example
```

**Dependency direction:** `feature/terminalharness` → `domain` + `core/terminal` + `core/ui`; `data` implements repositories; `core/terminal/stripe` wraps Stripe SDK; `designsystem` has no Stripe types.

### Config

| Key | Dev | Staging / Prod |
|---|---|---|
| `TERMINAL_ENABLED` | `true` | `false` |
| `TERMINAL_LOCATION_ID` | `tml_GswQ1QXT3Sx1ZW` | empty |
| `TERMINAL_STUB_BASE_URL` | `http://10.0.2.2:4242/` (emulator → host) | empty |
| `TERMINAL_USE_SIMULATED_READER` | `true` | `false` |

Exposed as `BuildConfig` fields. Secret only in stub process env: `STRIPE_SECRET_KEY`.

### Init

- When Terminal enabled: `TerminalApplicationDelegate.onCreate` from `RestaurantApplication`
- Lazy `Terminal.init` after location permission granted and token provider ready
- Staging/prod: Terminal client bound to no-op / fake; harness destination not registered

## 3. Data flow

```
Harness VM
  → ensure permissions
  → TerminalClient.discover(simulated)
  → TerminalClient.connect(reader, locationId)
  → TerminalPaymentRepository.createPaymentIntent(amountCents, currency)
  → TerminalClient.processPayment(clientSecret)
  → PaymentOutcome → UiState
```

Token path (SDK-owned lifecycle):

```
Stripe SDK → ConnectionTokenProvider
  → TerminalTokenRepository.fetchConnectionToken()
  → POST {TERMINAL_STUB_BASE_URL}connection_token → { secret }
```

### Stub API (Draft)

Separate Retrofit client on `TERMINAL_STUB_BASE_URL` (not main `API_BASE_URL`). Auth: none (`X-No-Auth`).

| ID | Method | Path | Request | Response |
|---|---|---|---|---|
| `api:terminal:connection-token` | POST | `connection_token` | `{}` | `{ "secret": string }` |
| `api:terminal:create-payment-intent` | POST | `payment_intents` | `{ "amountCents": long, "currency": string }` | `{ "id": string, "clientSecret": string }` |

Stub calls Stripe Test mode with `sk_test_` from env:

- `POST /v1/terminal/connection_tokens`
- `POST /v1/payment_intents` with `payment_method_types[]=card_present`

**PDR-006:** Production replaces stub with authenticated backend; `TerminalClient` stays stable.

### Errors

Map to harness UI + existing patterns:

- Stub unreachable / no network → transient message
- Token failure → dialog; block discover/connect
- Discover empty / connect failure → inline error
- Decline → declined state; reuse PaymentIntent guidance from Stripe docs
- Cancel → idle connected
- Missing location / Bluetooth → actionable message

Mutations use `launchSubmit` (`connect`, `pay`).

## 4. Harness UX

Dev-only screen (tablet-friendly, tokens + strings):

1. Status: Terminal enabled, connection status, connected reader serial
2. Actions: Discover, Connect (first/selected), Disconnect
3. Amount field default `$1.00` (100 cents); Pay; Cancel in-flight
4. Result: success / declined / error text
5. Simulated vs physical toggle bound to config default (simulated on in dev)

Entry: Home (dev only) secondary action → `TerminalHarnessDestination`. Not in customer checkout flow.

Previews: idle, discovering, connected, processing, declined, error — tablet landscape + portrait.

## 5. Testing

| Layer | Coverage |
|---|---|
| Unit | `FakeTerminalClient` success/decline/disconnect; MockWebServer token + PI; `TerminalHarnessViewModelTest` (Turbine) |
| Fixtures | `test/resources/terminal/*.json` |
| Stub | README curl checks against Stripe test mode |
| Instrumented | Compose test tags on harness; skip/soft-fail if stub/SDK unavailable in CI |

Acceptance without physical M2:

1. Unit tests pass with fakes  
2. With stub + `sk_test_` + simulated reader: harness can discover, connect, and complete a test PaymentIntent visible in Stripe Dashboard (test mode)

## 6. Doc sync (same change)

- `SPECIFICATION.md` — FR-FOUND-021  
- `FOUND.md` + `sprint-0.md` — FOUND-021  
- `API-REGISTRY.md` — two Draft endpoints  
- `ADR-007` — Stripe Terminal SDK + hybrid fake/real  
- `PDR-006` — production Terminal backend  
- `PROJECT-INDEX.md` — link ADR/PDR/spec/plan  
- `TEST-CONTEXT.md` — test notes  

## 7. Follow-up (not this task)

Wire `TerminalClient` into Checkout `Settlement.Card` and Self-service payment steps; replace stub URL with real backend when PDR-006 closes.
