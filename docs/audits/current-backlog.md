# Current Audit Backlog

Last broad audit: 2026-08-09
Source: [`snapshots/2026-08-08-initial-project-audit.md`](snapshots/2026-08-08-initial-project-audit.md)

## Rules

- Keep finding IDs stable.
- Update `Status`, `Verification`, and `Notes` after work.
- Do not mark statutory findings verified without official known-answer evidence.
- Do not mark any finding verified while `mix precommit` fails.

## Release Blockers

| ID | Severity | Status | Finding | Minimal acceptance criteria | Verification |
|---|---|---|---|---|---|
| PAY-001 | Critical | in_progress | EPF percentage direction corrected, but KWSP Third Schedule schedules and statutory rounding remain absent. | Effective-dated KWSP Third Schedule data, employee categories, official rounding, and known-answer tests replace approximation. | Threshold tests pass; official KWSP validation still required |
| PAY-002 | Critical | in_progress | PCB now uses selected year snapshot and explicit spouse eligibility, but remains simplified Method 1, not production Malaysian MTD. | Implement and validate required LHDN computerized MTD scope, or remove production PCB claims and expose limitation clearly. | PCB focused tests pass; official LHDN ordinary/additional remuneration examples pending |
| SEC-001 | Critical | verified | Key-management routes now require a master key; route authorization is fully tested. Durable scoped credentials remain required for production. | Separate admin authorization is tested; durable scoped credentials remain required for production. | 401/403/200 route tests pass (key_controller_test.exs, 8 tests); `mix precommit` passes |
| SEC-002 | Critical | in_progress | No tenant, owner, role, or authorization boundary exists. | Documented security limitation in `ApiKeyAuth` and `Keys` modules; full tenancy requires persistence layer. | Cross-tenant behavior pinned by tests (api_controller_test.exs); `mix precommit` passes |
| DATA-001 | Critical | open | Employee persistence is claimed but no Repo, schema, migration, or durable payroll state exists. | Either remove claim or add constrained employer/employee/payroll persistence with tenant ownership and auditability. | Migration/schema tests, restart persistence test, `mix precommit` |
| PAY-003 | High | verified | Unsupported years now reject at domain and API boundaries; selected rates snapshot reaches PCB. | Reject unsupported years and apply one selected snapshot consistently. | Domain/API malformed-year tests; `mix test` |
| PAY-004 | High | in_progress | Integer-sen Money helpers now drive EPF, HRDF, PCB (annual tax + monthly), and payslip aggregation. Remaining: scheme-specific rounding edge cases and official boundary known-answer coverage. | Integer sen and scheme-specific rounding throughout all payroll calculations. | 104 tests + `mix precommit` pass; official boundary and Money unit coverage added (money_test.exs) |
| PAY-005 | High | in_progress | HRDF supports declared 1%, 0.5%, and exempt modes, but employer eligibility, wage-base rules, and official category validation remain incomplete. | Model covered wage floor and categories from HRD Corp rules with known-answer tests. | HRDF mode tests pass; official HRD Corp validation pending |
| PAY-006 | High | in_progress | Employee age, citizenship, and bulk-row statutory profiles now reach payslip orchestration: SOCSO Category 2 for 60+, zero EIS for 60+/non-Malaysian, flat EPF for non-Malaysian. Remaining: PR status and full category matrix from official rules. | Add validated employee statutory profile and route each scheme by eligibility. | Top-level and bulk profile tests pass; official category matrix pending |
| API-001 | High | verified | Bulk calculation now shares wage normalization, returns per-row errors, and enforces a 500-employee maximum. | One shared validation boundary; per-row errors; explicit maximum batch size; no crashes on valid JSON shapes. | Malformed and maximum-size request tests pass (domain + HTTP); `mix precommit` passes |
| SEC-003 | High | open | Keys are plaintext, ephemeral, unscoped, and inconsistent across nodes/restarts. | Store only durable hashes and metadata; support owner, scope, expiry, rotation, and audited revocation. | Restart, revocation, scope, and secret-leak tests |
| SEC-004 | High | in_progress | Rate limiter is a single-node atomic GenServer with rolling-window retry duration; restart still resets counters. | Use durable or explicitly single-node atomic counters matching documented quota semantics. | Concurrent quota, key isolation, and retry-window tests pass; restart behavior documented but not directly tested |
| API-002 | High | in_progress | PDF content stream and xref are now parser-valid, but payslip identity, period, numbering, and real endpoint parser test remain absent. | Produce parser-valid PDF with extractable payslip text and required payroll identity fields. | `pdfinfo`/`pdftotext` manual check passes; automated parser test pending |

