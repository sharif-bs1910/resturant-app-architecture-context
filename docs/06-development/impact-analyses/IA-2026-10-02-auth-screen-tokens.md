# IA-2026-10-02-auth-screen-tokens

## Change summary

Additive design tokens so the pairing and sign-in screens can match the Kitchen Tablet Figma frames without raw colours or dp literals in feature code. No ticket or FR exists for this UI. There is no backend: a completed location code only navigates to sign-in, and a completed PIN only navigates home.

Tokens already present in the working tree from that UI work:

- `AppColors.card` `#FFFFFF` — keypad and passcode cells. `surface` is Oat Milk 2 and is too warm for those cards.
- `AppColors.textMuted` `#6A6664` — subtitles, hint body, and the delete icon.
- `AppSizes` for the Figma frame only: `authBrandWidth` 520, `authPanelPadding` 64, `authPanelTop` 72, `passcodeCellWidth` 56, `passcodeKeyWidth` 80, `passcodeKeyHeight` 68.

This follow-up does not change those values. Narrower widths use existing spacing tokens and shrink or scroll in the feature composables.

Select role adds default `AppSizes` only: wizard bar padding 40×28, body top 80, body width 1000, heading width 588, card padding 28, radio 28. No existing call site changes.

## Trigger (which rule)

Design tokens (`core/designsystem/theme/`).

## Consumers found (search commands + results)

| Search command | Files / matches |
|---|---|
| `rg -n "AppTheme\.colors\.card" app/src` | 3 matches, `feature/auth/PasscodeEntry.kt` only |
| `rg -n "AppTheme\.colors\.textMuted" app/src` | 3 matches: `PasscodeEntry.kt` (1), `AuthChrome.kt` (2) |
| `rg -n "AppTheme\.sizes\.(authBrandWidth\|authPanelPadding\|authPanelTop\|passcodeCellWidth\|passcodeKeyWidth\|passcodeKeyHeight)" app/src` | `AuthChrome.kt`, `PasscodeEntry.kt` |
| `rg -n "textMuted\|authBrandWidth\|passcodeKeyWidth" ../resturant-app-architecture/docs` | no matches before this analysis |

`AppColors(` is constructed only in `LightAppColors`. No other theme copy site. No test constructs `AppColors` or `AppSizes`.

## Blast radius

Direct: `AppColors.kt`, `AppDimens.kt`, pairing and sign-in screens, their previews. Indirect: none. Existing buttons, cards, and `NumericKeypad` keep `surface`. No endpoint.

## Risk (Low/Medium/High + why)

Low. The fields are additive, with defaults on `AppSizes`. The only required-arg change is `AppColors`, and the only constructor is `LightAppColors`. Call sites are the new auth screens.

## Plan (ordered `API → clients → tests → docs`)

1. API — add `card`, `textMuted`, and the auth sizes in `theme/`. No further token edits in the responsiveness follow-up.
2. Clients — `feature/auth`, `feature/pairing`, `feature/signin`. Wide tablets keep the 520dp brand column and 80×68 keys. Medium widths give the form more of the row and use `spacing.xxl` padding. Compact uses `spacing.lg`. Both panes scroll. Cells and keys shrink down to a 48dp key, then scroll horizontally.
3. Tests — `PairingViewModelTest`, `SignInViewModelTest`. `scripts/ai-hooks/design-lint-check.sh app/src/main` and `ANDROID_HOME=$HOME/Android/Sdk ./gradlew ktlintCheck testDevDebugUnitTest`. detekt stays skipped (PDR-005).
4. Docs — this analysis; a colour note in `BRAND-GUIDELINES.md`; `PROJECT-INDEX.md` last-updated. No API registry row, ADR, or FR, because there is no endpoint and no ticket.

## Rollback

Revert `AppColors.kt`, `AppDimens.kt`, `feature/auth`, `feature/pairing`, `feature/signin`, `navigation/Destinations.kt`, `navigation/AppNavHost.kt`, and the new `auth_` strings. Start destination returns to `HomeDestination`. No stored data or backend change. Re-run the test command above.

## Approval (name/date)

| Approver | Date | Decision |
|---|---|---|
| | | |
