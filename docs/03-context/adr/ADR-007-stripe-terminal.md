# ADR-007 — Stripe Terminal SDK with hybrid fake/real client

## Status

Accepted

## Date

2026-10-14

## Context

The app needs in-person card payments via Stripe Reader M2. There is no product backend yet for connection tokens or PaymentIntents. Checkout and Self-service currently use demo delays. Developers need automated tests without hardware and a path to exercise Stripe’s simulated reader against a test sandbox (FR-FOUND-021).

## Decision

- Depend on Stripe Terminal Android SDK **6.0.0** (`stripeterminal` + `stripeterminal-ktx`). Raise **minSdk to 26** (SDK requirement).
- Expose `TerminalClient` in `core/terminal` with:
  - `StripeTerminalClient` when `BuildConfig.TERMINAL_ENABLED`
  - `FakeTerminalClient` when disabled (and for unit tests)
- Connection tokens and PaymentIntents come from a **separate Retrofit base URL** (`TERMINAL_STUB_BASE_URL`), not the main API host. Endpoints: `api:terminal:connection-token`, `api:terminal:create-payment-intent` (Draft).
- Ship `tools/stripe-terminal-stub/` which calls Stripe Test APIs using `STRIPE_SECRET_KEY` from the environment only. Never put secret keys in the APK or git.
- Dev-only harness under `feature/terminalharness` for discover → connect → $1.00 pay.
- Checkout card collect uses Terminal when `TERMINAL_ENABLED` (discover/connect if needed → PaymentIntent → `processPayment`); cash/delivery and disabled builds keep the demo delay. Self-service wiring remains a follow-up.
- `TerminalApplicationDelegate.onCreate` runs only when Terminal is enabled.

## Consequences

- Staging/prod builds stay free of Terminal runtime init side effects when `TERMINAL_ENABLED=false`.
- Cleartext HTTP to `10.0.2.2` / localhost is allowed only in the `dev` network security config.
- Production must replace the stub with an authenticated backend (PDR-006).
- APK size grows due to the Terminal SDK; tablet product already targets modern devices (minSdk 26).

## Alternatives considered

- **Fully fake only** — rejected for this change: sandbox verification with simulated reader was required.
- **Secret key or static token JSON in the app** — rejected: insecure and incompatible with Stripe’s connection-token model.
- **Server-driven Terminal only** — deferred; client SDK is required for M2 Bluetooth/USB flows on Android.
