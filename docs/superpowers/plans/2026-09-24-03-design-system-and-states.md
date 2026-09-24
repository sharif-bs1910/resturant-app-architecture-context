# Plan 3 of 3 — Design System, Components, States & App Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the design tokens, theme, preview infrastructure, all shared components (buttons, inputs, selection, quantity, cards, dialogs, rows), loading/empty/error/offline states, `AppScaffold`, navigation, the blank home screen and Compose UI tests, satisfying FR-FOUND-003 and FR-FOUND-006…020.

**Architecture:** `core/designsystem/{theme,interaction,preview,component/<group>,state}` is independent of `domain`/`data`/`feature`. Error-aware UI (`ErrorState`, `ServiceUnavailableState`, `OfflineBlockingState`, `LoadStateContent`, `AppScaffold`) lives in `core/ui` because it depends on `AppError`/`UiEffect`. Every public composable has previews at the bottom of its file; pressed/focused previews use `ForcedInteraction`.

**Tech Stack:** Jetpack Compose (BOM 2025.07.00), Material3, material-icons-extended, Coil 3.3.0, Navigation Compose 2.8.5 type-safe routes, Hilt, Compose UI test (JUnit4).

**Spec:** §4.2, §7, §8, §10, §11, §14. **Depends on:** Plan 2 (all tasks).

## Global Constraints

- Paths: `SRC/` = `app/src/main/java/com/noshitechinc/restaurant/`, `TEST/` = `app/src/test/java/com/noshitechinc/restaurant/`, `ATEST/` = `app/src/androidTest/java/com/noshitechinc/restaurant/`.
- Gradle commands prefixed with `ANDROID_HOME=$HOME/Android/Sdk`. No git. "Checkpoint" = list changed files.
- Light mode only; English strings in `res/values/strings.xml`; no string literals, `Color(0x…)`, or `N.dp`/`N.sp` literals in `feature/`, `core/ui/`, `core/designsystem/` outside `theme/` and `preview/` — except inside preview functions at the bottom of files. `scripts/ai-hooks/design-lint-check.sh app/src/main` must print nothing.
- Component API conventions: first required params, then `modifier: Modifier = Modifier`, then optional params; stateless (`value` + `onValueChange`); `enabled: Boolean = true`; interactive components accept `interactionSource: MutableInteractionSource? = null` and use `rememberInteractionVisuals(...)`.
- Touch targets ≥ `AppTheme.sizes.minTouchTarget` (48dp); primary POS actions use `ButtonSize.Large` (56dp).
- Long content: names `maxLines` + `TextOverflow.Ellipsis`; prices/amounts never truncated (laid out with intrinsic width, name gets `Modifier.weight(1f)`); addresses up to 3 lines; buttons/chips grow in height.
- Previews per component file: every variant × relevant states (enabled, disabled, pressed, focused, loading, error), long-text/translated sample (`PreviewData`), all via `@ComponentPreviews` (includes font scale 2.0 and tablet width). Screens use `@ScreenPreviews`.
- Every new user-facing string goes in `strings.xml` (Task 1 adds the full set used by this plan).

---

### Task 1: Tokens, theme, interaction visuals, preview infrastructure, strings

**Files:**
- Create: `SRC/core/designsystem/theme/AppColors.kt`, `AppTypography.kt`, `AppDimens.kt` (spacing, radius, border, sizes), `StatusTone.kt`, `AppTheme.kt`
- Create: `SRC/core/designsystem/interaction/InteractionVisuals.kt`
- Create: `SRC/core/designsystem/preview/PreviewAnnotations.kt`, `PreviewSurface.kt`, `PreviewData.kt`
- Create: `SRC/core/ui/UiTextExt.kt`
- Modify: `app/src/main/res/values/strings.xml`
- Test: `TEST/core/designsystem/theme/StatusToneTest.kt`

**Interfaces (Produces):**
- `AppTheme { }` composable; `AppTheme.colors: AppColors`, `.typography: AppTypography`, `.spacing: AppSpacing`, `.radius: AppRadius`, `.border: AppBorder`, `.sizes: AppSizes`
- `enum class StatusTone { Neutral, Info, Success, Warning, Danger }`; `@Composable fun StatusTone.containerColor(): Color`, `@Composable fun StatusTone.contentColor(): Color`
- `enum class ForcedInteraction { None, Pressed, Focused }`, `val LocalForcedInteraction`, `data class InteractionVisuals(pressed, focused)`, `@Composable fun rememberInteractionVisuals(interactionSource: InteractionSource): InteractionVisuals`, `fun Modifier.focusRing(visible: Boolean, color: Color, width: Dp, shape: Shape): Modifier`
- Annotations `@TabletLandscapePreview`, `@TabletPortraitPreview`, `@FontScalePreviews`, `@ComponentPreviews`, `@ScreenPreviews`; `@Composable fun PreviewSurface(modifier, forcedInteraction, content)`; `object PreviewData`
- `@Composable fun UiText.asString(): String`, `fun UiText.asString(context: Context): String`

- [ ] **Step 1: Write failing test**

`TEST/core/designsystem/theme/StatusToneTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem.theme

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals

class StatusToneTest {
    @Test
    fun `every tone has distinct container and content colors`() {
        StatusTone.entries.forEach { tone ->
            val (container, content) = LightAppColors.toneColors(tone)
            assertNotEquals(container, content, "tone $tone")
        }
    }

    @Test
    fun `danger maps to destructive palette`() {
        assertEquals(LightAppColors.destructiveContainer to LightAppColors.onDestructiveContainer, LightAppColors.toneColors(StatusTone.Danger))
    }
}
```

- [ ] **Step 2: Run — expect FAIL** (`./gradlew testDevDebugUnitTest`).

- [ ] **Step 3: Implement tokens**

`SRC/core/designsystem/theme/AppColors.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem.theme

import androidx.compose.runtime.Immutable
import androidx.compose.ui.graphics.Color

@Immutable
data class AppColors(
    val primary: Color,
    val onPrimary: Color,
    val primaryPressed: Color,
    val primaryContainer: Color,
    val onPrimaryContainer: Color,
    val secondary: Color,
    val onSecondary: Color,
    val secondaryPressed: Color,
    val secondaryContainer: Color,
    val onSecondaryContainer: Color,
    val background: Color,
    val surface: Color,
    val surfaceVariant: Color,
    val surfacePressed: Color,
    val outline: Color,
    val outlineVariant: Color,
    val textPrimary: Color,
    val textSecondary: Color,
    val textDisabled: Color,
    val disabledContainer: Color,
    val destructive: Color,
    val onDestructive: Color,
    val destructivePressed: Color,
    val destructiveContainer: Color,
    val onDestructiveContainer: Color,
    val success: Color,
    val successContainer: Color,
    val onSuccessContainer: Color,
    val warning: Color,
    val warningContainer: Color,
    val onWarningContainer: Color,
    val info: Color,
    val infoContainer: Color,
    val onInfoContainer: Color,
    val neutralContainer: Color,
    val onNeutralContainer: Color,
    val focusRing: Color,
    val scrim: Color,
)

val LightAppColors = AppColors(
    primary = Color(0xFFC2410C),
    onPrimary = Color(0xFFFFFFFF),
    primaryPressed = Color(0xFF9A3412),
    primaryContainer = Color(0xFFFFEDD5),
    onPrimaryContainer = Color(0xFF7C2D12),
    secondary = Color(0xFF0F766E),
    onSecondary = Color(0xFFFFFFFF),
    secondaryPressed = Color(0xFF115E59),
    secondaryContainer = Color(0xFFCCFBF1),
    onSecondaryContainer = Color(0xFF134E4A),
    background = Color(0xFFF8F7F5),
    surface = Color(0xFFFFFFFF),
    surfaceVariant = Color(0xFFF1EFEC),
    surfacePressed = Color(0xFFE7E5E4),
    outline = Color(0xFFD6D3D1),
    outlineVariant = Color(0xFFE7E5E4),
    textPrimary = Color(0xFF1C1917),
    textSecondary = Color(0xFF57534E),
    textDisabled = Color(0xFFA8A29E),
    disabledContainer = Color(0xFFE7E5E4),
    destructive = Color(0xFFB91C1C),
    onDestructive = Color(0xFFFFFFFF),
    destructivePressed = Color(0xFF991B1B),
    destructiveContainer = Color(0xFFFEE2E2),
    onDestructiveContainer = Color(0xFF7F1D1D),
    success = Color(0xFF15803D),
    successContainer = Color(0xFFDCFCE7),
    onSuccessContainer = Color(0xFF14532D),
    warning = Color(0xFFB45309),
    warningContainer = Color(0xFFFEF3C7),
    onWarningContainer = Color(0xFF78350F),
    info = Color(0xFF1D4ED8),
    infoContainer = Color(0xFFDBEAFE),
    onInfoContainer = Color(0xFF1E3A8A),
    neutralContainer = Color(0xFFF5F5F4),
    onNeutralContainer = Color(0xFF44403C),
    focusRing = Color(0xFF2563EB),
    scrim = Color(0x99000000),
)
```

`SRC/core/designsystem/theme/StatusTone.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.graphics.Color

enum class StatusTone { Neutral, Info, Success, Warning, Danger }

fun AppColors.toneColors(tone: StatusTone): Pair<Color, Color> = when (tone) {
    StatusTone.Neutral -> neutralContainer to onNeutralContainer
    StatusTone.Info -> infoContainer to onInfoContainer
    StatusTone.Success -> successContainer to onSuccessContainer
    StatusTone.Warning -> warningContainer to onWarningContainer
    StatusTone.Danger -> destructiveContainer to onDestructiveContainer
}

@Composable
@ReadOnlyComposable
fun StatusTone.containerColor(): Color = AppTheme.colors.toneColors(this).first

@Composable
@ReadOnlyComposable
fun StatusTone.contentColor(): Color = AppTheme.colors.toneColors(this).second
```

`SRC/core/designsystem/theme/AppTypography.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem.theme

import androidx.compose.material3.Typography
import androidx.compose.runtime.Immutable
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

@Immutable
data class AppTypography(
    val displayLarge: TextStyle,
    val headlineLarge: TextStyle,
    val headlineMedium: TextStyle,
    val headlineSmall: TextStyle,
    val titleLarge: TextStyle,
    val titleMedium: TextStyle,
    val titleSmall: TextStyle,
    val bodyLarge: TextStyle,
    val bodyMedium: TextStyle,
    val bodySmall: TextStyle,
    val labelLarge: TextStyle,
    val labelMedium: TextStyle,
    val labelSmall: TextStyle,
    val priceLarge: TextStyle,
    val priceMedium: TextStyle,
    val priceSmall: TextStyle,
    val numericDisplay: TextStyle,
)

private fun style(size: Int, lineHeight: Int, weight: FontWeight, tabular: Boolean = false) = TextStyle(
    fontFamily = FontFamily.Default,
    fontSize = size.sp,
    lineHeight = lineHeight.sp,
    fontWeight = weight,
    fontFeatureSettings = if (tabular) "tnum" else null,
)

val DefaultAppTypography = AppTypography(
    displayLarge = style(45, 52, FontWeight.Normal),
    headlineLarge = style(32, 40, FontWeight.SemiBold),
    headlineMedium = style(28, 36, FontWeight.SemiBold),
    headlineSmall = style(24, 32, FontWeight.SemiBold),
    titleLarge = style(22, 28, FontWeight.SemiBold),
    titleMedium = style(18, 24, FontWeight.SemiBold),
    titleSmall = style(16, 22, FontWeight.Medium),
    bodyLarge = style(16, 24, FontWeight.Normal),
    bodyMedium = style(14, 20, FontWeight.Normal),
    bodySmall = style(12, 16, FontWeight.Normal),
    labelLarge = style(16, 20, FontWeight.SemiBold),
    labelMedium = style(14, 18, FontWeight.Medium),
    labelSmall = style(12, 16, FontWeight.Medium),
    priceLarge = style(24, 32, FontWeight.SemiBold, tabular = true),
    priceMedium = style(18, 24, FontWeight.SemiBold, tabular = true),
    priceSmall = style(14, 20, FontWeight.Medium, tabular = true),
    numericDisplay = style(40, 48, FontWeight.SemiBold, tabular = true),
)

fun AppTypography.toMaterialTypography(): Typography = Typography(
    displayLarge = displayLarge,
    headlineLarge = headlineLarge,
    headlineMedium = headlineMedium,
    headlineSmall = headlineSmall,
    titleLarge = titleLarge,
    titleMedium = titleMedium,
    titleSmall = titleSmall,
    bodyLarge = bodyLarge,
    bodyMedium = bodyMedium,
    bodySmall = bodySmall,
    labelLarge = labelLarge,
    labelMedium = labelMedium,
    labelSmall = labelSmall,
)
```