## Important Follow-Up

| ID | Severity | Status | Finding | Minimal acceptance criteria | Verification |
|---|---|---|---|---|---|
| API-003 | Medium | verified | Numeric parsers reject trailing garbage at every boundary; children/wage parse completely or return structured errors. | Require complete parse; return structured validation errors. | Tests for `5000abc`, `2026junk`, negative/fractional children pass (api_controller_test.exs) |
| PAY-007 | High | verified | Zero wage now rejected at domain and API boundaries; bulk rows get per-row errors instead of impossible negative payslips. | Define valid zero-wage behavior from official rules and reject impossible payroll outcomes. | Zero and lower-bound tests pass (payslip_test.exs, api_controller_test.exs) |
| UI-001 | Medium | verified | LiveView defaults omitted HRDF checkbox to false. | LiveView normalization handles omitted checkbox as false without crashing. | LiveView interaction test passes (calculator_live_test.exs) |
| UI-002 | Medium | verified | LiveView uses `<Layouts.app>`, `to_form/2`, `<.form>`, `<.input>`, and key IDs; interaction tests now cover render, submit, error, and omitted-checkbox paths. | Use Phoenix 1.8 form/layout conventions with tested IDs. | `mix test` passes; LiveView interaction tests added (calculator_live_test.exs, 7 tests) |
| UI-003 | High | in_progress | Landing page, separate `/calculator` playground, navigation, and redesigned `/api-docs` now exist; responsive/accessibility interaction coverage and screenshot review remain. | Build responsive landing page, API playground, trust/source messaging, clear docs CTA, and modern visual system without adding a UI framework. | `mix test`/`mix precommit` pass; browser/mobile review and screenshot review pending |
| ARCH-001 | Medium | open | Web layer calls internal calculators, PDF, keys, and raw ETS directly. | Use existing `PayrollApi` module as thin public context; keep storage internals private. | Compile plus focused context/controller tests |
| ARCH-002 | Medium | in_progress | Parsing and error mapping differ across API, bulk, PDF, and LiveView. | One input normalization policy and stable public error mapper. | Wage/children parsing now shared across single, bulk, and PDF boundaries; LiveView still has its own inline parse |
| DOC-001 | Medium | in_progress | OpenAPI now documents bulk employee profiles, PDF HRDF option, and key deletion error statuses; route/schema parser-depth and README/changelog drift review remain. | Make OpenAPI canonical; align routes, auth, schemas, examples, and versions. | OpenAPI contract tests pass; key error contract tests pass; README/changelog drift review pending |
| OPS-001 | Medium | open | Health endpoint is liveness-only and production may start without usable API key. | Fail invalid production configuration at startup; add separate readiness checks. | Production-config and readiness tests |
| OPS-002 | Medium | open | Claimed release/systemd deployment lacks repository artifacts, CI, runbook, or rollback process. | Add reproducible release/deployment artifacts or remove claims. | CI release smoke test |
| OPS-003 | Medium | open | Metrics exist without reporter; security/payroll audit events are absent. | Choose reporter and actionable signals, or remove unused telemetry until needed; persist security audit events before production. | Reporter smoke test and audit-event tests |
| TEST-001 | High | open | Tests validate internal formulas rather than official statutory results. | Add release-gating known-answer and boundary suites from official sources. | Focused statutory suites plus `mix precommit` |
| TEST-002 | Medium | in_progress | Keys, limiter, LiveView, PDF validity, malformed bulk input, and OpenAPI drift lacked tests. | Add focused boundary tests before expanding unit-test volume. | Added: key authorization (8), rate limiter (3), LiveView (7), money (10), OpenAPI contract (6), malformed input, zero-wage; PDF parser test still pending |
| TEST-003 | Medium | verified | Removed unreachable `humanize/1` warning and restored fallback handling. | Remove or make clause reachable without suppressing warning. | `mix precommit` exits 0 |

