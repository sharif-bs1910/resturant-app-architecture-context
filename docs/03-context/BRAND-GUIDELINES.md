# Brand guidelines — Noshi Brand Library v1.0

Source: Figma file `YJwjweeoIAWxM7AuzAB1Xg` (April 2026, Active). Applied in the Android theme and shared components. Patterns (page 05) are not built; this app stays tablet only.

## Logo

Primary system is the Steam Bowl plus a Fraunces wordmark. The bowl is espresso on light surfaces. Three Hot Sauce dots sit above it and are part of the mark. The wordmark is lowercase Fraunces SemiBold with tracking −3.5%. Only the **i** is Fraunces SemiBold Italic in Hot Sauce.

| Surface | Bowl | Steam | Word | Accent i |
|---|---|---|---|---|
| Light (on Oat Milk) | Espresso | Hot Sauce | Espresso | Hot Sauce |
| Dark (on Espresso) | Oat Milk | Hot Sauce | Oat Milk | Hot Sauce |
| Brand (on Hot Sauce) | Oat Milk | Espresso | Espresso | Oat Milk |

Code: the Steam Bowl paths are the Figma SVG export (`ic_steam_bowl_light`, `_dark`, `_brand`). `NoshiWordmark` stays live Fraunces text. `NoshiLockup` hides the mark below 24dp. The Bite + Inter lockup is the library’s tech-product alternate and is not used in this app.

Misuse rules from the library: do not drop the steam, recolor outside the three surfaces, recolor the whole wordmark Hot Sauce, upright the i, crowd the lockup, or mix Steam Bowl with Inter.

## Color and type

Mapped in `AppColors` and `AppTypography` (IA-2026-10-01-brand-tokens). Status colours are still the previous palette (PDR-002).

Pairing and sign-in add two screen colours that the library page does not name (IA-2026-10-02-auth-screen-tokens): `card` is white `#FFFFFF` for passcode cells and keys, and `textMuted` is `#6A6664` for secondary copy. Oat Milk 2 stays `surface`. The 520dp brand column and 80×68 keys are `AppSizes` used on expanded width only.

## Components

| Library component | In the app |
|---|---|
| Button Primary | `ButtonVariant.Primary` — Hot Sauce, Espresso label, pill, padding 12×20 |
| Button Secondary | `ButtonVariant.Secondary` — Oat Milk 2 fill, Espresso label, pill |
| Button Ghost | `ButtonVariant.Outline` — transparent, Espresso label and stroke, pill |
| Tag Mono / Brand / Inverse | `AppTag` — JetBrains Mono 11, uppercase, 18% tracking |
| AppHero | `AppHero` — one hero per screen; eyebrow, title with one italic accent, secondary action |

`ButtonVariant.Destructive` stays for error actions. The library does not define it.

## Documentation rules that apply

- Contrast target is WCAG AA. Espresso on Hot Sauce is the body pairing. Oat Milk on Hot Sauce is only for large display.
- Focus ring is 2dp Hot Sauce.
- Body copy is Inter, at least 12sp; 14sp is the default body.
- Touch targets stay **48dp**. The library’s 44px figure is the iOS minimum.
- Voice from the library: confident, warm, decisive, specific. Do not add cute, urgent, or apologetic product copy until business context is shared.
