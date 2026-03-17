# Contract Changelog

## 2026-03-18
- API version bumped to 1.1.0.
- Added Python import service dev server to OpenAPI servers list.
- Added new `/api` endpoints for Python import service:
  - `GET /api/schools` — school list (new format)
  - `GET /api/schools/{id}/config` — full school config with field_mapping / timer_config
  - `GET /api/schools/{id}/script` — JS provider script download
  - `POST /api/import/validate` — raw JSON → standardized courses (core validation)
  - `POST /api/import/log` — import log reporting (new format)
  - `GET /health` — service health check
- All existing `/v1` paths remain unchanged and backward-compatible.
- Flutter `AppEnv.apiBaseUrl` switched to `localhost:8000` (Python service).
- `ImportApiService` created in Flutter to consume new `/api` endpoints.
- `ImportEngine` now supports dual import paths (backend validate vs local HTML parse).

## 2026-03-14
- Added initial OpenAPI v1 file.
- Added school config list response schema.
- Added import log request schema.
- Added standard error response schema.
- Extended school config contract with level enum: junior/undergraduate/master/general.
- Added release check contract: GET /v1/release/check and response schema.
- Added adapter rule contract: GET /v1/config/adapters and adapter rule list schema.
