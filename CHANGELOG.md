# Changelog

All notable changes to the Malaysia Payroll API.

## [0.2.0] — 2026-08-07

### Added
- API key authentication (Bearer) with 401 for missing/invalid keys
- Rate limiting: 1,000 req/month per key (sliding window), 429 + Retry-After
- Public `/api/v1/health` liveness endpoint
- Key management endpoints (`GET/POST/DELETE /api/v1/keys`)
- Year-keyed rate tables (2025, 2026) with effective dates and source references
- Production release build + systemd unit (`payroll-api.service`)
- OpenAPI 3.1 spec (`priv/static/openapi.yaml`)
- README with quickstart and architecture docs

### Changed
- `/api/v1/rates` now requires auth (was public)
- Rates are data-driven (`rates_by_year/0`) — no calculation code changes needed for new years

## [0.1.0] — 2026-08-06

### Added
- `GET /api/v1/rates` — statutory rate tables
- `POST /api/v1/calculate-payslip` — EPF + SOCSO + EIS + HRDF
- Monthly PCB (LHDN MTD Method 1): YA 2025 brackets, reliefs, RM400 rebate
- LiveView payslip calculator UI
- API docs page
- Conventional Commits enforced (commit-msg hook)
- 30+ tests

[0.2.0]: https://github.com/Sienz16/Malaysia-Payroll/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Sienz16/Malaysia-Payroll/releases/tag/v0.1.0