`SRC/core/designsystem/theme/AppDimens.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem.theme

import androidx.compose.runtime.Immutable
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Immutable
data class AppSpacing(
    val none: Dp = 0.dp,
    val xxs: Dp = 2.dp,
    val xs: Dp = 4.dp,
    val sm: Dp = 8.dp,
    val md: Dp = 12.dp,
    val lg: Dp = 16.dp,
    val xl: Dp = 24.dp,
    val xxl: Dp = 32.dp,
    val xxxl: Dp = 48.dp,
)

@Immutable
data class AppRadius(
    val none: Dp = 0.dp,
    val xs: Dp = 4.dp,
    val sm: Dp = 8.dp,
    val md: Dp = 12.dp,
    val lg: Dp = 16.dp,
    val xl: Dp = 24.dp,
    val pill: Dp = 999.dp,
)

@Immutable
data class AppBorder(
    val thin: Dp = 1.dp,
    val medium: Dp = 1.5.dp,
    val thick: Dp = 2.dp,
    val focus: Dp = 2.dp,
)

@Immutable
data class AppSizes(
    val minTouchTarget: Dp = 48.dp,
    val buttonSmall: Dp = 40.dp,
    val buttonMedium: Dp = 48.dp,
    val buttonLarge: Dp = 56.dp,
    val inputHeight: Dp = 56.dp,
    val iconSm: Dp = 16.dp,
    val iconMd: Dp = 24.dp,
    val iconLg: Dp = 32.dp,
    val iconXl: Dp = 48.dp,
    val illustration: Dp = 72.dp,
    val progressSmall: Dp = 20.dp,
    val stepperButton: Dp = 48.dp,
    val stepperValueMinWidth: Dp = 48.dp,
    val keypadKey: Dp = 72.dp,
    val keypadMaxWidth: Dp = 360.dp,
    val cardImage: Dp = 88.dp,
    val badgeMinHeight: Dp = 28.dp,
    val skeletonLine: Dp = 16.dp,
    val listRowMinHeight: Dp = 56.dp,
    val dialogMaxWidth: Dp = 560.dp,
    val formMaxWidth: Dp = 640.dp,
    val contentMaxWidth: Dp = 1200.dp,
)
```

`SRC/core/designsystem/theme/AppTheme.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf

private val LocalAppColors = staticCompositionLocalOf { LightAppColors }
private val LocalAppTypography = staticCompositionLocalOf { DefaultAppTypography }
private val LocalAppSpacing = staticCompositionLocalOf { AppSpacing() }
private val LocalAppRadius = staticCompositionLocalOf { AppRadius() }
private val LocalAppBorder = staticCompositionLocalOf { AppBorder() }
private val LocalAppSizes = staticCompositionLocalOf { AppSizes() }

object AppTheme {
    val colors: AppColors
        @Composable @ReadOnlyComposable
        get() = LocalAppColors.current
    val typography: AppTypography
        @Composable @ReadOnlyComposable
        get() = LocalAppTypography.current
    val spacing: AppSpacing
        @Composable @ReadOnlyComposable
        get() = LocalAppSpacing.current
    val radius: AppRadius
        @Composable @ReadOnlyComposable
        get() = LocalAppRadius.current
    val border: AppBorder
        @Composable @ReadOnlyComposable
        get() = LocalAppBorder.current
    val sizes: AppSizes
        @Composable @ReadOnlyComposable
        get() = LocalAppSizes.current
}

@Composable
fun AppTheme(content: @Composable () -> Unit) {
    val colors = LightAppColors
    val typography = DefaultAppTypography
    val radius = AppRadius()
    CompositionLocalProvider(
        LocalAppColors provides colors,
        LocalAppTypography provides typography,
        LocalAppSpacing provides AppSpacing(),
        LocalAppRadius provides radius,
        LocalAppBorder provides AppBorder(),
        LocalAppSizes provides AppSizes(),
    ) {
        MaterialTheme(
            colorScheme = colors.toColorScheme(),
            typography = typography.toMaterialTypography(),
            shapes = radius.toShapes(),
            content = content,
        )
    }
}

private fun AppColors.toColorScheme(): ColorScheme = lightColorScheme(
    primary = primary,
    onPrimary = onPrimary,
    primaryContainer = primaryContainer,
    onPrimaryContainer = onPrimaryContainer,
    secondary = secondary,
    onSecondary = onSecondary,
    secondaryContainer = secondaryContainer,
    onSecondaryContainer = onSecondaryContainer,
    background = background,
    onBackground = textPrimary,
    surface = surface,
    onSurface = textPrimary,
    surfaceVariant = surfaceVariant,
    onSurfaceVariant = textSecondary,
    outline = outline,
    outlineVariant = outlineVariant,
    error = destructive,
    onError = onDestructive,
    errorContainer = destructiveContainer,
    onErrorContainer = onDestructiveContainer,
    scrim = scrim,
)

private fun AppRadius.toShapes(): Shapes = Shapes(
    extraSmall = RoundedCornerShape(xs),
    small = RoundedCornerShape(sm),
    medium = RoundedCornerShape(md),
    large = RoundedCornerShape(lg),
    extraLarge = RoundedCornerShape(xl),
)
```

- [ ] **Step 4: Interaction visuals** `SRC/core/designsystem/interaction/InteractionVisuals.kt`

```kotlin
package com.noshitechinc.restaurant.core.designsystem.interaction

import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.InteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.Dp

enum class ForcedInteraction { None, Pressed, Focused }

val LocalForcedInteraction = staticCompositionLocalOf { ForcedInteraction.None }

@Immutable
data class InteractionVisuals(val pressed: Boolean, val focused: Boolean)

@Composable
fun rememberInteractionVisuals(interactionSource: InteractionSource): InteractionVisuals {
    val pressed by interactionSource.collectIsPressedAsState()
    val focused by interactionSource.collectIsFocusedAsState()
    val forced = LocalForcedInteraction.current
    return InteractionVisuals(
        pressed = pressed || forced == ForcedInteraction.Pressed,
        focused = focused || forced == ForcedInteraction.Focused,
    )
}

fun Modifier.focusRing(visible: Boolean, color: Color, width: Dp, shape: Shape): Modifier =
    if (visible) border(width, color, shape) else this
```

- [ ] **Step 5: Preview infrastructure**

`SRC/core/designsystem/preview/PreviewAnnotations.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem.preview

import androidx.compose.ui.tooling.preview.Preview

@Preview(name = "Tablet landscape", device = "spec:width=1280dp,height=800dp,dpi=240", showBackground = true)
annotation class TabletLandscapePreview

@Preview(name = "Tablet portrait", device = "spec:width=800dp,height=1280dp,dpi=240", showBackground = true)
annotation class TabletPortraitPreview

@Preview(name = "Font 1.0", fontScale = 1f, showBackground = true)
@Preview(name = "Font 1.5", fontScale = 1.5f, showBackground = true)
@Preview(name = "Font 2.0", fontScale = 2f, showBackground = true)
annotation class FontScalePreviews

@Preview(name = "Tablet medium width", widthDp = 800, showBackground = true)
@Preview(name = "Tablet expanded width", widthDp = 1280, showBackground = true)
@Preview(name = "Tablet medium width, font 2.0", widthDp = 800, fontScale = 2f, showBackground = true)
annotation class ComponentPreviews

@TabletLandscapePreview
@TabletPortraitPreview
@Preview(name = "Tablet landscape, font 2.0", device = "spec:width=1280dp,height=800dp,dpi=240", fontScale = 2f, showBackground = true)
annotation class ScreenPreviews
```

`SRC/core/designsystem/preview/PreviewSurface.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem.preview

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import com.noshitechinc.restaurant.core.designsystem.interaction.ForcedInteraction
import com.noshitechinc.restaurant.core.designsystem.interaction.LocalForcedInteraction
import com.noshitechinc.restaurant.core.designsystem.theme.AppTheme

@Composable
fun PreviewSurface(
    modifier: Modifier = Modifier,
    forcedInteraction: ForcedInteraction = ForcedInteraction.None,
    content: @Composable () -> Unit,
) {
    AppTheme {
        CompositionLocalProvider(LocalForcedInteraction provides forcedInteraction) {
            Surface(modifier = modifier, color = AppTheme.colors.background) {
                Box(modifier = Modifier.padding(AppTheme.spacing.lg)) { content() }
            }
        }
    }
}
```

`SRC/core/designsystem/preview/PreviewData.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem.preview

object PreviewData {
    const val SHORT_NAME = "Latte"
    const val LONG_NAME = "Slow-roasted heritage pork shoulder with charred spring onions, apple cider glaze and extra crispy crackling"
    const val DESCRIPTION = "Double shot espresso with steamed whole milk."
    const val LONG_DESCRIPTION = "Hand-pulled noodles in a rich twelve-hour bone broth, topped with marinated soft egg, bamboo shoots, nori, " +
        "scallions and a spoon of house chili crisp. Contains gluten, egg, soy and sesame."
    const val PRICE = "$4.50"
    const val LONG_PRICE = "$12,345,678.90"
    const val TABLE = "Table 12"
    const val CUSTOMER_LONG = "Alexandria Catherine Montgomery-Worthington the Third"
    const val ADDRESS_LONG = "Suite 1400, 12345 North Lamar Boulevard Frontage Road, Building C, Austin, TX 78753-1234"
    const val TRANSLATED_LABEL = "Bestellung aufgeben und sofort an die Küche senden"
    const val SEARCH_QUERY = "gluten free vegan chocolate fudge brownie with salted caramel"
    val MODIFIERS = listOf("No onions", "Extra cheese", "Gluten-free bun", "Sauce on the side")
}
```

`SRC/core/ui/UiTextExt.kt`
```kotlin
package com.noshitechinc.restaurant.core.ui

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.res.stringResource
import com.noshitechinc.restaurant.core.common.UiText

@Composable
@ReadOnlyComposable
fun UiText.asString(): String = when (this) {
    is UiText.Resource -> stringResource(id, *args.toTypedArray())
    is UiText.Dynamic -> value
}

fun UiText.asString(context: Context): String = when (this) {
    is UiText.Resource -> context.getString(id, *args.toTypedArray())
    is UiText.Dynamic -> value
}
```

- [ ] **Step 6: Strings** — add to `res/values/strings.xml` inside `<resources>`:

```xml
    <string name="home_subtitle">The foundation is ready. Features will appear here.</string>
    <string name="home_version">Version %1$s</string>
    <string name="env_dev">Development</string>
    <string name="env_staging">Staging</string>
    <string name="env_prod">Production</string>

    <string name="action_cancel">Cancel</string>
    <string name="action_confirm">Confirm</string>
    <string name="action_ok">OK</string>
    <string name="action_retry">Try again</string>
    <string name="action_done">Done</string>
    <string name="action_add">Add</string>
    <string name="action_remove">Remove</string>
    <string name="action_clear_search">Clear search</string>

    <string name="a11y_loading">Loading</string>
    <string name="a11y_clear_text">Clear text</string>
    <string name="a11y_increase">Increase quantity</string>
    <string name="a11y_decrease">Decrease quantity</string>
    <string name="a11y_backspace">Delete last digit</string>
    <string name="a11y_choose_time">Choose time</string>
    <string name="a11y_success">Success</string>
    <string name="a11y_selected">Selected</string>

    <string name="input_search_placeholder">Search</string>
    <string name="input_amount_placeholder">$0.00</string>
    <string name="address_street">Street address</string>
    <string name="address_unit">Apt, suite or unit (optional)</string>
    <string name="address_city">City</string>
    <string name="address_state">State</string>
    <string name="address_zip">ZIP code</string>
    <string name="error_address_street">Enter a street address</string>
    <string name="error_address_city">Enter a city</string>
    <string name="error_address_state">Use a 2-letter state code</string>
    <string name="error_address_zip">Enter a 5-digit ZIP code</string>
    <string name="time_picker_title">Select time</string>

    <string name="keypad_clear">Clear</string>
    <string name="keypad_double_zero">00</string>
    <string name="keypad_decimal">.</string>

    <string name="menu_item_unavailable">Unavailable</string>
    <string name="order_line_quantity">%1$d×</string>
    <plurals name="order_items_count">
        <item quantity="one">%d item</item>
        <item quantity="other">%d items</item>
    </plurals>
    <plurals name="kitchen_elapsed_minutes">
        <item quantity="one">%d min</item>
        <item quantity="other">%d min</item>
    </plurals>

    <string name="state_loading">Loading…</string>
    <string name="state_empty_title">Nothing here yet</string>
    <string name="state_empty_message">Items will appear here once they are added.</string>
    <string name="state_no_results_title">No results for “%1$s”</string>
    <string name="state_no_results_message">Try a different spelling or fewer words.</string>
    <string name="offline_blocking_title">You are offline</string>
    <string name="offline_blocking_message">Reconnect to the internet to continue. Orders cannot be sent while offline.</string>
    <string name="service_unavailable_message">We are having trouble reaching the restaurant service. Try again in a moment.</string>
```

