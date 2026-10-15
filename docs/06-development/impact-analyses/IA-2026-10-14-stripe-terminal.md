# IA-2026-10-14-stripe-terminal

## Change summary

Add Stripe Terminal (Reader M2–ready) foundations for **FOUND-021 / FR-FOUND-021**: version-catalog dependency, Terminal-related `BuildConfig` fields from `config/env/*.properties`, Android manifest location/Bluetooth permissions, Application lifecycle hook, and additive stub API clients. Checkout/Self-service payment wiring is out of scope.

## Trigger (which rule)

- Gradle flavors / `config/env/*.properties` / version catalog (`gradle/libs.versions.toml`)
- Android manifest
- Additive API clients/DTOs (registry + doc sync; new endpoints only)

## Consumers found (search commands + results)

| Search command | Files / matches |
|---|---|
| `rg -n "BuildConfig\." app/src --glob '*.kt'` | `di/AppModule.kt` (ENVIRONMENT, VERSION_*), `di/LoggingModule.kt` (CRASH_REPORTING_ENABLED), `di/NetworkModule.kt` (HTTP_LOG_LEVEL, timeouts, API_BASE_URL) — **no existing TERMINAL_* fields** |
| `rg -n "API_BASE_URL\|productFlavors\|libs.versions" app/build.gradle.kts config/env gradle/libs.versions.toml` | Flavor loop + BuildConfig generation in `app/build.gradle.kts`; three env property files; catalog without Stripe today |
| `rg -n "uses-permission\|AndroidManifest" app/src/main/AndroidManifest.xml` | INTERNET, ACCESS_NETWORK_STATE only; Application `.app.RestaurantApplication` |
| `rg -n "RestaurantApplication\|AppStartup" app/src/main --glob '*.kt'` | `RestaurantApplication.kt`, `AppStartup` injection — will gain optional TerminalApplicationDelegate call |
| `rg -n "stripeterminal\|Stripe\|TerminalClient\|TERMINAL_" app/src` | No production Terminal integration (payment UIs are demo delays only) |
| `rg -n "api:terminal:" ../resturant-app-architecture/docs` | No existing terminal API rows |

## Blast radius

**Direct**

- `gradle/libs.versions.toml` — new Stripe Terminal library entries  
- `app/build.gradle.kts` — dependencies + BuildConfig fields for Terminal keys  
- `config/env/dev.properties`, `staging.properties`, `prod.properties` — new keys (required by flavor `value()` helper)  
- `app/src/main/AndroidManifest.xml` — location + Bluetooth permissions  
- `RestaurantApplication` / startup — Terminal SDK lifecycle when enabled  
- New packages: `core/terminal`, terminal DTOs/API/repos, `feature/terminalharness`, `di/TerminalModule`, stub under `tools/`  
- Navigation + Home (dev entry)  
- Context docs: API registry, ADR-007, PDR-006, FR-FOUND-021, sprint board, PROJECT-INDEX  

**Indirect**

- APK size / method count from Stripe SDK  
- Runtime permission UX on harness  
- Cleartext HTTP to `10.0.2.2` stub may need `usesCleartextTraffic` or network security config for **dev** only  
- Existing Checkout/Self-service demos unchanged  

## Risk (Low/Medium/High + why)

**High** — build/flavor/env/manifest changes; new native SDK; cleartext/dev networking; permission surface. Mitigated by `TERMINAL_ENABLED=false` on staging/prod and fake client when disabled.

## Plan (ordered `API → clients → tests → docs`)

1. **API** — Register `api:terminal:connection-token` and `api:terminal:create-payment-intent` (Draft); add DTOs + `TerminalStubApi` on separate Retrofit base URL.  
2. **Clients** — `TerminalClient` + Stripe/fake adapters; repositories; harness feature; Application/manifest/BuildConfig; local stub tool.  
3. **Tests** — MockWebServer + FakeTerminalClient + ViewModel tests; `ANDROID_HOME=$HOME/Android/Sdk ./gradlew ktlintCheck testDevDebugUnitTest`; design-lint on UI paths.  
4. **Docs** — Spec/plan (done), this IA, SPECIFICATION FR-FOUND-021, FOUND/sprint, ADR-007, PDR-006, API-REGISTRY, PROJECT-INDEX, TEST-CONTEXT.

## Rollback

1. Revert catalog, `app/build.gradle.kts`, env properties, manifest, Application, new source packages, nav/home entry, stub tool, and context-doc additions.  
2. Confirm `./gradlew assembleDevDebug` and `testDevDebugUnitTest` on the reverted tree.  
3. No stored reader credentials beyond optional SharedPreferences serial (remove with feature). No production data migration.

## Approval (name/date)

| Approver | Date | Decision |
|---|---|---|
| User (chat: "implement") | 2026-10-14 | Approved — proceed with plan |
