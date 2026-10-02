# IA-2026-10-01-brand-tokens

## Change summary

Replace placeholder foundation tokens with values from **Noshi Brand Library v1.0** (Figma file `YJwjweeoIAWxM7AuzAB1Xg`, April 2026). Keep the existing `AppTheme` property names so feature and component call sites do not change.

**FR / tickets:** FR-FOUND-006 (design tokens), PDR-002. No new ticket ID.

**Source:** pages `02 · Color`, `03 · Type`, `06 · Documentation`, plus the `Color` and `Spacing & Radius` variable collections.

## Trigger (which rule)

Design tokens in `core/designsystem/theme/`.

## Consumers found (search commands + results)

Commands run from `resturant-app` on 2026-10-01.

| Search command | Files / matches |
|---|---|
| `rg -l "AppTheme" app/src --glob '*.kt'` | **42** Kotlin files |
| `rg -l "AppTheme\.colors\." app/src` | **22** files (buttons, cards, dialogs, inputs, states, `HomeScreen`, `AppScaffold`, `StatusTone`, `PreviewSurface`) |
| `rg -l "AppTheme\.typography\." app/src` | **20** files |
| `rg -l "AppTheme\.spacing\." app/src` | **30** files |
| `rg -l "AppTheme\.radius\." app/src` | **13** files (`AppButton`, `AppIconButton`, `AppTextField`, `AppCard`, `AppModal`, `SuccessDialog`, `StatusBadge`, `AppSwitch`, `NumericKeypad`, `MenuItemCard`, `KitchenTicketCard`, `SkeletonList`, `AppScaffold`) |
| `rg -l "AppTheme\.sizes\." app/src` | **19** files |
| `rg -l "AppTheme\.border\." app/src` | **7** files |
| `rg -n "PDR-002" ../resturant-app-architecture --glob '!**/superpowers/**' --glob '!**/IA-*'` | `PROJECT-INDEX.md`, `PROJECT-CONTEXT.md`, `PENDING-DECISIONS.md`, `SPECIFICATION.md`, `CONCEPT-NOTE.md`, `BUSINESS-TECH-CONTEXT.md`, `ADR-006` |

No unit test asserts a specific hex or sp value. Compose tests wrap content in `AppTheme { }` and assert by test tag, so they should keep passing if only values change.

## Blast radius

**In scope (token values and font files only)**

| Area | Change |
|---|---|
| `AppColors.kt` | Map brand primitives and semantic aliases onto existing fields (table below). Status colours the library does not define stay as they are. |
| `AppTypography.kt` | Point styles at Fraunces, Inter, and JetBrains Mono. Remap sizes to the brand scale while keeping property names. |
| `app/src/main/res/font/` | Add **static** font files. minSdk is 25; variable fonts need API 26, so do not ship variable font files. |
| `AppDimens.kt` `AppRadius` | `md` 12 → 14, `lg` 16 → 20, `xl` 24 → 28 (brand Radius/MD, LG, XL). `sm` 8 and `pill` 999 already match. |
| `focusRing` | `#2563EB` → Hot Sauce `#FF5A3C`. `AppBorder.focus` stays 2dp. |

**Color mapping (existing field → brand token)**

| Field | New value | Brand token |
|---|---|---|
| `primary` | `#FF5A3C` | Brand / Hot Sauce |
| `onPrimary` | `#1A1410` | Neutral / Espresso (AA 5.89 on Hot Sauce at body size). Oat Milk on Hot Sauce is 2.88 and fails AA below 48px. |
| `primaryPressed` | `#E43B1E` | Brand / Hot Sauce Deep |
| `secondary` | `#E4FF3B` | Brand / Citrus Zest (Surface / Accent) |
| `onSecondary` | `#1A1410` | Neutral / Espresso |
| `background` | `#FBF6EE` | Neutral / Oat Milk |
| `surface` | `#F3ECDD` | Neutral / Oat Milk 2 (Background / Elevated) |
| `textPrimary` | `#1A1410` | Neutral / Espresso |
| `textSecondary` | `#2D1F14` | Neutral / Miso (Text / Muted) |
| `focusRing` | `#FF5A3C` | Brand / Hot Sauce |