- [ ] **Step 7: Run tests + build — expect PASS** (`./gradlew testDevDebugUnitTest assembleDevDebug`).

- [ ] **Step 8: Checkpoint** — list files.

---

### Task 2: Buttons (reference implementation for all components)

**Files:**
- Create: `SRC/core/designsystem/component/button/AppButton.kt`, `SRC/core/designsystem/component/button/AppIconButton.kt`

**Interfaces (Produces):**
- `enum class ButtonVariant { Primary, Secondary, Outline, Destructive }`, `enum class ButtonSize { Small, Medium, Large }`
- `@Composable fun AppButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, variant: ButtonVariant = ButtonVariant.Primary, size: ButtonSize = ButtonSize.Medium, enabled: Boolean = true, loading: Boolean = false, leadingIcon: ImageVector? = null, interactionSource: MutableInteractionSource? = null)` — `loading` shows a spinner and ignores clicks (FR-FOUND-019); test tag via caller `modifier`.
- `@Composable fun AppIconButton(icon: ImageVector, contentDescription: String, onClick: () -> Unit, modifier: Modifier = Modifier, variant: ButtonVariant = ButtonVariant.Outline, enabled: Boolean = true, interactionSource: MutableInteractionSource? = null)` — square, `AppTheme.sizes.minTouchTarget`.

- [ ] **Step 1: Implement `AppButton.kt`**

```kotlin
package com.noshitechinc.restaurant.core.designsystem.component.button

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.noshitechinc.restaurant.R
import com.noshitechinc.restaurant.core.designsystem.interaction.ForcedInteraction
import com.noshitechinc.restaurant.core.designsystem.interaction.focusRing
import com.noshitechinc.restaurant.core.designsystem.interaction.rememberInteractionVisuals
import com.noshitechinc.restaurant.core.designsystem.preview.ComponentPreviews
import com.noshitechinc.restaurant.core.designsystem.preview.PreviewData
import com.noshitechinc.restaurant.core.designsystem.preview.PreviewSurface
import com.noshitechinc.restaurant.core.designsystem.theme.AppTheme

enum class ButtonVariant { Primary, Secondary, Outline, Destructive }

enum class ButtonSize { Small, Medium, Large }

@Composable
fun AppButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    variant: ButtonVariant = ButtonVariant.Primary,
    size: ButtonSize = ButtonSize.Medium,
    enabled: Boolean = true,
    loading: Boolean = false,
    leadingIcon: ImageVector? = null,
    interactionSource: MutableInteractionSource? = null,
) {
    val source = interactionSource ?: remember { MutableInteractionSource() }
    val visuals = rememberInteractionVisuals(source)
    val colors = buttonColors(variant, enabled, visuals.pressed)
    val shape = RoundedCornerShape(AppTheme.radius.md)
    val loadingDescription = stringResource(R.string.a11y_loading)
    Surface(
        onClick = { if (!loading) onClick() },
        enabled = enabled,
        shape = shape,
        color = colors.container,
        contentColor = colors.content,
        border = colors.border?.let { BorderStroke(AppTheme.border.thin, it) },
        interactionSource = source,
        modifier = modifier
            .heightIn(min = size.minHeight())
            .focusRing(visuals.focused, AppTheme.colors.focusRing, AppTheme.border.focus, shape)
            .semantics { if (loading) stateDescription = loadingDescription },
    ) {
        Row(
            modifier = Modifier.padding(horizontal = size.horizontalPadding(), vertical = AppTheme.spacing.sm),
            horizontalArrangement = Arrangement.spacedBy(AppTheme.spacing.sm, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (loading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(AppTheme.sizes.progressSmall),
                    color = colors.content,
                    strokeWidth = AppTheme.border.thick,
                )
            } else if (leadingIcon != null) {
                Icon(imageVector = leadingIcon, contentDescription = null, modifier = Modifier.size(AppTheme.sizes.iconMd))
            }
            Text(
                text = text,
                style = size.textStyle(),
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Immutable
internal data class ButtonColors(val container: Color, val content: Color, val border: Color?)

@Composable
internal fun buttonColors(variant: ButtonVariant, enabled: Boolean, pressed: Boolean): ButtonColors {
    val c = AppTheme.colors
    if (!enabled) {
        return if (variant == ButtonVariant.Outline) {
            ButtonColors(Color.Transparent, c.textDisabled, c.outlineVariant)
        } else {
            ButtonColors(c.disabledContainer, c.textDisabled, null)
        }
    }
    return when (variant) {
        ButtonVariant.Primary -> ButtonColors(if (pressed) c.primaryPressed else c.primary, c.onPrimary, null)
        ButtonVariant.Secondary -> ButtonColors(if (pressed) c.secondaryPressed else c.secondary, c.onSecondary, null)
        ButtonVariant.Outline -> ButtonColors(if (pressed) c.surfacePressed else Color.Transparent, c.primary, c.outline)
        ButtonVariant.Destructive -> ButtonColors(if (pressed) c.destructivePressed else c.destructive, c.onDestructive, null)
    }
}

@Composable
private fun ButtonSize.minHeight(): Dp = when (this) {
    ButtonSize.Small -> AppTheme.sizes.buttonSmall
    ButtonSize.Medium -> AppTheme.sizes.buttonMedium
    ButtonSize.Large -> AppTheme.sizes.buttonLarge
}

@Composable
private fun ButtonSize.horizontalPadding(): Dp = when (this) {
    ButtonSize.Small -> AppTheme.spacing.md
    ButtonSize.Medium -> AppTheme.spacing.lg
    ButtonSize.Large -> AppTheme.spacing.xl
}

@Composable
private fun ButtonSize.textStyle(): TextStyle = when (this) {
    ButtonSize.Small -> AppTheme.typography.labelMedium
    ButtonSize.Medium, ButtonSize.Large -> AppTheme.typography.labelLarge
}

@ComponentPreviews
@Composable
private fun AppButtonVariantsPreview() {
    PreviewSurface {
        Column(verticalArrangement = Arrangement.spacedBy(AppTheme.spacing.sm)) {
            ButtonVariant.entries.forEach { variant ->
                AppButton(text = variant.name, onClick = {}, variant = variant, leadingIcon = Icons.Filled.Add)
                AppButton(text = "${variant.name} disabled", onClick = {}, variant = variant, enabled = false)
                AppButton(text = "${variant.name} loading", onClick = {}, variant = variant, loading = true)
            }
        }
    }
}

@ComponentPreviews
@Composable
private fun AppButtonPressedPreview() {
    PreviewSurface(forcedInteraction = ForcedInteraction.Pressed) {
        Column(verticalArrangement = Arrangement.spacedBy(AppTheme.spacing.sm)) {
            ButtonVariant.entries.forEach { AppButton(text = "${it.name} pressed", onClick = {}, variant = it) }
        }
    }
}

@ComponentPreviews
@Composable
private fun AppButtonFocusedPreview() {
    PreviewSurface(forcedInteraction = ForcedInteraction.Focused) {
        Column(verticalArrangement = Arrangement.spacedBy(AppTheme.spacing.sm)) {
            ButtonVariant.entries.forEach { AppButton(text = "${it.name} focused", onClick = {}, variant = it) }
        }
    }
}

@ComponentPreviews
@Composable
private fun AppButtonSizesAndLongLabelPreview() {
    PreviewSurface {
        Column(verticalArrangement = Arrangement.spacedBy(AppTheme.spacing.sm)) {
            ButtonSize.entries.forEach { AppButton(text = "Size ${it.name}", onClick = {}, size = it) }
            AppButton(text = PreviewData.TRANSLATED_LABEL, onClick = {}, size = ButtonSize.Large, modifier = Modifier.width(220.dp))
        }
    }
}
```

- [ ] **Step 2: Implement `AppIconButton.kt`** — reuse `buttonColors` (internal) and the same `Surface` pattern: `Surface(onClick, enabled, shape = RoundedCornerShape(AppTheme.radius.md), color/border from buttonColors, interactionSource)` with `Modifier.size(AppTheme.sizes.minTouchTarget).focusRing(...)` and a centered `Icon(icon, contentDescription, Modifier.size(AppTheme.sizes.iconMd))`. Previews: each variant × enabled/disabled, pressed, focused.

- [ ] **Step 3: Verify**

Run: `cd /home/bs01470/AndroidStudioProjects/resturant-app && ANDROID_HOME=$HOME/Android/Sdk ./gradlew assembleDevDebug --console=plain && scripts/ai-hooks/design-lint-check.sh app/src/main/java/com/noshitechinc/restaurant/core/designsystem/component/button; echo "lint=$?"`
Expected: `BUILD SUCCESSFUL`, no lint output, `lint=0`.

- [ ] **Step 4: Checkpoint** — list files.

---

### Task 3: Inputs — text, search, numeric, currency, phone, address, time

**Files:**
- Create in `SRC/core/designsystem/component/input/`: `AppTextField.kt`, `SearchField.kt`, `NumericField.kt`, `CurrencyField.kt`, `PhoneField.kt`, `AddressInput.kt`, `TimeField.kt`, `InputTransformations.kt`
- Create: `SRC/core/common/model/TimeOfDay.kt`
- Test: `TEST/core/designsystem/component/input/InputTransformationsTest.kt`

**Interfaces (Produces):**
- `@Composable fun AppTextField(value: String, onValueChange: (String) -> Unit, modifier: Modifier = Modifier, label: String? = null, placeholder: String? = null, helperText: String? = null, errorText: String? = null, enabled: Boolean = true, readOnly: Boolean = false, singleLine: Boolean = true, minLines: Int = 1, maxLines: Int = if (singleLine) 1 else 4, leadingIcon: ImageVector? = null, trailingContent: (@Composable () -> Unit)? = null, prefix: String? = null, keyboardOptions: KeyboardOptions = KeyboardOptions.Default, keyboardActions: KeyboardActions = KeyboardActions.Default, visualTransformation: VisualTransformation = VisualTransformation.None, interactionSource: MutableInteractionSource? = null)`
- `@Composable fun SearchField(query: String, onQueryChange: (String) -> Unit, modifier: Modifier = Modifier, placeholder: String = stringResource(R.string.input_search_placeholder), enabled: Boolean = true, onSearch: () -> Unit = {})`
- `@Composable fun NumericField(value: String, onValueChange: (String) -> Unit, label: String, modifier: Modifier = Modifier, maxDigits: Int = 6, helperText: String? = null, errorText: String? = null, enabled: Boolean = true)`
- `@Composable fun CurrencyField(cents: Long, onCentsChange: (Long) -> Unit, label: String, modifier: Modifier = Modifier, formatter: CurrencyFormatter = remember { CurrencyFormatter() }, helperText: String? = null, errorText: String? = null, enabled: Boolean = true)`
- `@Composable fun PhoneField(digits: String, onDigitsChange: (String) -> Unit, label: String, modifier: Modifier = Modifier, errorText: String? = null, enabled: Boolean = true)`
- `@Composable fun AddressInput(address: PostalAddress, onAddressChange: (PostalAddress) -> Unit, modifier: Modifier = Modifier, invalidFields: Set<AddressField> = emptySet(), enabled: Boolean = true)`
- `data class TimeOfDay(val hour: Int, val minute: Int)` (0–23, 0–59; `init` requires ranges)
- `@Composable fun TimeField(time: TimeOfDay?, onTimeChange: (TimeOfDay) -> Unit, label: String, modifier: Modifier = Modifier, errorText: String? = null, enabled: Boolean = true)`
- `class CurrencyVisualTransformation(formatter: CurrencyFormatter) : VisualTransformation`, `object UsPhoneVisualTransformation : VisualTransformation`

- [ ] **Step 1: Write failing test**