## Cleanup Candidates

Cleanup follows correctness and security work unless deletion removes active risk.

| ID | Priority | Status | Candidate | Estimated reduction |
|---|---|---|---|---:|
| ARCH-003 | Low | open | Delete unreachable generated Phoenix home page and action. | about 202 lines |
| ARCH-004 | Low | verified | Removed duplicate digested OpenAPI artifact (`openapi-2ae06d...yaml`) that carried stale EPF direction and missing profile fields. | 245 lines |
| ARCH-005 | Low | open | Remove unused telemetry process/dependencies if no reporter is planned. | about 71 lines, 2 dependencies |
| ARCH-006 | Low | open | Retain only used core components and remove forbidden DaisyUI code. | about 250-350 lines, 1 dependency |
| ARCH-007 | Low | open | Remove unused generated extension points and comments. | about 40-70 lines |
| ARCH-008 | Low | open | Remove translated response-label payload if not contractual. | about 65-95 lines |

Conservative cleanup ceiling: **808-938 lines and 3 direct dependencies** (remains after ARCH-004 completion).

## Verified Findings

| ID | Status | Verification |
|---|---|---|
| SEC-001 | verified | Key authorization: 401 (no key), 403 (plain key), 200 (master key) across GET/POST/DELETE; master key cannot be deleted. `key_controller_test.exs` |
| SEC-004 | in_progress | Rate limiter atomic: concurrent checks with no lost updates; quota enforcement, per-key independence, and rolling retry duration tested. Restart persistence remains explicitly unsupported and untested. `rate_limiter_test.exs` |
| PAY-003 | verified | Unsupported/malformed years rejected at domain and API boundaries. |
| PAY-006 | in_progress | Age/citizenship profile reaches top-level and bulk payslip paths; PR and full official category matrix remain open. |
| PAY-007 | verified | Zero wage rejected at domain and API; bulk row errors; no negative payslips. |
| API-001 | verified | Bulk shares wage normalization, per-row errors, 500-employee max enforced at domain and HTTP. |
| API-003 | verified | Trailing garbage in wage/children/year rejected; complete numeric strings accepted. |
| UI-001 | verified | Omitted HRDF checkbox handled as false without crashing. |
| UI-002 | verified | LiveView render/submit/error/omitted-checkbox interaction tests pass. |
| TEST-003 | verified | `humanize/1` warning removed; `mix precommit` exits 0. |
| ARCH-004 | verified | Stale digested OpenAPI artifact removed from repo. |

## Latest Verification Baseline

| Date | Command | Result |
|---|---|---|
| 2026-08-09 | `mix test` | 105 tests passed |
| 2026-08-09 | `mix precommit` | Passed (compile --warnings-as-errors, format, 105 tests) |
| 2026-08-08 | `mix hex.audit` | No retired or security-advisory packages found |
| 2026-08-08 | `mix deps.audit` | Task unavailable |

## Recent Changes (2026-08-09, remediation pass 2)

