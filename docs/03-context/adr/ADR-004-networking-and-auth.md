# ADR-004 — Networking and auth: OkHttp chain, single-flight token refresh, AppError taxonomy

## Status

Accepted

## Date

2026-09-24

## Context

All API access must share one client with consistent headers, authentication, logging and error handling (FR-FOUND-004, FR-FOUND-017, FR-FOUND-018). The backend auth scheme is not defined yet (PDR-001), so auth must be pluggable. On a busy tablet several requests can fail with 401 at the same moment; refreshing the token once per request would race and could invalidate refresh tokens. Server error messages must never expose internal details to staff.

## Decision

- **OkHttp chain** (in order): `HeaderInterceptor` (`Accept: application/json`, `Accept-Language: en`, `X-App-Version`, `X-Platform: android`) → `AuthInterceptor` (adds `Authorization: Bearer <token>` from `TokenStore`'s in-memory cache, hydrated at startup off the main thread; requests carrying the `X-No-Auth` header are sent without a token and the marker header is removed) → `HttpLoggingInterceptor` (level from `BuildConfig.HTTP_LOG_LEVEL`; `Authorization` and cookie headers redacted). `TokenAuthenticator` is installed as the OkHttp `Authenticator`.
- **Auth:** `AuthProvider { suspend fun refresh(refreshToken: String): TokenPair? }`. The default `RefreshTokenAuthProvider` calls `api:auth:refresh` (`POST auth/refresh`, placeholder per PDR-001) through a separate Retrofit instance without the authenticator. `KeystoreTokenStore` keeps access and refresh tokens in DataStore encrypted with an Android Keystore AES-GCM key. `SessionManager.endSession()` clears tokens and emits `sessionEnded: SharedFlow<Unit>`, observed by the app shell.
- **`TokenAuthenticator` single-flight refresh:** on 401 it takes a `Mutex`; if the stored token differs from the one the failed request used, it retries with the new token; otherwise it refreshes once; it gives up after one retry per request (`priorResponse` check); when refresh fails it calls `SessionManager.endSession()` and the request fails as `SessionExpired`.
- **Results:** `safeApiCall { }` returns `ApiResult.Success(data)` or `ApiResult.Failure(error: AppError)` and rethrows `CancellationException`. Retrofit services are called only from repositories.
- **`AppError` taxonomy:** `NoInternet`, `Timeout`, `ServiceUnavailable` (HTTP 502/503/504), `SessionExpired` (401 after refresh failure), `Forbidden` (403), `NotFound` (404), `Validation(message, fieldErrors)` (400/422), `Server(code, message)` (other 5xx), `Unknown(cause)`. `ErrorMapper` maps HTTP status codes and exceptions to these kinds.
- **Error bodies and message sanitizing:** `ErrorBodyParser` is replaceable; the default parses `{ "message": String?, "code": String?, "errors": { field: [String] }? }`. `MessageSanitizer` passes a server message only if it is non-blank, at most 280 characters, and free of stack traces, HTML and SQL-like text; otherwise the UI uses the string resource for the error kind.
- **Connectivity:** `NetworkMonitor.isOnline: StateFlow<Boolean>` from a `ConnectivityManager` network callback, shared in an application scope. `AppScaffold(requiresNetwork = true)` shows `OfflineBlockingState` over the content while offline.
- Every endpoint is registered in [API-REGISTRY.md](../API-REGISTRY.md) with an `api:{domain}:{slug}` ID.

## Consequences

- Parallel 401s cause exactly one refresh; other requests reuse the new token.
- Swapping the auth scheme after PDR-001 means replacing `AuthProvider` (and possibly `AuthInterceptor`), not touching repositories or ViewModels.
- UI code handles one closed set of error kinds, and each kind has a title and message resource and a matching state component.
- Staff never see raw stack traces, HTML error pages or SQL fragments.
- Changes to `ApiResult`, `AppError`, DTOs or API contracts require an impact analysis.

## Alternatives considered

- **Refresh inside an interceptor** — rejected: interceptors do not see the retry chain as clearly as `Authenticator`, and making refresh single-flight there is harder.
- **Refresh without a mutex** — rejected: concurrent 401s would trigger several refreshes and may invalidate rotating refresh tokens.
- **Throwing exceptions to ViewModels** — rejected: `ApiResult` + `AppError` makes failures explicit and exhaustive in `when` expressions.
- **Always show server messages** — rejected: backend messages can leak internal details and break layouts.
- **Jetpack security-crypto `EncryptedSharedPreferences`** — rejected: deprecated; Keystore AES-GCM over DataStore is used instead.