`TEST/core/designsystem/component/input/InputTransformationsTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem.component.input

import androidx.compose.ui.text.AnnotatedString
import com.noshitechinc.restaurant.core.common.format.CurrencyFormatter
import kotlin.test.Test
import kotlin.test.assertEquals

class InputTransformationsTest {
    @Test
    fun `currency transformation shows formatted amount with cursor at end`() {
        val transformed = CurrencyVisualTransformation(CurrencyFormatter()).filter(AnnotatedString("123456"))
        assertEquals("$1,234.56", transformed.text.text)
        assertEquals(transformed.text.length, transformed.offsetMapping.originalToTransformed(3))
        assertEquals(6, transformed.offsetMapping.transformedToOriginal(2))
    }

    @Test
    fun `phone transformation formats digits and maps offsets`() {
        val transformed = UsPhoneVisualTransformation.filter(AnnotatedString("5551234567"))
        assertEquals("(555) 123-4567", transformed.text.text)
        assertEquals(14, transformed.offsetMapping.originalToTransformed(10))
        assertEquals(3, transformed.offsetMapping.transformedToOriginal(5))
    }
}
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement `InputTransformations.kt`**

```kotlin
package com.noshitechinc.restaurant.core.designsystem.component.input

import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.input.OffsetMapping
import androidx.compose.ui.text.input.TransformedText
import androidx.compose.ui.text.input.VisualTransformation
import com.noshitechinc.restaurant.core.common.format.CurrencyFormatter
import com.noshitechinc.restaurant.core.common.format.UsPhoneFormatter

class CurrencyVisualTransformation(private val formatter: CurrencyFormatter) : VisualTransformation {
    override fun filter(text: AnnotatedString): TransformedText {
        val original = text.text
        val formatted = if (original.isEmpty()) "" else formatter.format(CurrencyFormatter.centsFromDigits(original))
        return TransformedText(
            AnnotatedString(formatted),
            object : OffsetMapping {
                override fun originalToTransformed(offset: Int): Int = formatted.length
                override fun transformedToOriginal(offset: Int): Int = original.length
            },
        )
    }
}

object UsPhoneVisualTransformation : VisualTransformation {
    override fun filter(text: AnnotatedString): TransformedText {
        val digits = UsPhoneFormatter.digitsOnly(text.text)
        return TransformedText(
            AnnotatedString(UsPhoneFormatter.format(digits)),
            object : OffsetMapping {
                override fun originalToTransformed(offset: Int): Int = UsPhoneFormatter.originalToTransformed(offset, digits.length)
                override fun transformedToOriginal(offset: Int): Int = UsPhoneFormatter.transformedToOriginal(offset, digits.length)
            },
        )
    }
}
```

`SRC/core/common/model/TimeOfDay.kt`
```kotlin
package com.noshitechinc.restaurant.core.common.model

data class TimeOfDay(val hour: Int, val minute: Int) {
    init {
        require(hour in 0..MAX_HOUR) { "hour out of range: $hour" }
        require(minute in 0..MAX_MINUTE) { "minute out of range: $minute" }
    }

    private companion object {
        const val MAX_HOUR = 23
        const val MAX_MINUTE = 59
    }
}
```

- [ ] **Step 4: Implement `AppTextField.kt`** using Material3 `OutlinedTextField`:
  - `shape = RoundedCornerShape(AppTheme.radius.md)`, `textStyle = AppTheme.typography.bodyLarge`, `modifier.fillMaxWidth().heightIn(min = AppTheme.sizes.inputHeight)` applied by the caller's modifier chain (`modifier.heightIn(...)` inside).
  - `label = label?.let { { Text(it, maxLines = 1, overflow = TextOverflow.Ellipsis) } }`, `placeholder` likewise, `prefix = prefix?.let { { Text(it) } }`, `leadingIcon` → `Icon(..., contentDescription = null)`, `trailingIcon = trailingContent`.
  - `isError = errorText != null`; `supportingText` shows `errorText` (color `AppTheme.colors.destructive`) else `helperText` (color `textSecondary`), `maxLines = 3`.
  - Colors: `OutlinedTextFieldDefaults.colors(focusedBorderColor = primary, unfocusedBorderColor = outline, disabledBorderColor = outlineVariant, errorBorderColor = destructive, focusedLabelColor = primary, errorLabelColor = destructive, cursorColor = primary, focusedContainerColor = surface, unfocusedContainerColor = surface, disabledContainerColor = disabledContainer, disabledTextColor = textDisabled)`; when `LocalForcedInteraction.current == ForcedInteraction.Focused`, pass `unfocusedBorderColor = primary` and `unfocusedLabelColor = primary` so the focused look renders in static previews.
  - Previews: empty with label, filled, placeholder, helper, error, disabled, read-only, focused (`ForcedInteraction.Focused`), multiline with `PreviewData.ADDRESS_LONG`, long label `PreviewData.TRANSLATED_LABEL`.

- [ ] **Step 5: Implement specialized inputs** (each file has previews: empty, filled, error, disabled, focused, long content):
  - `SearchField`: `AppTextField(label = null, placeholder = placeholder, leadingIcon = Icons.Filled.Search, trailingContent = if (query.isNotEmpty()) { { IconButton(onClick = { onQueryChange("") }) { Icon(Icons.Filled.Close, stringResource(R.string.a11y_clear_text)) } } } else null, keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search), keyboardActions = KeyboardActions(onSearch = { onSearch() }))`. Preview with `PreviewData.SEARCH_QUERY`.
  - `NumericField`: `onValueChange = { onValueChange(it.filter(Char::isDigit).take(maxDigits)) }`, `KeyboardOptions(keyboardType = KeyboardType.Number)`, `textStyle` tabular via `AppTheme.typography.priceMedium` is not required — keep bodyLarge.
  - `CurrencyField`: raw text `if (cents == 0L) "" else cents.toString()`; `onValueChange = { onCentsChange(CurrencyFormatter.centsFromDigits(it)) }`; `visualTransformation = remember(formatter) { CurrencyVisualTransformation(formatter) }`; placeholder `stringResource(R.string.input_amount_placeholder)`; `KeyboardType.Number`. Preview with `cents = 1_234_567_890L` for long amounts.
  - `PhoneField`: `prefix = MarketConfig.UnitedStates.phoneCountryCode + " "` is data, not copy — build it as `"${MarketConfig.UnitedStates.phoneCountryCode} "` from the config object (no literal text); `onValueChange = { onDigitsChange(UsPhoneFormatter.digitsOnly(it)) }`; `visualTransformation = UsPhoneVisualTransformation`; `KeyboardType.Phone`.
  - `AddressInput`: fields street, unit, city, state (`it.uppercase().take(2)`), zip (`it.filter { c -> c.isDigit() || c == '-' }.take(10)`); errors from `invalidFields` mapped to `R.string.error_address_*`; layout with `rememberAdaptiveInfo()`: when `usesTwoPane` → street full width, then `Row` of unit (weight 1), and a `Row` of city (weight 2), state (weight 1), zip (weight 1.4) with `Arrangement.spacedBy(AppTheme.spacing.md)`; compact → all stacked. Street uses `singleLine = false, maxLines = 3`. Previews: empty, filled with `PreviewData.ADDRESS_LONG` as street, all fields invalid, disabled; tablet widths via `@ComponentPreviews`.
  - `TimeField`: read-only `AppTextField` showing `DateFormat.getTimeFormat(context).format(calendarFor(time))` (use `java.util.Calendar`; empty string when `time == null`), trailing `IconButton` with `Icons.Filled.Schedule` and `stringResource(R.string.a11y_choose_time)`; tapping the icon or the field (`Modifier.clickable` on an overlay `Box` matching the field bounds) opens an `AlertDialog` with Material3 `TimePicker(rememberTimePickerState(initialHour, initialMinute, is24Hour = DateFormat.is24HourFormat(context)))`, title `R.string.time_picker_title`, confirm `R.string.action_ok` → `onTimeChange(TimeOfDay(state.hour, state.minute))`, dismiss `R.string.action_cancel`. Annotate with `@OptIn(ExperimentalMaterial3Api::class)`. Previews: empty, 09:30, error, disabled.

- [ ] **Step 6: Run tests, build, lint — expect PASS**

Run: `cd /home/bs01470/AndroidStudioProjects/resturant-app && ANDROID_HOME=$HOME/Android/Sdk ./gradlew testDevDebugUnitTest assembleDevDebug --console=plain && scripts/ai-hooks/design-lint-check.sh app/src/main/java/com/noshitechinc/restaurant/core/designsystem/component/input; echo "lint=$?"`
Expected: `BUILD SUCCESSFUL`, `lint=0`.

- [ ] **Step 7: Checkpoint** — list files.

---

### Task 4: Selection — switch, segmented control, filter chips, status badge

**Files:**
- Create in `SRC/core/designsystem/component/selection/`: `AppSwitch.kt`, `SegmentedControl.kt`, `FilterChipGroup.kt`, `StatusBadge.kt`

**Interfaces (Produces):**
- `@Composable fun AppSwitch(checked: Boolean, onCheckedChange: (Boolean) -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true, interactionSource: MutableInteractionSource? = null)` — Material3 `Switch` with `SwitchDefaults.colors(checkedTrackColor = primary, checkedThumbColor = onPrimary, uncheckedTrackColor = surfaceVariant, uncheckedBorderColor = outline, uncheckedThumbColor = textSecondary, disabled* = disabledContainer/textDisabled)`, wrapped in `Box(Modifier.sizeIn(minWidth = minTouchTarget, minHeight = minTouchTarget).focusRing(...))`.
- `@Composable fun SegmentedControl(options: List<String>, selectedIndex: Int, onSelect: (Int) -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true)` — `SingleChoiceSegmentedButtonRow` + `SegmentedButton(shape = SegmentedButtonDefaults.itemShape(index, options.size), selected, onClick = { onSelect(index) }, enabled, colors = SegmentedButtonDefaults.colors(activeContainerColor = primaryContainer, activeContentColor = onPrimaryContainer, inactiveContainerColor = surface, inactiveContentColor = textPrimary, activeBorderColor = primary, inactiveBorderColor = outline), modifier = Modifier.heightIn(min = minTouchTarget))`, label `Text(maxLines = 2, overflow = Ellipsis, textAlign = Center)`. `@OptIn(ExperimentalMaterial3Api::class)` if required by the BOM.
- `data class FilterOption(val id: String, val label: String, val count: Int? = null)`; `@Composable fun FilterChipGroup(options: List<FilterOption>, selectedIds: Set<String>, onToggle: (String) -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true)` — `FlowRow(horizontalArrangement = spacedBy(sm), verticalArrangement = spacedBy(sm))` of Material3 `FilterChip(selected, onClick = { onToggle(id) }, label = { Text(label + count suffix, maxLines = 1, overflow = Ellipsis) }, leadingIcon = check icon when selected, colors = FilterChipDefaults.filterChipColors(selectedContainerColor = primaryContainer, selectedLabelColor = onPrimaryContainer, containerColor = surface, labelColor = textPrimary), modifier = Modifier.heightIn(min = minTouchTarget))`. Count suffix uses a new string resource `<string name="filter_option_with_count">%1$s · %2$d</string>` (add to `strings.xml`): `count?.let { stringResource(R.string.filter_option_with_count, label, it) } ?: label`. `@OptIn(ExperimentalLayoutApi::class)`.
- `@Composable fun StatusBadge(text: String, tone: StatusTone, modifier: Modifier = Modifier, icon: ImageVector? = null)` — `Surface(shape = RoundedCornerShape(AppTheme.radius.pill), color = tone.containerColor(), contentColor = tone.contentColor())`, `Row(Modifier.heightIn(min = badgeMinHeight).padding(horizontal = md, vertical = xs))`, text `labelMedium`, `maxLines = 1`, `overflow = Ellipsis`.

- [ ] **Step 1: Implement all four files following Task 2's structure** (tokens only, `rememberInteractionVisuals` for switch focus, previews at bottom).

- [ ] **Step 2: Previews required**
  - `AppSwitch`: on, off, disabled on, disabled off, focused.
  - `SegmentedControl`: 2 and 3 options, each selected index, disabled, long option labels (`PreviewData.TRANSLATED_LABEL`) at font 2.0 (via `@ComponentPreviews`).
  - `FilterChipGroup`: none selected, some selected, many options wrapping, disabled, long label.
  - `StatusBadge`: every `StatusTone` with and without icon, long text constrained to `Modifier.width(140.dp)` in preview.

- [ ] **Step 3: Build + lint — expect PASS** (same command as Task 3 Step 6, path `component/selection`).

- [ ] **Step 4: Checkpoint** — list files.

---

### Task 5: Quantity stepper and numeric keypad

**Files:**
- Create in `SRC/core/designsystem/component/quantity/`: `QuantityStepper.kt`, `NumericKeypad.kt`, `KeypadReducer.kt`
- Test: `TEST/core/designsystem/component/quantity/KeypadReducerTest.kt`

**Interfaces (Produces):**
- `@Composable fun QuantityStepper(quantity: Int, onQuantityChange: (Int) -> Unit, modifier: Modifier = Modifier, min: Int = 0, max: Int = 99, enabled: Boolean = true)` — test tags `QuantityStepperTags.DECREMENT = "stepper_decrement"`, `INCREMENT = "stepper_increment"`, `VALUE = "stepper_value"` (object `QuantityStepperTags`).
- `enum class KeypadMode { Integer, Decimal, Currency, Pin }`
- `sealed interface KeypadKey { data class Digit(val value: Int) : KeypadKey; data object DoubleZero; data object Decimal; data object Backspace; data object Clear }`
- `object KeypadReducer { fun reduce(current: String, key: KeypadKey, mode: KeypadMode, maxLength: Int = DEFAULT_MAX_LENGTH): String; const val DEFAULT_MAX_LENGTH = 9 }`
- `@Composable fun NumericKeypad(onKey: (KeypadKey) -> Unit, modifier: Modifier = Modifier, mode: KeypadMode = KeypadMode.Integer, enabled: Boolean = true)` — test tags `NumericKeypadTags.digit(n) = "keypad_key_$n"`, `BACKSPACE = "keypad_backspace"`, `DECIMAL = "keypad_decimal"`, `DOUBLE_ZERO = "keypad_double_zero"`, `CLEAR = "keypad_clear"`.

- [ ] **Step 1: Write failing reducer test**

`TEST/core/designsystem/component/quantity/KeypadReducerTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem.component.quantity

