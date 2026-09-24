# API Registry

Every backend endpoint the app calls is registered here before or in the same change as the code that calls it (doc-sync rule in [AGENTS.md](../../AGENTS.md)). If a contract is not known, do not invent one: record a PDR in [PENDING-DECISIONS.md](PENDING-DECISIONS.md).

## ID scheme

`api:{domain}:{slug}`

- `domain` — the backend area in lower case, for example `auth`, `menu`, `orders`, `kitchen`.
- `slug` — a short kebab-case name for the operation, for example `refresh`, `list-items`, `create-order`.
- IDs are permanent. A replaced endpoint keeps its row with status `Deprecated`; the new endpoint gets a new ID.

## Columns

| Column | Meaning |
|---|---|
| ID | `api:{domain}:{slug}` |
| Method | HTTP method |
| Path | Path relative to `API_BASE_URL` (per environment in `config/env/*.properties`) |
| Auth | `bearer` (added by `AuthInterceptor`) or `none (X-No-Auth)` |
| Request | Request body fields or query parameters |
| Response | Response body fields on success |
| Errors | Endpoint-specific error handling beyond the common `AppError` mapping |
| Status | `Placeholder (PDR-NNN)`, `Draft`, `Live` or `Deprecated` |
| Consumers | Code that calls the endpoint (API interface → repository or provider) |

## Endpoints

| ID | Method | Path | Auth | Request | Response | Errors | Status | Consumers |
|---|---|---|---|---|---|---|---|---|
| api:auth:refresh | POST | auth/refresh | none (X-No-Auth) | {refreshToken} | {accessToken, refreshToken} | 401 → session end | Placeholder (PDR-001) | TokenAuthenticator via RefreshTokenAuthProvider |