- **PAY-007**: Zero wage rejected at domain (`:zero_wage`) and API boundaries; bulk rows return per-row errors. Friendly LiveView message added.
- **API-003**: `parse_children/1` strict — trailing garbage (`2abc`, `2.5`) and negatives rejected; shared `parse_wage_value/1` normalizes numeric strings at single + PDF boundaries.
- **API-001**: Bulk capped at 500 employees (`:bulk_too_large`); rows share `normalize_wage/1`; non-map rows return `:invalid_input`.
- **PAY-006**: Bulk rows now preserve and normalize `citizenship`, `age_60_plus`, `spouse_eligible`, and `hrdf_category` profiles.
- **SEC-004**: Rate limiter rewritten as single-node atomic GenServer (no ETS read/filter/write races); documented restart semantics.
- **SEC-004**: Rate-limited responses now report actual rolling-window recovery seconds through `Retry-After`.
- **SEC-001**: Full route authorization tests (401/403/200) for key admin endpoints.
- **SEC-002**: Cross-tenant behavior pinned by tests; limitation already documented in `ApiKeyAuth` + `Keys` moduledocs.
- **PAY-004**: PCB migrated to integer-sen (annual tax, monthly PCB with half-up rounding); payslip aggregation sums in sen; `Money` unit tests added.
- **PAY-006**: SOCSO Category 2 (60+), EIS eligibility (zero for 60+/non-Malaysian), flat EPF for non-Malaysian reach the payslip.
- **UI-002**: Calculator LiveView interaction tests (render, submit, error, omitted checkbox, zero wage) + landing/docs coverage.
- **DOC-001**: OpenAPI canonical — bulk, PDF, openapi endpoints added; SOCSO/EIS bracket schema fixed (ceiling RM6,000); EPF direction corrected; `/keys/{key}` matches router; contract tests added.
- **DOC-001**: Bulk employee profile fields, PDF `include_hrdf`, and key deletion `404`/`422` responses aligned with OpenAPI.
- **ARCH-004**: Stale digested OpenAPI artifact removed.
- **TEST-002**: +52 tests across key auth, rate limiter, LiveView, Money, OpenAPI contract, malformed input, zero-wage, and bulk statutory profiles.

Remaining release blockers: official KWSP Third Schedule implementation, official LHDN MTD scope, durable tenant-aware credentials/data, official HRD Corp eligibility, full scheme-specific rounding known-answer suites, automated PDF parser test, and deployment/operations controls.

## Remediation Pass Results (2026-08-09)

- Domain and API unsupported-year fallback removed; PCB receives selected rate snapshot.
- Master-key plug now uses same environment/application-config lookup as key seeding and constant-time comparison.
- PDF content stream now uses PDF text operators; xref points to xref start; `pdfinfo` and `pdftotext` parse generated output.
- API and LiveView reject trailing numeric garbage.
- LiveView handles omitted HRDF checkbox and uses Phoenix form/layout components with stable key IDs.
- Bulk calculation returns row errors for non-map employees; negative children reject.
- HRDF mode selection supports `standard_1pct`, `reduced_0_5pct`, and `exempt`; official eligibility and wage-base rules remain open.
- Integer-sen helper now drives EPF/HRDF percentage calculations; PCB and full aggregation still need migration.
- `mix test` and `mix precommit` pass with 52 tests.

Remaining release blockers: official KWSP Third Schedule implementation, official LHDN MTD scope, durable tenant-aware credentials/data, full integer-sen and scheme-specific rounding, automated PDF parser test, bulk limits, LiveView interaction tests, and deployment/operations controls.

PCB remediation: selected rate snapshots now carry PCB brackets/reliefs/rebates; `spouse_eligible` controls spouse relief instead of `married`; negative children reject. YTD remuneration, previous PCB, remaining months, zakat, CP38, residency, and additional-remuneration Method 2 remain open.

Product completion baseline (2026-08-09, after remediation pass 2):

- Basic calculation demo: **80%**
- Narrow stateless statutory API: **62%**
- Production-ready statutory payroll API: **52%**
- Complete employer payroll system: **below 25%**
- Working prototype: **yes**
- Safe for real payroll: **no**

Next major phase: UI-first product modernization. Scope and research brief live in [`ui-modernization-brief.md`](ui-modernization-brief.md).
