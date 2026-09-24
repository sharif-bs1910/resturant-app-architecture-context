# ADR-006 — Design system and adaptive layout: tokens, shared components, previews, AdaptiveInfo, orientation policy

## Status

Accepted (amended 2026-09-24 — tablet only; see IA-2026-09-24-tablet-only)

## Date

2026-09-24

## Context

The app must look and behave consistently across every future screen, target **tablets only**, handle long and translated content, and switch to Figma brand values later without touching feature code (FR-FOUND-003, FR-FOUND-006…FR-FOUND-020). Brand tokens are not available yet (PDR-002). Components are verified through previews because the foundation ships only a blank home screen. Tablets should run in landscape, but Android 16 (targetSdk 36) ignores orientation and resizability restrictions on displays with smallest width ≥ 600dp.

## Decision

- **Tokens** in `core/designsystem/theme/`, light only, placeholder values: `AppColors`, `AppTypography` (including tabular-figure numeric styles), `AppSpacing`, `AppRadius`, `AppBorder`, `AppSizes` (minTouchTarget 48dp, posButtonHeight 56dp, dialogMaxWidth 560dp, content max widths). Exposed as `AppTheme.colors`, `.typography`, `.spacing`, `.radius`, `.border`, `.sizes` via CompositionLocals and mapped into Material3 `lightColorScheme`, `Typography` and `Shapes`. No colour, dp, sp or user-facing string literal outside theme and resource files; enforced by the design-lint hook and `design-lint-check.sh`.
- **Status tones:** `StatusTone { Neutral, Info, Success, Warning, Danger }` in the design system; feature modules map their own statuses to tones later, keeping domain concepts out of `designsystem`.
- **Component library** in `core/designsystem/component/<group>/`: buttons, inputs, selection, quantity, cards, dialogs, rows. Conventions: required parameters first, then `modifier`, then optional parameters; stateless value + `onValueChange`; `enabled`; optional `interactionSource` with visuals from `rememberInteractionVisuals` and a `focusRing`.
- **States:** generic states (`LoadingState`, progress, `SkeletonList`, `EmptyState`, `NoSearchResultsState`) in `core/designsystem/state`; error-aware states (`ErrorState`, `ServiceUnavailableState`, `OfflineBlockingState`, `LoadStateContent`) and `AppScaffold` in `core/ui`, because `designsystem` must not depend on `AppError`.
- **Long content:** names use `maxLines` + ellipsis; prices are never truncated; addresses wrap up to 3 lines; buttons and chips grow in height. Verified at font scale 1.0, 1.5 and 2.0 and with the `en-XA` pseudo-locale.
- **Previews** in `core/designsystem/preview/`: `@TabletLandscapePreview` (1280×800dp), `@TabletPortraitPreview` (800×1280dp), `@FontScalePreviews` (1.0/1.5/2.0), `@ComponentPreviews` (tablet medium width, tablet expanded width, tablet medium width at font 2.0) and `@ScreenPreviews` (tablet landscape, tablet portrait, tablet landscape at font 2.0); `PreviewSurface { }` applies `AppTheme`; `PreviewData` holds long and translated samples; pressed and focused visuals render through the preview-only `ForcedInteraction`. Every component and screen file ends with previews covering each variant and state. There is no (removed — tablet only).
- **Adaptive layout:** own `AdaptiveInfo` + `WidthClass` computed from `LocalConfiguration` (`rememberAdaptiveInfo()`): Compact < 600dp (narrow multi-window), Medium 600–839dp, Expanded ≥ 840dp; `usesTwoPane` for Medium and Expanded; `cardColumns` 2 / 3 / 4. No `material3-window-size-class` or `material3-adaptive` dependency. Phones are not a supported product target.
- **Orientation policy:** `OrientationPolicy.requestedOrientation(smallestScreenWidthDp)` in `MainActivity` always returns `SCREEN_ORIENTATION_SENSOR_LANDSCAPE` (tablet-only product).
- **Android 16 caveat:** on targetSdk 36, Android 16 ignores the orientation request and resizability restrictions on sw600dp+ displays. The manifest declares the opt-out property `android.window.PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY`, which is honoured only while targetSdk is 36. Tablet layouts must therefore still work in portrait and multi-window, and screen previews include tablet portrait.

## Consequences

- Figma values (PDR-002) replace token values in one package; feature code does not change.
- Previews work without Hilt or window-size providers, because `AdaptiveInfo` reads `LocalConfiguration` directly.
- Every new component carries a preview matrix, which costs time per component but keeps visual regressions visible and makes font-scale problems obvious early.
- Changing tokens or public parameters of shared components requires an impact analysis.
- Raising targetSdk above 36 removes the orientation opt-out; tablet portrait and multi-window layouts are already required, so this does not break the app.

## Alternatives considered

- **Material3 defaults without custom tokens** — rejected: cannot express POS-specific sizes, status tones and numeric styles, and replacing brand values later would touch feature code.
- **SDP/SSP dimension libraries** — rejected: scale dimensions by screen size instead of using fixed, reviewable tokens.
- **`material3-window-size-class` / `material3-adaptive`** — rejected at plan time: they need providers that are awkward in previews and add dependencies; `AdaptiveInfo` covers the needed rules.
- **Design system depending on `AppError`** — rejected: error-aware states live in `core/ui` to keep `designsystem` free of app-level types.
- **Hard landscape lock only (`screenOrientation="landscape"` in the manifest)** — rejected: ignored on Android 16 large screens; tablet portrait and multi-window must still be designed.
- **Phone/handset layouts as a product target** — rejected (amended): product is tablet only.
