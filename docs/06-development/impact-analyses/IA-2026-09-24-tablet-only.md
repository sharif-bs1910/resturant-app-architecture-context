# IA-2026-09-24-tablet-only

## Change summary

Constrain Noshitech Restaurant to **tablet only**. Remove phone/handset device assumptions from living context docs and Android code (previews, orientation policy wording, crash keys, adaptive tests/docs, AI rules/skills).

**FR / tickets:** amends FR-FOUND-003 (adaptive layout), FR-FOUND-005 (logging keys), FR-FOUND-006…020 preview expectations; ADR-006 amendment. No new ticket ID yet.

**Out of scope (keep):**

- `PhoneField`, `UsPhoneFormatter`, `UsPhoneValidator` — US **telephone** market formats, not handset layouts.
- `WidthClass.Compact` behaviour for **narrow multi-window** on tablets (rename phone-oriented labels only).

**In scope (expanded):** living docs, Android code/skills, and historical `docs/superpowers/` plans/specs — update everywhere per human request.

## Trigger (which rule)

- Public parameters / shared preview APIs in `core/designsystem` (`PhonePreview`, `ComponentPreviews`, `ScreenPreviews`).
- Adaptive / orientation behaviour used from `MainActivity` (related to manifest orientation policy docs; code change in `OrientationPolicy`).
- Living docs and AI rules that encode the phone-support contract.

## Consumers found (search commands + results)

Commands run from `resturant-app` root on 2026-09-24.

| Search command | Files / matches |
|---|---|
| `rg -n "PhonePreview" app/src scripts .cursor/skills .claude/skills` | Definition + use in `PreviewAnnotations.kt`; `design-lint-check.sh` PREVIEW_RE; skills mention phone widths |
| `rg -l "ComponentPreviews" app/src` | **33 files** (annotation + all components/states that use `@ComponentPreviews`) |
| `rg -l "ScreenPreviews" app/src` | `PreviewAnnotations.kt`, `HomeScreen.kt`, `AppScaffold.kt`, `OfflineBlockingState.kt` |
| `rg -n "OrientationPolicy\|isTablet\|device_class\|WidthClass\.Compact" app/src` | `OrientationPolicy.kt`, `AdaptiveInfo.kt`, `MainActivity.kt`, `RestaurantApplication.kt`, `AppStartup.kt`, `AppLogging.kt`, `AdaptiveInfoTest.kt`, `CrashReportingTreeTest.kt` |
| `rg -n -i "phones supported\|PhonePreview\|phone width\|phones rotate\|device_class.*phone\|tablet landscape, phone" ../resturant-app-architecture --glob '!**/superpowers/**'` | `project-overview.md`, `AI-ASSISTANT-RULES.md`, `PROJECT-CONTEXT.md`, `CONCEPT-NOTE.md`, `SPECIFICATION.md` (FR-FOUND-003/005), `ADR-005`, `ADR-006`, `FOUND.md` |
| `rg -n "phone" .cursor/skills --glob '*.md*'` | `build-ui-component`, `scaffold-screen`, `review-change` (and `.claude/skills` symlinks) |

## Blast radius

**Code (Android repo)**

| Area | Files |
|---|---|
| Preview API | `core/designsystem/preview/PreviewAnnotations.kt` — remove `@PhonePreview`; retarget `@ComponentPreviews` / `@ScreenPreviews` to tablet widths only |
| Preview consumers | All 33 `@ComponentPreviews` / `@ScreenPreviews` call sites pick up new matrix automatically (no per-file signature change if annotation bodies change only) |
| Orientation | `OrientationPolicy.kt`, `MainActivity.kt` — always request landscape for this product (no phone free-rotate branch) |
| Logging | `AppLogging.kt`, `AppStartup.kt`, `RestaurantApplication.kt` — `device_class` always `tablet`; drop `isTablet` parameter |
| Adaptive tests | `AdaptiveInfoTest.kt` — rename phone-oriented test names; update orientation expectations |
| Design lint | `scripts/ai-hooks/design-lint-check.sh` — drop `PhonePreview` from PREVIEW_RE |
| Skills / rules | `.cursor/skills/{build-ui-component,scaffold-screen,review-change}/SKILL.md` (+ `.claude` copies), `.cursor/rules/ui-design-system.mdc` if it mentions phone |

**Docs (context repo)**

- `.ai/context/project-overview.md`, `.ai/AI-ASSISTANT-RULES.md`
- `docs/00-project-context/PROJECT-CONTEXT.md`, `docs/01-concept/CONCEPT-NOTE.md`
- `docs/02-specification/SPECIFICATION.md` (FR-FOUND-003, FR-FOUND-005 acceptance)
- `docs/03-context/adr/ADR-005-*.md`, `ADR-006-*.md` (amend Decision / Consequences)
- `docs/05-breakdown/modules/FOUND.md` (preview column for FR-FOUND-003)
- `PROJECT-INDEX.md` — last-updated / note if status changes
- This IA file

**Not affected:** Retrofit/DTOs, tokens, flavors, `PhoneField` API, Gradle catalog.

## Risk (Low/Medium/High + why)

**Medium** — many preview call sites, but most update via shared annotations; behaviour change is intentional (no phone support); unit tests for orientation/logging must change; no backend or data migration.

## Plan (ordered `API → clients → tests → docs`)

1. **API** — Update `PreviewAnnotations.kt` (remove `PhonePreview`; tablet-only `@ComponentPreviews` / `@ScreenPreviews`). Simplify `OrientationPolicy.requestedOrientation` to landscape for the product. Simplify `AppLogging.install` / `AppStartup.run` to always set `device_class=tablet`.
2. **Clients** — `MainActivity`, `RestaurantApplication`; design-lint PREVIEW_RE; Cursor/Claude skills and UI rules text.
3. **Tests** — Update `AdaptiveInfoTest`, `CrashReportingTreeTest` as needed. Prove with:
   - `ANDROID_HOME=$HOME/Android/Sdk ./gradlew ktlintCheck testDevDebugUnitTest`
   - `scripts/ai-hooks/design-lint-check.sh app/src/main`
   - `scripts/ai-hooks/tests/run-tests.sh` (if design-lint regex tests cover PhonePreview)
4. **Docs** — Amend living context files listed above; sync FOUND / SPEC / ADR-005 / ADR-006; leave `PhoneField` requirements unchanged.

## Rollback

Revert the git commits (or restore the files listed in Blast radius) in both repos. Re-run the same Gradle and hook commands. No tokens, secrets or backend state involved.

## Approval (name/date)

| Approver | Date | Decision |
|---|---|---|
| Human (chat) | 2026-09-24 | Approved — update everywhere |
