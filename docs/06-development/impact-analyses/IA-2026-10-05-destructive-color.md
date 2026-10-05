# IA-2026-10-05-destructive-color

<!--
Copy to docs/06-development/impact-analyses/IA-YYYY-MM-DD-<topic>.md.
Required before changing any trigger listed in .ai/AI-ASSISTANT-RULES.md#impact-analysis.
No file covered by this analysis is edited until a human fills in the Approval section.
-->

## Change summary

Do not change the shared `destructive` color (`#B91C1C`). Add a new theme token for the Figma status-danger brown `#8B3A1F`, and use it only on the Orders Refund and Cancel & refund buttons.

No ticket or FR-FOUND ID. The earlier plan in this file, which replaced `destructive` everywhere, is withdrawn.

## Trigger (which rule)

Design tokens in `core/designsystem/theme/`.

## Consumers found (search commands + results)

| Search command | Files / matches |
|---|---|
| `rg -n "statusDanger" app/src` | No matches. The token does not exist yet. |
| `rg -n "destructive = true" app/src/main/java/com/noshitechinc/restaurant/feature/checkout/CheckoutOrders.kt` | 2 matches, both `DialogButtons(..., destructive = true)`: Refund confirm and Cancel & refund confirm. Those are the only `PillButton` callers that pass `destructive = true`. |
| `rg -n "AppTheme\.colors\.destructive\b" app/src` | 7 matches that stay on `#B91C1C`: `ErrorState.kt` (2), `PairingScreen.kt` (2), `AppScaffold.kt` (1), `PasscodeEntry.kt` (1), `CheckoutOrders.kt` (2: canceled icon and recap accent). |
| `rg -n "c\.destructive\b" app/src` | 6 matches that stay on `#B91C1C`: `AppButton.kt`, `AppTextField.kt` (3), `ListRow.kt` (2). |
| `rg -n "B91C1C\|8B3A1F\|destructive" ../resturant-app-architecture/docs --glob '*.md'` | PDR-002 still leaves status colours on the previous palette. This change adds one new fill and does not replace that palette. |

## Blast radius

Direct:

- `app/src/main/java/com/noshitechinc/restaurant/core/designsystem/theme/AppColors.kt` — new `statusDanger` field and `LightAppColors.statusDanger = Color(0xFF8B3A1F)`.
- `app/src/main/java/com/noshitechinc/restaurant/feature/checkout/CheckoutChrome.kt` — `PillButton` destructive fill reads `statusDanger` instead of `destructive`. Label colour stays `background`.

Indirect: only the two Orders confirm buttons (Refund, Cancel & refund). `AppButton`, error states, passcode, pairing, list rows, and the canceled-order icon stay `#B91C1C`. No Material `colorScheme.error` change. No container or pressed token.

`AppColors` is a data class, so the new field is added with the other colour fields. There is one constructor, `LightAppColors`.

## Risk (Low/Medium/High + why)

Low — additive token. One existing call path changes colour (`PillButton` when `destructive` is true), and that path has two callers, both the buttons named above. `destructive` hex stays `#B91C1C`.

## Plan (ordered `API → clients → tests → docs`)

1. API — Add `statusDanger: Color` to `AppColors` and set it to `#8B3A1F` in `LightAppColors`. Leave `destructive` and `destructivePressed` unchanged.
2. Clients — In `CheckoutChrome.kt`, the destructive `PillButton` background uses `AppTheme.colors.statusDanger`.
3. Tests — no assertion updates. `ANDROID_HOME=$HOME/Android/Sdk ./gradlew ktlintCheck testDevDebugUnitTest` and `scripts/ai-hooks/design-lint-check.sh app/src/main`. Detekt stays deferred (PDR-005).
4. Docs — one line on PDR-002 that `statusDanger` is `#8B3A1F` and the other status colours are still open. Update the `PROJECT-INDEX.md` last-updated line in the same change.

## Rollback

Remove `statusDanger` from `AppColors` / `LightAppColors`, point the `PillButton` destructive fill back at `destructive`, and revert the PDR-002 / `PROJECT-INDEX.md` lines. No stored data or backend change. Verify with the same Gradle and design-lint commands.

## Approval (name/date)

<!-- Filled in by the human approver, never by the AI. -->

| Approver | Date | Decision |
|---|---|---|
| | | |