`primaryContainer`, `secondaryContainer`, outlines, disabled, scrim, and all success / warning / info / destructive fields have **no brand token**. Leave those hex values unchanged.

**Type mapping (existing field → brand token)**

| Field | Family / weight | Size / line height |
|---|---|---|
| `displayLarge` | Fraunces SemiBold | 56sp / 54sp (`display.section`, 96%) |
| `headlineLarge` | Inter ExtraBold | 40sp / 42sp (`ui.h1`, 105%) |
| `headlineMedium` | Fraunces SemiBold | 44sp / 46sp (`display.card`, 105%) |
| `headlineSmall` | Inter Bold | 24sp / 29sp (`ui.h2`, 120%) |
| `bodyLarge` | Inter Regular | 18sp / 27sp (`body.lg`, 150%) |
| `bodyMedium` | Inter Regular | 14sp / 22sp (`body.base`, 155%) |
| `bodySmall` | Inter Regular | 12sp / 19sp (`body.sm`, 155%) |
| `labelLarge` | Inter Bold | 13sp / 14sp (`ui.button`, 105%) |
| `labelSmall` | JetBrains Mono Regular | 11sp / 11sp (`mono.eyebrow`) |
| `price*` / `numericDisplay` | Inter, keep tabular `tnum` | Keep current sizes |

`display.hero` (128) is not assigned to a default style. It is too large for the shared display token.

**Out of scope**

- Do not rename `AppTheme` properties (42 call sites).
- Do not change `AppSpacing` values. Overlapping steps already match the brand (0, 4, 8, 12, 16, 24, 32, 48). Brand steps 20, 28, 40, 56, 64, 80 and the local `xxs` 2dp stay unmapped.
- Do not change `minTouchTarget` from 48dp to the library’s 44px (iOS HIG). Android touch target stays 48dp.
- Do not restyle `AppButton` to a pill. It still reads `AppTheme.radius.md`. Pill buttons are a later component change.
- Do not add a 375dp phone breakpoint. Product stays tablet only.
- Do not edit component signatures, DTOs, or the manifest.

## Risk (Low/Medium/High + why)

**Medium** — every screen and preview picks up new colours, type, and three radius steps, but Kotlin call sites stay source-compatible and no contract or exhaustive `when` changes. Status colours stay placeholder, so badges do not fully match a brand status system the library does not define.

## Plan (ordered `API → clients → tests → docs`)

1. **API** — Update values in `AppColors.kt`, `AppTypography.kt`, and `AppRadius` in `AppDimens.kt`. Add static font files under `app/src/main/res/font/` and wire `FontFamily`s. Do not add or rename public token properties.
2. **Clients** — None. Components keep using `AppTheme.*`.
3. **Tests** — `ANDROID_HOME=$HOME/Android/Sdk ./gradlew ktlintCheck testDevDebugUnitTest` and `scripts/ai-hooks/design-lint-check.sh app/src/main`. No new token-value unit test unless a compile failure appears.
4. **Docs** — Update PDR-002 in `PENDING-DECISIONS.md` and `PROJECT-INDEX.md` to record what was applied and what remains open (status colours, unmapped spacing, pill buttons, 44px target). Amend ADR-006 consequences and the FR-FOUND-006 acceptance line in `SPECIFICATION.md` so it no longer says the whole palette is a placeholder. Update `.ai/context/project-overview.md` open-decisions line.

## Rollback

Revert the token files, font resources, and the doc edits in this change. Re-run the same Gradle and design-lint commands. No stored user data, tokens, or backend state.

## Approval (name/date)

| Approver | Date | Decision |
|---|---|---|
| Human (chat) | 2026-10-01 | Approved — implement |