import kotlin.test.Test
import kotlin.test.assertEquals

class KeypadReducerTest {
    private fun type(mode: KeypadMode, vararg keys: KeypadKey, start: String = ""): String =
        keys.fold(start) { acc, key -> KeypadReducer.reduce(acc, key, mode) }

    private fun d(n: Int) = KeypadKey.Digit(n)

    @Test
    fun `integer mode drops leading zero and respects max length`() {
        assertEquals("5", type(KeypadMode.Integer, d(0), d(5)))
        assertEquals("123456789", type(KeypadMode.Integer, *Array(12) { d(it % 9 + 1) }))
    }

    @Test
    fun `pin mode keeps leading zeros`() {
        assertEquals("0012", type(KeypadMode.Pin, d(0), d(0), d(1), d(2)))
    }

    @Test
    fun `decimal mode allows one separator and two fraction digits`() {
        assertEquals("0.", type(KeypadMode.Decimal, KeypadKey.Decimal))
        assertEquals("12.34", type(KeypadMode.Decimal, d(1), d(2), KeypadKey.Decimal, KeypadKey.Decimal, d(3), d(4), d(5)))
    }

    @Test
    fun `currency mode appends double zero and trims leading zeros`() {
        assertEquals("500", type(KeypadMode.Currency, d(0), d(5), KeypadKey.DoubleZero))
        assertEquals("", type(KeypadMode.Currency, KeypadKey.DoubleZero))
    }

    @Test
    fun `backspace and clear`() {
        assertEquals("12", type(KeypadMode.Integer, d(1), d(2), d(3), KeypadKey.Backspace))
        assertEquals("", type(KeypadMode.Integer, d(1), d(2), KeypadKey.Clear))
        assertEquals("", type(KeypadMode.Integer, KeypadKey.Backspace))
    }

    @Test
    fun `keys not valid for a mode are ignored`() {
        assertEquals("1", type(KeypadMode.Integer, d(1), KeypadKey.Decimal))
        assertEquals("1", type(KeypadMode.Pin, d(1), KeypadKey.DoubleZero))
    }
}
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement `KeypadReducer.kt`**

```kotlin
package com.noshitechinc.restaurant.core.designsystem.component.quantity

enum class KeypadMode { Integer, Decimal, Currency, Pin }

sealed interface KeypadKey {
    data class Digit(val value: Int) : KeypadKey {
        init {
            require(value in 0..9) { "digit out of range: $value" }
        }
    }

    data object DoubleZero : KeypadKey
    data object Decimal : KeypadKey
    data object Backspace : KeypadKey
    data object Clear : KeypadKey
}

object KeypadReducer {
    const val DEFAULT_MAX_LENGTH = 9
    private const val DECIMAL_SEPARATOR = '.'
    private const val MAX_FRACTION_DIGITS = 2

    fun reduce(current: String, key: KeypadKey, mode: KeypadMode, maxLength: Int = DEFAULT_MAX_LENGTH): String = when (key) {
        KeypadKey.Clear -> ""
        KeypadKey.Backspace -> current.dropLast(1)
        is KeypadKey.Digit -> appendDigits(current, key.value.toString(), mode, maxLength)
        KeypadKey.DoubleZero -> if (mode == KeypadMode.Currency) appendDigits(current, "00", mode, maxLength) else current
        KeypadKey.Decimal -> when {
            mode != KeypadMode.Decimal -> current
            DECIMAL_SEPARATOR in current -> current
            current.isEmpty() -> "0$DECIMAL_SEPARATOR"
            else -> current + DECIMAL_SEPARATOR
        }
    }

    private fun appendDigits(current: String, digits: String, mode: KeypadMode, maxLength: Int): String {
        if (mode == KeypadMode.Decimal && DECIMAL_SEPARATOR in current) {
            val fraction = current.substringAfter(DECIMAL_SEPARATOR)
            val room = MAX_FRACTION_DIGITS - fraction.length
            return if (room <= 0) current else current + digits.take(room)
        }
        val combined = (current + digits).let { if (mode == KeypadMode.Pin) it else it.trimStart('0') }
        return combined.take(maxLength)
    }
}
```

- [ ] **Step 4: Implement `QuantityStepper.kt`** — `Row(verticalAlignment = CenterVertically, horizontalArrangement = spacedBy(sm))`: `AppIconButton(Icons.Filled.Remove, stringResource(R.string.a11y_decrease), onClick = { onQuantityChange(quantity - 1) }, enabled = enabled && quantity > min, modifier = Modifier.testTag(QuantityStepperTags.DECREMENT))`; value `Text(quantity.toString(), style = AppTheme.typography.priceMedium, textAlign = Center, modifier = Modifier.widthIn(min = AppTheme.sizes.stepperValueMinWidth).testTag(QuantityStepperTags.VALUE))`; increment likewise with `Icons.Filled.Add`, `quantity < max`. Previews: at min, middle, at max, disabled, value 999 (long), font 2.0.

- [ ] **Step 5: Implement `NumericKeypad.kt`** — `Column(modifier.widthIn(max = AppTheme.sizes.keypadMaxWidth), verticalArrangement = spacedBy(sm))` of 4 rows × 3 keys; each key is a `KeypadButton` (private) built like `AppButton` Outline style: `Surface(onClick, enabled, shape = RoundedCornerShape(radius.md), border = outline, color = if (pressed) surfacePressed else surface)` with `Modifier.weight(1f).heightIn(min = AppTheme.sizes.keypadKey).testTag(...)`, label `AppTheme.typography.headlineSmall`. Rows: `1 2 3`, `4 5 6`, `7 8 9`, `[left] 0 [Backspace]`, where left = `Decimal` (Decimal mode, label `R.string.keypad_decimal`), `DoubleZero` (Currency, `R.string.keypad_double_zero`), `Clear` (Integer/Pin, `R.string.keypad_clear`). Backspace shows `Icons.AutoMirrored.Filled.Backspace` with `R.string.a11y_backspace`. Digit labels come from `value.toString()`. Previews: each mode, disabled, pressed (`ForcedInteraction.Pressed`), a preview combining `Text(value, style = numericDisplay)` + keypad with `remember { mutableStateOf("") }` wired through `KeypadReducer`.

- [ ] **Step 6: Run tests + build + lint — expect PASS** (Task 3 Step 6 command, path `component/quantity`).

- [ ] **Step 7: Checkpoint** — list files.

---

### Task 6: Cards — menu item, order line, order, kitchen ticket

**Files:**
- Create in `SRC/core/designsystem/component/card/`: `AppCard.kt`, `MenuItemCard.kt`, `OrderLineCard.kt`, `OrderCard.kt`, `KitchenTicketCard.kt`, `ElapsedTone.kt`
- Test: `TEST/core/designsystem/component/card/ElapsedToneTest.kt`

**Interfaces (Produces):**
- `@Composable fun AppCard(modifier: Modifier = Modifier, onClick: (() -> Unit)? = null, selected: Boolean = false, enabled: Boolean = true, content: @Composable ColumnScope.() -> Unit)` — `Surface` with `RoundedCornerShape(radius.lg)`, `color = surface`, border `outline` (thin) or `primary` (thick) when selected, pressed → `surfacePressed`, focus ring; content padded `spacing.lg`, `Arrangement.spacedBy(spacing.sm)`.
- `@Composable fun MenuItemCard(name: String, price: String, modifier: Modifier = Modifier, description: String? = null, imageUrl: String? = null, isAvailable: Boolean = true, onClick: (() -> Unit)? = null, onAdd: (() -> Unit)? = null)`
- `@Composable fun OrderLineCard(name: String, quantity: Int, lineTotal: String, modifier: Modifier = Modifier, modifiers: List<String> = emptyList(), note: String? = null, onQuantityChange: ((Int) -> Unit)? = null, onRemove: (() -> Unit)? = null)`
- `@Composable fun OrderCard(orderNumber: String, title: String, statusLabel: String, statusTone: StatusTone, total: String, itemCount: Int, elapsedMinutes: Int, modifier: Modifier = Modifier, selected: Boolean = false, onClick: (() -> Unit)? = null)`
- `data class KitchenTicketItem(val quantity: Int, val name: String, val modifiers: List<String> = emptyList(), val isDone: Boolean = false)`
- `enum class ElapsedTone { OnTime, Warning, Overdue; companion object { fun of(elapsedMinutes: Int, warningAfterMinutes: Int, overdueAfterMinutes: Int): ElapsedTone } }`
- `@Composable fun KitchenTicketCard(ticketNumber: String, title: String, statusLabel: String, statusTone: StatusTone, elapsedMinutes: Int, items: List<KitchenTicketItem>, modifier: Modifier = Modifier, warningAfterMinutes: Int = 10, overdueAfterMinutes: Int = 20, onItemToggle: ((Int) -> Unit)? = null, actionLabel: String? = null, onAction: (() -> Unit)? = null, actionLoading: Boolean = false)`

- [ ] **Step 1: Write failing test**

`TEST/core/designsystem/component/card/ElapsedToneTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem.component.card

import kotlin.test.Test
import kotlin.test.assertEquals

class ElapsedToneTest {
    @Test
    fun `tone changes at thresholds`() {
        assertEquals(ElapsedTone.OnTime, ElapsedTone.of(9, warningAfterMinutes = 10, overdueAfterMinutes = 20))
        assertEquals(ElapsedTone.Warning, ElapsedTone.of(10, warningAfterMinutes = 10, overdueAfterMinutes = 20))
        assertEquals(ElapsedTone.Warning, ElapsedTone.of(19, warningAfterMinutes = 10, overdueAfterMinutes = 20))
        assertEquals(ElapsedTone.Overdue, ElapsedTone.of(20, warningAfterMinutes = 10, overdueAfterMinutes = 20))
    }
}
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement `ElapsedTone.kt`**

```kotlin
package com.noshitechinc.restaurant.core.designsystem.component.card

import com.noshitechinc.restaurant.core.designsystem.theme.StatusTone

enum class ElapsedTone {
    OnTime,
    Warning,
    Overdue,
    ;

    val statusTone: StatusTone
        get() = when (this) {
            OnTime -> StatusTone.Neutral
            Warning -> StatusTone.Warning
            Overdue -> StatusTone.Danger
        }

