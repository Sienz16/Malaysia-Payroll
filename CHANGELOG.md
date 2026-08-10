# Changelog

All notable changes to the Malaysia Payroll API.

## Unreleased

### Changed
- Calculator, bulk, rates, and PDF endpoints are public and rate-limited by client IP.
- Removed API-key authentication and key-management endpoints; no user data is stored.

## [0.2.0] — 2026-08-07

Prototype release. Not production payroll software.

### Added
- API key authentication (Bearer) with 401 for missing/invalid keys
- Rate limiting: 1,000 req/month per key (sliding window), 429 + Retry-After
- Public `/api/v1/health` liveness endpoint
- Key management endpoints (`GET/POST/DELETE /api/v1/keys`)
- Year-keyed rate tables (2025, 2026) with effective dates and source references
- Prototype production configuration groundwork
- OpenAPI 3.1 spec (`priv/static/openapi.yaml`)
- README with quickstart and architecture docs

### Changed
- `/api/v1/rates` now requires auth (was public)
- Rates are data-driven (`rates_by_year/0`) — no calculation code changes needed for new years

## [0.1.0] — 2026-08-06

### Added
- `GET /api/v1/rates` — statutory rate tables
- `POST /api/v1/calculate-payslip` — EPF + SOCSO + EIS + HRDF
- Simplified PCB Method 1 calculation with YA 2025 brackets, reliefs, RM400 rebate
- LiveView payslip calculator UI
- API docs page
- Conventional Commits enforced (commit-msg hook)
- Focused test suite

### Known limitations

- Official KWSP Third Schedule wage ranges and statutory rounding remain open.
- Full LHDN MTD/PCB workflow and official known-answer validation remain open.
- HRD Corp eligibility, payroll persistence, and deployment controls remain open.

[0.2.0]: https://github.com/Sienz16/Malaysia-Payroll/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Sienz16/Malaysia-Payroll/releases/tag/v0.1.0