    companion object {
        fun of(elapsedMinutes: Int, warningAfterMinutes: Int, overdueAfterMinutes: Int): ElapsedTone = when {
            elapsedMinutes >= overdueAfterMinutes -> Overdue
            elapsedMinutes >= warningAfterMinutes -> Warning
            else -> OnTime
        }
    }
}
```

- [ ] **Step 4: Implement cards** (all built on `AppCard`; long-content rules enforced):
  - `MenuItemCard`: `Row(spacedBy(md))` → image `AsyncImage(model = imageUrl, contentDescription = null, contentScale = Crop, modifier = Modifier.size(cardImage).clip(RoundedCornerShape(radius.md)).background(surfaceVariant))` only when `imageUrl != null`; `Column(Modifier.weight(1f))` with name (`titleMedium`, `maxLines = 2`, ellipsis) and description (`bodyMedium`, `textSecondary`, `maxLines = 2`); `Column(horizontalAlignment = End)` with price (`priceMedium`, `softWrap = false`, no maxLines truncation) and, when `onAdd != null`, `AppIconButton(Icons.Filled.Add, stringResource(R.string.action_add), onAdd, variant = Primary, enabled = isAvailable)`. When `!isAvailable`: `Modifier.alpha(0.5f)` on text column is not allowed as a literal — use `AppTheme.colors.textDisabled` for text instead, and show `StatusBadge(stringResource(R.string.menu_item_unavailable), StatusTone.Neutral)`. Previews: short, `PreviewData.LONG_NAME` + `LONG_DESCRIPTION` + `LONG_PRICE`, no image, unavailable, pressed, focused, grid of 4 at tablet width.
  - `OrderLineCard`: top `Row`: quantity label `stringResource(R.string.order_line_quantity, quantity)` (`labelLarge`), name (`weight(1f)`, `maxLines = 2`), line total (`priceMedium`, no truncation); modifiers joined with `", "` via `joinToString` (`bodySmall`, `textSecondary`, `maxLines = 2`); note (`bodySmall`, italic via `FontStyle.Italic`, `maxLines = 3`); bottom `Row` with `QuantityStepper(min = 1)` when `onQuantityChange != null` and `AppButton(stringResource(R.string.action_remove), variant = Outline, size = Small)` when `onRemove != null`. Previews: simple, with modifiers `PreviewData.MODIFIERS` and a long note, long name + long price, editable, read-only.
  - `OrderCard`: header `Row` (order number `titleMedium` `weight(1f)` `maxLines = 1`, `StatusBadge(statusLabel, statusTone)`), title (`bodyLarge`, `maxLines = 1`, ellipsis), footer `Row` (`pluralStringResource(R.plurals.order_items_count, itemCount, itemCount)` + `pluralStringResource(R.plurals.kitchen_elapsed_minutes, elapsedMinutes, elapsedMinutes)` in `weight(1f)` with `bodySmall`; total `priceMedium`). Previews: each `StatusTone`, selected, `PreviewData.CUSTOMER_LONG` title, long total, pressed.
  - `KitchenTicketCard`: header strip `Surface(color = ElapsedTone.of(...).statusTone.containerColor())` containing ticket number, title (`maxLines = 1`), elapsed minutes (plural) and `StatusBadge`; items list: each row `Row` with `Checkbox`-less toggle (`Modifier.clickable(enabled = onItemToggle != null) { onItemToggle?.invoke(index) }`, min height `minTouchTarget`), quantity `labelLarge`, name `bodyLarge` (`TextDecoration.LineThrough` + `textDisabled` when `isDone`, `maxLines = 2`), modifiers below (`bodySmall`, `maxLines = 2`); optional footer `AppButton(actionLabel, onAction, size = Large, loading = actionLoading, modifier = Modifier.fillMaxWidth())`. Previews: on time, warning, overdue, many items with long names and modifiers, some done, action loading.

- [ ] **Step 5: Run tests + build + lint — expect PASS** (path `component/card`).

- [ ] **Step 6: Checkpoint** — list files.

---

### Task 7: Dialogs and rows

**Files:**
- Create in `SRC/core/designsystem/component/dialog/`: `AppModal.kt`, `ConfirmationDialog.kt`, `SuccessDialog.kt`
- Create in `SRC/core/designsystem/component/row/`: `ListRow.kt`, `SettingsRow.kt`

**Interfaces (Produces):**
- `@Composable fun AppModalLayout(title: String, modifier: Modifier = Modifier, actions: @Composable RowScope.() -> Unit = {}, content: @Composable ColumnScope.() -> Unit)` — stateless card: `Surface(shape = RoundedCornerShape(radius.xl), color = surface)` with `Modifier.widthIn(max = AppTheme.sizes.dialogMaxWidth)`; title `headlineSmall`; content in `Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()))`; actions in `FlowRow(horizontalArrangement = spacedBy(sm, Alignment.End))`.
- `@Composable fun AppModal(title: String, onDismissRequest: () -> Unit, modifier: Modifier = Modifier, dismissEnabled: Boolean = true, actions: @Composable RowScope.() -> Unit = {}, content: @Composable ColumnScope.() -> Unit)` — `Dialog(onDismissRequest = { if (dismissEnabled) onDismissRequest() }, properties = DialogProperties(usePlatformDefaultWidth = false, dismissOnBackPress = dismissEnabled, dismissOnClickOutside = dismissEnabled))` wrapping `Box(Modifier.fillMaxSize().padding(spacing.xl), contentAlignment = Center) { AppModalLayout(...) }`.
- `@Composable fun ConfirmationDialogLayout(title: String, message: String, confirmLabel: String, onConfirm: () -> Unit, onDismiss: () -> Unit, modifier: Modifier = Modifier, dismissLabel: String = stringResource(R.string.action_cancel), destructive: Boolean = false, confirmLoading: Boolean = false)` and `@Composable fun ConfirmationDialog(...same params...)` which hosts the layout in `AppModal(dismissEnabled = !confirmLoading)`. Confirm button: `AppButton(variant = if (destructive) Destructive else Primary, loading = confirmLoading)`; dismiss: `AppButton(variant = Outline, enabled = !confirmLoading)`.
- `@Composable fun SuccessDialogLayout(title: String, message: String, actionLabel: String, onAction: () -> Unit, modifier: Modifier = Modifier)` and `@Composable fun SuccessDialog(title, message, actionLabel, onAction, onDismissRequest: () -> Unit = onAction, modifier)` — centered `Icons.Filled.CheckCircle` (`size = illustration`, tint `success`, inside `successContainer` circle, `contentDescription = stringResource(R.string.a11y_success)`), title, message, full-width primary action.
- `@Composable fun ListRow(title: String, modifier: Modifier = Modifier, subtitle: String? = null, leadingIcon: ImageVector? = null, trailingText: String? = null, trailingContent: (@Composable () -> Unit)? = null, showChevron: Boolean = false, enabled: Boolean = true, destructive: Boolean = false, onClick: (() -> Unit)? = null, interactionSource: MutableInteractionSource? = null)` — `Row(Modifier.heightIn(min = listRowMinHeight).clickable(enabled && onClick != null, interactionSource = source, indication = ripple()) { onClick?.invoke() }.background(if (pressed) surfacePressed else Transparent).focusRing(...).padding(horizontal = lg, vertical = md))`; title `bodyLarge` (`destructive` → `AppTheme.colors.destructive`, disabled → `textDisabled`) `maxLines = 2`; subtitle `bodySmall` `maxLines = 2`; trailing text never truncated; chevron `Icons.AutoMirrored.Filled.KeyboardArrowRight`.
- In `SettingsRow.kt`: `SettingsNavigationRow(title: String, onClick: () -> Unit, modifier: Modifier = Modifier, subtitle: String? = null, value: String? = null, enabled: Boolean = true)`, `SettingsSwitchRow(title: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit, modifier: Modifier = Modifier, subtitle: String? = null, enabled: Boolean = true)` (whole row toggles; `AppSwitch` trailing; `Modifier.toggleable` semantics), `SettingsValueRow(title: String, value: String, modifier: Modifier = Modifier)`, `SettingsDestructiveRow(title: String, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true)` — all delegate to `ListRow`.

- [ ] **Step 1: Implement the five files.**

- [ ] **Step 2: Previews required** (previews target the `*Layout` composables because `Dialog` windows do not render in static previews):
  - `AppModalLayout`: short content; long scrolling content (`PreviewData.LONG_DESCRIPTION` × 6) at font 2.0; with 3 actions wrapping.
  - `ConfirmationDialogLayout`: normal, destructive, confirm loading, long title/message, `PreviewData.TRANSLATED_LABEL` as confirm label.
  - `SuccessDialogLayout`: normal and long message.
  - `ListRow`: title only, with subtitle, leading icon, trailing text (`PreviewData.LONG_PRICE`), chevron, disabled, destructive, pressed, focused, long title.
  - `SettingsRow` variants: each, with long titles and values, disabled.

- [ ] **Step 3: Build + lint — expect PASS** (paths `component/dialog`, `component/row`).

- [ ] **Step 4: Checkpoint** — list files.

---

### Task 8: Loading, empty, error, offline states and `AppScaffold`

**Files:**
- Create in `SRC/core/designsystem/state/`: `StatusMessage.kt`, `LoadingState.kt`, `SkeletonList.kt`, `EmptyState.kt`
- Create in `SRC/core/ui/state/`: `ErrorState.kt`, `OfflineBlockingState.kt`, `LoadStateContent.kt`
- Create: `SRC/core/ui/ObserveEffects.kt`, `SRC/core/ui/AppScaffold.kt`

**Interfaces (Produces):**
- `@Composable fun StatusMessage(icon: ImageVector, title: String, modifier: Modifier = Modifier, message: String? = null, iconTint: Color = AppTheme.colors.textSecondary, action: (@Composable () -> Unit)? = null)` — centered, `widthIn(max = formMaxWidth)`, `verticalScroll` so font 2.0 never clips; title `titleLarge` centered; message `bodyLarge` `textSecondary` centered.
- `@Composable fun LoadingState(modifier: Modifier = Modifier, message: String? = stringResource(R.string.state_loading))`, `@Composable fun AppCircularProgress(modifier: Modifier = Modifier)`, `@Composable fun AppLinearProgress(modifier: Modifier = Modifier, progress: Float? = null)` (null → indeterminate).
- `@Composable fun SkeletonList(modifier: Modifier = Modifier, rows: Int = 6)` — rows of rounded `surfaceVariant` placeholders animated with `rememberInfiniteTransition` alpha; `semantics { contentDescription = stringResource(R.string.a11y_loading) }` on the container.
- `@Composable fun EmptyState(modifier: Modifier = Modifier, title: String = stringResource(R.string.state_empty_title), message: String? = stringResource(R.string.state_empty_message), icon: ImageVector = Icons.Outlined.Inbox, actionLabel: String? = null, onAction: (() -> Unit)? = null)`
- `@Composable fun NoSearchResultsState(query: String, modifier: Modifier = Modifier, onClearSearch: (() -> Unit)? = null)` — title `stringResource(R.string.state_no_results_title, query)` limited to 3 lines, icon `Icons.Outlined.SearchOff`, action `R.string.action_clear_search`.
- `@Composable fun ErrorState(error: AppError, onRetry: () -> Unit, modifier: Modifier = Modifier, retrying: Boolean = false)` — icon: `Icons.Outlined.WifiOff` for `NoInternet`, `Icons.Outlined.CloudOff` for `ServiceUnavailable`, `Icons.Outlined.ErrorOutline` otherwise (tint `destructive`); title `stringResource(error.titleRes())`; message `error.toUiText().asString()`; action `AppButton(stringResource(R.string.action_retry), onRetry, loading = retrying)`. Test tag `StateTags.ERROR = "state_error"`.
- `@Composable fun ServiceUnavailableState(onRetry: () -> Unit, modifier: Modifier = Modifier, retrying: Boolean = false)` — `StatusMessage` with `CloudOff`, title `R.string.error_title_unavailable`, message `R.string.service_unavailable_message`, retry button.
- `@Composable fun OfflineBlockingState(onRetry: () -> Unit, modifier: Modifier = Modifier)` — full-size `Box` with `background(AppTheme.colors.scrim)` and `pointerInput(Unit) { awaitPointerEventScope { while (true) awaitPointerEvent().changes.forEach { it.consume() } } }` to block touches, centered `AppModalLayout(title = stringResource(R.string.offline_blocking_title))` containing `StatusMessage(WifiOff, …, message = R.string.offline_blocking_message)` and a retry `AppButton`. Test tag `StateTags.OFFLINE = "state_offline_blocking"`.
- `object StateTags { const val ERROR = "state_error"; const val OFFLINE = "state_offline_blocking"; const val LOADING = "state_loading" }` (in `LoadStateContent.kt`).
- `@Composable fun <T> LoadStateContent(state: LoadState<T>, onRetry: () -> Unit, empty: @Composable () -> Unit, modifier: Modifier = Modifier, loading: @Composable () -> Unit = { LoadingState(Modifier.testTag(StateTags.LOADING)) }, content: @Composable (T) -> Unit)` — `Idle` renders nothing; `Error` with `AppError.ServiceUnavailable` → `ServiceUnavailableState`, other errors → `ErrorState`.
- `@Composable fun ObserveEffects(effects: Flow<UiEffect>, onEffect: suspend (UiEffect) -> Unit)`
- `val LocalIsOnline: ProvidableCompositionLocal<Boolean>` (default `true`)
- `@Composable fun AppScaffold(modifier: Modifier = Modifier, effects: Flow<UiEffect> = emptyFlow(), onEffect: (UiEffect) -> Unit = {}, requiresNetwork: Boolean = false, onRetryConnection: () -> Unit = {}, topBar: @Composable () -> Unit = {}, content: @Composable (PaddingValues) -> Unit)`

- [ ] **Step 1: Implement `ObserveEffects.kt`**

```kotlin
package com.noshitechinc.restaurant.core.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import kotlinx.coroutines.flow.Flow

@Composable
fun ObserveEffects(effects: Flow<UiEffect>, onEffect: suspend (UiEffect) -> Unit) {
    val lifecycleOwner = LocalLifecycleOwner.current
    val currentOnEffect by rememberUpdatedState(onEffect)
    LaunchedEffect(effects, lifecycleOwner) {
        lifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
            effects.collect { currentOnEffect(it) }
        }
    }
}
```

- [ ] **Step 2: Implement `AppScaffold.kt`**

```kotlin
package com.noshitechinc.restaurant.core.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ProvidableCompositionLocal
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import com.noshitechinc.restaurant.R
import com.noshitechinc.restaurant.core.common.AppError
import com.noshitechinc.restaurant.core.designsystem.component.button.AppButton
import com.noshitechinc.restaurant.core.designsystem.component.dialog.AppModal
import com.noshitechinc.restaurant.core.designsystem.preview.PreviewSurface
import com.noshitechinc.restaurant.core.designsystem.preview.ScreenPreviews
import com.noshitechinc.restaurant.core.designsystem.theme.AppTheme
import com.noshitechinc.restaurant.core.ui.error.titleRes
import com.noshitechinc.restaurant.core.ui.error.toUiText
import com.noshitechinc.restaurant.core.ui.state.OfflineBlockingState
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.launch

val LocalIsOnline: ProvidableCompositionLocal<Boolean> = compositionLocalOf { true }

@Composable
fun AppScaffold(
    modifier: Modifier = Modifier,
    effects: Flow<UiEffect> = emptyFlow(),
    onEffect: (UiEffect) -> Unit = {},
    requiresNetwork: Boolean = false,
    onRetryConnection: () -> Unit = {},
    topBar: @Composable () -> Unit = {},
    content: @Composable (PaddingValues) -> Unit,
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }
    var messageTone by remember { mutableStateOf(MessageTone.Info) }
    var dialogError by remember { mutableStateOf<AppError?>(null) }

    ObserveEffects(effects) { effect ->
        when (effect) {
            is ShowMessage -> {
                messageTone = effect.tone
                scope.launch { snackbarHostState.showSnackbar(effect.text.asString(context)) }
            }
            is ShowErrorDialog -> dialogError = effect.error
            else -> onEffect(effect)
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        Scaffold(
            topBar = topBar,
            snackbarHost = {
                SnackbarHost(snackbarHostState) { data ->
                    AppSnackbar(message = data.visuals.message, tone = messageTone)
                }
            },
            containerColor = AppTheme.colors.background,
            content = content,
        )
        if (requiresNetwork && !LocalIsOnline.current) {
            OfflineBlockingState(onRetry = onRetryConnection)
        }
    }

    dialogError?.let { error ->
        AppModal(
            title = stringResource(error.titleRes()),
            onDismissRequest = { dialogError = null },
            actions = { AppButton(text = stringResource(R.string.action_ok), onClick = { dialogError = null }) },
        ) {
            Text(text = error.toUiText().asString(), style = AppTheme.typography.bodyLarge, color = AppTheme.colors.textSecondary)
        }
    }
}

@Composable
private fun AppSnackbar(message: String, tone: MessageTone) {
    val (container, content) = when (tone) {
        MessageTone.Info -> AppTheme.colors.textPrimary to AppTheme.colors.surface
        MessageTone.Success -> AppTheme.colors.success to AppTheme.colors.onPrimary
        MessageTone.Error -> AppTheme.colors.destructive to AppTheme.colors.onDestructive
    }
    Snackbar(
        modifier = Modifier.padding(AppTheme.spacing.lg),
        shape = RoundedCornerShape(AppTheme.radius.md),
        containerColor = container,
        contentColor = content,
    ) {
        Text(text = message, style = AppTheme.typography.bodyMedium, maxLines = 4)
    }
}

@ScreenPreviews
@Composable
private fun AppScaffoldOnlinePreview() {
    PreviewSurface {
        AppScaffold { Text(text = "Screen content", modifier = Modifier.padding(it)) }
    }
}

@ScreenPreviews
@Composable
private fun AppScaffoldOfflinePreview() {
    PreviewSurface {
        CompositionLocalProvider(LocalIsOnline provides false) {
            AppScaffold(requiresNetwork = true) { Text(text = "Screen content", modifier = Modifier.padding(it)) }
        }
    }
}

@ScreenPreviews
@Composable
private fun AppSnackbarPreview() {
    PreviewSurface {
        Box {
            AppSnackbar(message = "Order sent to the kitchen", tone = MessageTone.Success)
        }
    }
}
```

- [ ] **Step 3: Implement the state files** exactly per the Interfaces block. Previews required:
  - `StatusMessage`: with/without message and action; long message at font 2.0.
  - `LoadingState`, `AppCircularProgress`, `AppLinearProgress` (indeterminate and `0.4f`), `SkeletonList` (tablet medium and expanded width).
  - `EmptyState`: default copy, custom copy with action; `NoSearchResultsState` with `PreviewData.SEARCH_QUERY`.
  - `ErrorState`: one preview per `AppError` kind (NoInternet, Timeout, ServiceUnavailable, SessionExpired, Forbidden, NotFound, Validation with message, Server, Unknown) and a `retrying = true` preview; `ServiceUnavailableState`; `OfflineBlockingState` at `@ScreenPreviews`.
  - `LoadStateContent`: Loading, Empty, Error, Content.

- [ ] **Step 4: Build + lint — expect PASS**

Run: `cd /home/bs01470/AndroidStudioProjects/resturant-app && ANDROID_HOME=$HOME/Android/Sdk ./gradlew assembleDevDebug --console=plain && scripts/ai-hooks/design-lint-check.sh app/src/main/java/com/noshitechinc/restaurant/core; echo "lint=$?"`
Expected: `BUILD SUCCESSFUL`, `lint=0`.

- [ ] **Step 5: Checkpoint** — list files.

---

### Task 9: App shell — navigation, home feature, final `MainActivity`

**Files:**
- Create: `SRC/navigation/Destinations.kt`, `SRC/navigation/AppNavHost.kt`
- Create: `SRC/feature/home/HomeUiState.kt`, `SRC/feature/home/HomeViewModel.kt`, `SRC/feature/home/HomeScreen.kt`
- Modify: `SRC/app/MainActivity.kt`
- Test: `TEST/feature/home/HomeViewModelTest.kt`

**Interfaces (Produces):**
- `@Serializable data object HomeDestination`
- `@Composable fun AppNavHost(sessionEnded: Flow<Unit>, modifier: Modifier = Modifier, navController: NavHostController = rememberNavController())`
- `data class HomeUiState(val environment: AppEnvironment? = null, val versionName: String = "")`
- `@HiltViewModel class HomeViewModel @Inject constructor(appInfo: AppInfo) : BaseViewModel()` with `val uiState: StateFlow<HomeUiState>`
- `@Composable fun HomeRoute(viewModel: HomeViewModel = hiltViewModel())`, `@Composable fun HomeScreen(state: HomeUiState, modifier: Modifier = Modifier)`

- [ ] **Step 1: Write failing test**

`TEST/feature/home/HomeViewModelTest.kt`
```kotlin
package com.noshitechinc.restaurant.feature.home

import com.noshitechinc.restaurant.core.common.AppEnvironment
import com.noshitechinc.restaurant.core.common.AppInfo
import com.noshitechinc.restaurant.testing.MainDispatcherRule
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import org.junit.Rule

class HomeViewModelTest {
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun `non production builds expose the environment`() {
        val vm = HomeViewModel(AppInfo(AppEnvironment.Staging, "1.0.0", 3))
        assertEquals(HomeUiState(environment = AppEnvironment.Staging, versionName = "1.0.0"), vm.uiState.value)
    }

    @Test
    fun `production hides the environment`() {
        val vm = HomeViewModel(AppInfo(AppEnvironment.Prod, "1.0.0", 3))
        assertNull(vm.uiState.value.environment)
    }
}
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement home feature**

`SRC/feature/home/HomeUiState.kt`
```kotlin
package com.noshitechinc.restaurant.feature.home

import com.noshitechinc.restaurant.core.common.AppEnvironment

data class HomeUiState(
    val environment: AppEnvironment? = null,
    val versionName: String = "",
)
```

`SRC/feature/home/HomeViewModel.kt`
```kotlin
package com.noshitechinc.restaurant.feature.home

import com.noshitechinc.restaurant.core.common.AppEnvironment
import com.noshitechinc.restaurant.core.common.AppInfo
import com.noshitechinc.restaurant.core.ui.BaseViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

@HiltViewModel
class HomeViewModel @Inject constructor(appInfo: AppInfo) : BaseViewModel() {
    private val _uiState = MutableStateFlow(
        HomeUiState(
            environment = appInfo.environment.takeUnless { it == AppEnvironment.Prod },
            versionName = appInfo.versionName,
        ),
    )
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()
}
```

`SRC/feature/home/HomeScreen.kt`
```kotlin
package com.noshitechinc.restaurant.feature.home

import androidx.annotation.StringRes
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.noshitechinc.restaurant.R
import com.noshitechinc.restaurant.core.common.AppEnvironment
import com.noshitechinc.restaurant.core.designsystem.component.selection.StatusBadge
import com.noshitechinc.restaurant.core.designsystem.preview.PreviewSurface
import com.noshitechinc.restaurant.core.designsystem.preview.ScreenPreviews
import com.noshitechinc.restaurant.core.designsystem.theme.AppTheme
import com.noshitechinc.restaurant.core.designsystem.theme.StatusTone
import com.noshitechinc.restaurant.core.ui.AppScaffold

@Composable
fun HomeRoute(viewModel: HomeViewModel = hiltViewModel()) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    AppScaffold(effects = viewModel.effects) { padding ->
        HomeScreen(state = state, modifier = Modifier.padding(padding))
    }
}

@Composable
fun HomeScreen(state: HomeUiState, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier.fillMaxSize().padding(AppTheme.spacing.xl),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            modifier = Modifier.widthIn(max = AppTheme.sizes.formMaxWidth),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(AppTheme.spacing.md),
        ) {
            Text(
                text = stringResource(R.string.app_name),
                style = AppTheme.typography.headlineLarge,
                color = AppTheme.colors.textPrimary,
                textAlign = TextAlign.Center,
            )
            Text(
                text = stringResource(R.string.home_subtitle),
                style = AppTheme.typography.bodyLarge,
                color = AppTheme.colors.textSecondary,
                textAlign = TextAlign.Center,
            )
            state.environment?.let { StatusBadge(text = stringResource(it.labelRes()), tone = StatusTone.Warning) }
            Text(
                text = stringResource(R.string.home_version, state.versionName),
                style = AppTheme.typography.bodySmall,
                color = AppTheme.colors.textSecondary,
            )
        }
    }
}

@StringRes
private fun AppEnvironment.labelRes(): Int = when (this) {
    AppEnvironment.Dev -> R.string.env_dev
    AppEnvironment.Staging -> R.string.env_staging
    AppEnvironment.Prod -> R.string.env_prod
}

@ScreenPreviews
@Composable
private fun HomeScreenDevPreview() {
    PreviewSurface { HomeScreen(state = HomeUiState(environment = AppEnvironment.Dev, versionName = "0.1.0")) }
}

@ScreenPreviews
@Composable
private fun HomeScreenProdPreview() {
    PreviewSurface { HomeScreen(state = HomeUiState(environment = null, versionName = "0.1.0")) }
}
```

- [ ] **Step 4: Navigation**

`SRC/navigation/Destinations.kt`
```kotlin
package com.noshitechinc.restaurant.navigation

import kotlinx.serialization.Serializable

@Serializable
data object HomeDestination
```

`SRC/navigation/AppNavHost.kt`
```kotlin
package com.noshitechinc.restaurant.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.noshitechinc.restaurant.feature.home.HomeRoute
import kotlinx.coroutines.flow.Flow

@Composable
fun AppNavHost(
    sessionEnded: Flow<Unit>,
    modifier: Modifier = Modifier,
    navController: NavHostController = rememberNavController(),
) {
    LaunchedEffect(sessionEnded, navController) {
        sessionEnded.collect {
            navController.navigate(HomeDestination) {
                popUpTo(navController.graph.id) { inclusive = true }
                launchSingleTop = true
            }
        }
    }
    NavHost(navController = navController, startDestination = HomeDestination, modifier = modifier) {
        composable<HomeDestination> { HomeRoute() }
    }
}
```

- [ ] **Step 5: Final `MainActivity.kt`**

```kotlin
package com.noshitechinc.restaurant.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.noshitechinc.restaurant.core.adaptive.OrientationPolicy
import com.noshitechinc.restaurant.core.auth.SessionManager
import com.noshitechinc.restaurant.core.designsystem.theme.AppTheme
import com.noshitechinc.restaurant.core.network.NetworkMonitor
import com.noshitechinc.restaurant.core.ui.LocalIsOnline
import com.noshitechinc.restaurant.navigation.AppNavHost
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    @Inject
    lateinit var networkMonitor: NetworkMonitor

    @Inject
    lateinit var sessionManager: SessionManager

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        requestedOrientation = OrientationPolicy.requestedOrientation(resources.configuration.smallestScreenWidthDp)
        enableEdgeToEdge()
        setContent {
            val isOnline by networkMonitor.isOnline.collectAsStateWithLifecycle()
            AppTheme {
                CompositionLocalProvider(LocalIsOnline provides isOnline) {
                    AppNavHost(sessionEnded = sessionManager.sessionEnded)
                }
            }
        }
    }
}
```

Remove the now-unused `home_title` string from `strings.xml`.

- [ ] **Step 6: Run tests + all builds + lint — expect PASS**

Run: `cd /home/bs01470/AndroidStudioProjects/resturant-app && ANDROID_HOME=$HOME/Android/Sdk ./gradlew testDevDebugUnitTest assembleDevDebug assembleStagingDebug assembleProdRelease --console=plain && scripts/ai-hooks/design-lint-check.sh app/src/main; echo "lint=$?"`
Expected: `BUILD SUCCESSFUL`, `lint=0`.

- [ ] **Step 7: Checkpoint** — list files.

---

### Task 10: Compose UI tests

**Files:**
- Create: `ATEST/core/designsystem/QuantityStepperTest.kt`, `ATEST/core/designsystem/NumericKeypadTest.kt`, `ATEST/core/designsystem/AppButtonTest.kt`, `ATEST/core/ui/OfflineBlockingTest.kt`

**Interfaces:**
- Consumes: `QuantityStepperTags`, `NumericKeypadTags`, `KeypadReducer`, `KeypadMode`, `AppButton`, `AppScaffold`, `LocalIsOnline`, `StateTags`, `AppTheme`.

- [ ] **Step 1: Write the tests**

`ATEST/core/designsystem/QuantityStepperTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import com.noshitechinc.restaurant.core.designsystem.component.quantity.QuantityStepper
import com.noshitechinc.restaurant.core.designsystem.component.quantity.QuantityStepperTags
import com.noshitechinc.restaurant.core.designsystem.theme.AppTheme
import org.junit.Rule
import org.junit.Test

class QuantityStepperTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun stepperRespectsMinAndMax() {
        rule.setContent {
            AppTheme {
                var quantity by remember { mutableIntStateOf(1) }
                QuantityStepper(quantity = quantity, onQuantityChange = { quantity = it }, min = 1, max = 3)
            }
        }
        rule.onNodeWithTag(QuantityStepperTags.DECREMENT).assertIsNotEnabled()
        rule.onNodeWithTag(QuantityStepperTags.INCREMENT).performClick().performClick()
        rule.onNodeWithTag(QuantityStepperTags.VALUE).assertTextEquals("3")
        rule.onNodeWithTag(QuantityStepperTags.INCREMENT).assertIsNotEnabled()
        rule.onNodeWithTag(QuantityStepperTags.DECREMENT).assertIsEnabled()
    }
}
```

`ATEST/core/designsystem/NumericKeypadTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import com.noshitechinc.restaurant.core.designsystem.component.quantity.KeypadMode
import com.noshitechinc.restaurant.core.designsystem.component.quantity.KeypadReducer
import com.noshitechinc.restaurant.core.designsystem.component.quantity.NumericKeypad
import com.noshitechinc.restaurant.core.designsystem.component.quantity.NumericKeypadTags
import com.noshitechinc.restaurant.core.designsystem.theme.AppTheme
import org.junit.Rule
import org.junit.Test

class NumericKeypadTest {
    @get:Rule
    val rule = createComposeRule()

    private fun setKeypad(mode: KeypadMode) {
        rule.setContent {
            AppTheme {
                var value by remember { mutableStateOf("") }
                Column {
                    Text(text = value, modifier = Modifier.testTag("value"))
                    NumericKeypad(onKey = { value = KeypadReducer.reduce(value, it, mode) }, mode = mode)
                }
            }
        }
    }

    @Test
    fun integerTypingAndBackspace() {
        setKeypad(KeypadMode.Integer)
        rule.onNodeWithTag(NumericKeypadTags.digit(1)).performClick()
        rule.onNodeWithTag(NumericKeypadTags.digit(2)).performClick()
        rule.onNodeWithTag(NumericKeypadTags.BACKSPACE).performClick()
        rule.onNodeWithTag(NumericKeypadTags.digit(5)).performClick()
        rule.onNodeWithTag("value").assertTextEquals("15")
    }

    @Test
    fun decimalAllowsSingleSeparator() {
        setKeypad(KeypadMode.Decimal)
        rule.onNodeWithTag(NumericKeypadTags.digit(3)).performClick()
        rule.onNodeWithTag(NumericKeypadTags.DECIMAL).performClick()
        rule.onNodeWithTag(NumericKeypadTags.DECIMAL).performClick()
        rule.onNodeWithTag(NumericKeypadTags.digit(5)).performClick()
        rule.onNodeWithTag("value").assertTextEquals("3.5")
    }

    @Test
    fun currencyDoubleZero() {
        setKeypad(KeypadMode.Currency)
        rule.onNodeWithTag(NumericKeypadTags.digit(7)).performClick()
        rule.onNodeWithTag(NumericKeypadTags.DOUBLE_ZERO).performClick()
        rule.onNodeWithTag("value").assertTextEquals("700")
    }
}
```

`ATEST/core/designsystem/AppButtonTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.designsystem

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import com.noshitechinc.restaurant.core.designsystem.component.button.AppButton
import com.noshitechinc.restaurant.core.designsystem.theme.AppTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

class AppButtonTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun loadingButtonIgnoresTaps() {
        var clicks = 0
        var loading by mutableStateOf(true)
        rule.setContent {
            AppTheme { AppButton(text = "Send", onClick = { clicks++ }, loading = loading, modifier = Modifier.testTag("button")) }
        }
        rule.onNodeWithTag("button").performClick()
        assertEquals(0, clicks)
        loading = false
        rule.onNodeWithTag("button").performClick()
        assertEquals(1, clicks)
    }

    @Test
    fun disabledButtonIgnoresTaps() {
        var clicks = 0
        rule.setContent {
            AppTheme { AppButton(text = "Send", onClick = { clicks++ }, enabled = false, modifier = Modifier.testTag("button")) }
        }
        rule.onNodeWithTag("button").performClick()
        assertEquals(0, clicks)
    }
}
```

`ATEST/core/ui/OfflineBlockingTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.ui

import androidx.compose.material3.Text
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import com.noshitechinc.restaurant.core.designsystem.theme.AppTheme
import com.noshitechinc.restaurant.core.ui.state.StateTags
import org.junit.Rule
import org.junit.Test

class OfflineBlockingTest {
    @get:Rule
    val rule = createComposeRule()

    @Test
    fun blockingStateFollowsConnectivity() {
        var online by mutableStateOf(false)
        rule.setContent {
            AppTheme {
                CompositionLocalProvider(LocalIsOnline provides online) {
                    AppScaffold(requiresNetwork = true) { Text("content") }
                }
            }
        }
        rule.onNodeWithTag(StateTags.OFFLINE).assertIsDisplayed()
        online = true
        rule.waitForIdle()
        rule.onNodeWithTag(StateTags.OFFLINE).assertDoesNotExist()
    }
}
```

- [ ] **Step 2: Compile tests**

Run: `cd /home/bs01470/AndroidStudioProjects/resturant-app && ANDROID_HOME=$HOME/Android/Sdk ./gradlew assembleDevDebugAndroidTest --console=plain`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 3: Run on a device/emulator**

Run: `$HOME/Android/Sdk/platform-tools/adb devices; $HOME/Android/Sdk/emulator/emulator -list-avds`
- If a device is listed: `ANDROID_HOME=$HOME/Android/Sdk ./gradlew connectedDevDebugAndroidTest --console=plain` → expect `BUILD SUCCESSFUL`.
- Else if an AVD exists: start it headless with `$HOME/Android/Sdk/emulator/emulator -avd <name> -no-window -no-audio -no-boot-anim` in the background, wait for `adb wait-for-device` and `sys.boot_completed == 1`, then run the connected tests.
- Else: record "UI tests compiled; device run pending (no device/AVD)" in context repo `docs/06-development/TEST-CONTEXT.md`.

- [ ] **Step 4: Checkpoint** — list files.

---

### Task 11: Definition-of-done verification and doc sync

- [ ] **Step 1: Full gate**

Run:
```bash
cd /home/bs01470/AndroidStudioProjects/resturant-app
ANDROID_HOME=$HOME/Android/Sdk ./gradlew ktlintCheck detekt testDevDebugUnitTest assembleDevDebug assembleStagingDebug assembleProdRelease assembleDevDebugAndroidTest --console=plain
scripts/ai-hooks/design-lint-check.sh app/src/main; echo "design-lint=$?"
scripts/ai-hooks/tests/run-tests.sh; echo "hook-tests=$?"
```
Expected: `BUILD SUCCESSFUL` (omit `detekt` if PDR-005 deferred it), `design-lint=0`, `hook-tests=0`.

- [ ] **Step 2: Preview coverage check**

Run: `cd /home/bs01470/AndroidStudioProjects/resturant-app && for f in $(rg -l '^@Composable' app/src/main/java/com/noshitechinc/restaurant/core/designsystem/component app/src/main/java/com/noshitechinc/restaurant/core/designsystem/state app/src/main/java/com/noshitechinc/restaurant/core/ui app/src/main/java/com/noshitechinc/restaurant/feature); do rg -q '@(ComponentPreviews|ScreenPreviews)' "$f" || echo "NO PREVIEW: $f"; done; echo done`
Expected: only `done` (files with only `private`/`internal` helpers may be listed — add previews or confirm they contain no public composables).

- [ ] **Step 3: Live hook checks** — perform Plan 1 Task 6 Step 4 items 2–5 in Cursor and record results in `TEST-CONTEXT.md`.

- [ ] **Step 4: Doc sync** (context repo)
  - `sprint-0.md`: all FOUND-001…020 → Done (or note exceptions, e.g. device run pending).
  - `modules/FOUND.md`: final code paths + tests per FR.
  - `SPECIFICATION.md`: no changes unless acceptance criteria changed (then new text, same IDs).
  - `ADR-006`: note final preview annotation names and the `AdaptiveInfo` approach.
  - `PROJECT-INDEX.md`: status "Foundation complete", Last updated, open PDRs.
  - `TEST-CONTEXT.md`: commands run, results, device-run status, hook verification log.

- [ ] **Step 5: Final checkpoint** — list all files changed in this plan.

---

## Self-review (done at plan time)

- FR coverage: 003 → Tasks 3 (AddressInput adaptive), 9 (orientation in `MainActivity`) + Plan 2 Task 6; 006 → Task 1; 007 → Task 2; 008 → Task 3; 009 → Task 4; 010 → Task 5; 011 → Task 6; 012 → Task 7; 013 → Task 7; 014 → Tasks 2–7 (variant previews via `ForcedInteraction`); 015 → Task 8; 016 → Task 8; 017 → Task 8 (`ErrorState`, `LoadStateContent`) + Plan 2 errors; 018 → Task 8 (`ServiceUnavailableState`, `OfflineBlockingState`, `AppScaffold`); 019 → Task 2 (`loading`) + Plan 2 `launchSubmit` + Task 10 test; 020 → Global Constraints + per-component long-content previews + `en-XA` pseudo-locale (Plan 2 Task 1).
- Type consistency: `StatusTone.containerColor()/contentColor()`, `rememberInteractionVisuals`, `focusRing(visible, color, width, shape)`, `QuantityStepperTags`, `NumericKeypadTags`, `StateTags`, `LocalIsOnline`, `AppModalLayout`, `HomeDestination` are defined where first used.
- Component bodies for Tasks 3–8 are specified by exact signatures, token usage, behaviour and preview matrices; Task 2 (`AppButton`) and Task 8 (`AppScaffold`) give full reference code to copy patterns from.
