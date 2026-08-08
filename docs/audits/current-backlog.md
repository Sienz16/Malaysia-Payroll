# Current Audit Backlog

Last broad audit: 2026-08-08
Source: [`snapshots/2026-08-08-initial-project-audit.md`](snapshots/2026-08-08-initial-project-audit.md)

## Rules

- Keep finding IDs stable.
- Update `Status`, `Verification`, and `Notes` after work.
- Do not mark statutory findings verified without official known-answer evidence.
- Do not mark any finding verified while `mix precommit` fails.

## Release Blockers

| ID | Severity | Status | Finding | Minimal acceptance criteria | Verification |
|---|---|---|---|---|---|
| PAY-001 | Critical | open | EPF employer rates are reversed and percentage arithmetic ignores KWSP schedules. | Effective-dated KWSP Third Schedule data, employee categories, official rounding, and known-answer tests replace approximation. | Official KWSP examples plus all threshold tests; `mix precommit` |
| PAY-002 | Critical | open | PCB is annualized simplified tax, not production Malaysian MTD. | Implement and validate required LHDN computerized MTD scope, or remove production PCB claims and expose limitation clearly. | Official LHDN ordinary/additional remuneration examples; `mix precommit` |
| SEC-001 | Critical | open | Every valid API key can administer all API keys. | Remove key-management API or protect it with separate admin authorization and scoped credentials. | Calculation-only key receives 403 for every key-management route |
| SEC-002 | Critical | open | No tenant, owner, role, or authorization boundary exists. | Define employer tenancy before persistent payroll data; enforce tenant ownership at every data boundary. | Cross-tenant access tests plus `mix precommit` |
| DATA-001 | Critical | open | Employee persistence is claimed but no Repo, schema, migration, or durable payroll state exists. | Either remove claim or add constrained employer/employee/payroll persistence with tenant ownership and auditability. | Migration/schema tests, restart persistence test, `mix precommit` |
| PAY-003 | High | open | Unsupported years silently use 2026 rates while response reports requested year. | Reject unsupported years; pass selected snapshot consistently into EPF, SOCSO, EIS, HRDF, and PCB. | Unsupported-year API and domain tests |
| PAY-004 | High | open | Payroll money uses binary floating-point and generic rounding. | Use integer sen and explicit scheme-specific rounding rules throughout domain calculation. | Boundary/property tests and official examples |
| PAY-005 | High | open | HRDF eligibility is reduced to universal 1% toggle. | Model non-applicability, covered wage base, 0.5%, and 1% employer categories. | HRD Corp known scenarios |
| PAY-006 | High | open | Employee age, citizenship, PR status, foreign-worker category, and SOCSO Category 2 cannot reach payslip calculation. | Add validated employee statutory profile and route each scheme by eligibility. | Category matrix tests |
| API-001 | High | open | Bulk calculation bypasses normalization, allows malformed entries, and has no size limit. | One shared validation boundary; per-row errors; explicit maximum batch size; no crashes on valid JSON shapes. | Malformed and maximum-size request tests |
| SEC-003 | High | open | Keys are plaintext, ephemeral, unscoped, and inconsistent across nodes/restarts. | Store only durable hashes and metadata; support owner, scope, expiry, rotation, and audited revocation. | Restart, revocation, scope, and secret-leak tests |
| SEC-004 | High | open | Rate limiter has lost-update races, linear timestamp storage, and node/restart bypasses. | Use durable or explicitly single-node atomic counters matching documented quota semantics. | Concurrent quota and restart tests |
| API-002 | High | open | Hand-written PDF output has invalid content stream and incorrect `startxref`. | Produce parser-valid PDF with extractable payslip text and required payroll identity fields. | Real PDF parser/text extraction test |

## Important Follow-Up

| ID | Severity | Status | Finding | Minimal acceptance criteria | Verification |
|---|---|---|---|---|---|
| API-003 | Medium | open | Numeric parsers accept trailing garbage and silently substitute defaults. | Require complete parse; return structured validation errors. | Tests for `5000abc`, `2026junk`, negative/fractional children |
| PAY-007 | High | open | Zero wage receives SOCSO/EIS deductions and negative net pay. | Define valid zero-wage behavior from official rules and reject impossible payroll outcomes. | Zero and lower-bound tests |
| UI-001 | Medium | open | Unchecked HRDF checkbox can miss LiveView handler clause. | Shared form normalization handles omitted checkbox as false without crashing. | LiveView submit test with checkbox unchecked |
| UI-002 | Medium | open | LiveView bypasses project layout/form conventions and lacks stable DOM IDs. | Use `<Layouts.app>`, `to_form/2`, `<.form>`, `<.input>`, and tested IDs. | LiveView mount and interaction tests |
| ARCH-001 | Medium | open | Web layer calls internal calculators, PDF, keys, and raw ETS directly. | Use existing `PayrollApi` module as thin public context; keep storage internals private. | Compile plus focused context/controller tests |
| ARCH-002 | Medium | open | Parsing and error mapping differ across API, bulk, PDF, and LiveView. | One input normalization policy and stable public error mapper. | Same invalid input yields consistent outcomes on each boundary |
| DOC-001 | Medium | open | README, docs page, OpenAPI, router, versions, and examples disagree. | Make OpenAPI canonical; align routes, auth, schemas, examples, and versions. | Contract test comparing documented and routed endpoints |
| OPS-001 | Medium | open | Health endpoint is liveness-only and production may start without usable API key. | Fail invalid production configuration at startup; add separate readiness checks. | Production-config and readiness tests |
| OPS-002 | Medium | open | Claimed release/systemd deployment lacks repository artifacts, CI, runbook, or rollback process. | Add reproducible release/deployment artifacts or remove claims. | CI release smoke test |
| OPS-003 | Medium | open | Metrics exist without reporter; security/payroll audit events are absent. | Choose reporter and actionable signals, or remove unused telemetry until needed; persist security audit events before production. | Reporter smoke test and audit-event tests |
| TEST-001 | High | open | Tests validate internal formulas rather than official statutory results. | Add release-gating known-answer and boundary suites from official sources. | Focused statutory suites plus `mix precommit` |
| TEST-002 | Medium | open | Keys, limiter, LiveView, PDF validity, malformed bulk input, and OpenAPI drift lack tests. | Add focused boundary tests before expanding unit-test volume. | New tests plus `mix precommit` |
| TEST-003 | Medium | open | Project gate fails on unreachable `humanize/1` clause. | Remove or make clause reachable without suppressing warning. | `mix precommit` exits 0 |

## Cleanup Candidates

Cleanup follows correctness and security work unless deletion removes active risk.

| ID | Priority | Status | Candidate | Estimated reduction |
|---|---|---|---|---:|
| ARCH-003 | Low | open | Delete unreachable generated Phoenix home page and action. | about 202 lines |
| ARCH-004 | Low | open | Stop tracking duplicate digested OpenAPI artifact. | 245 lines |
| ARCH-005 | Low | open | Remove unused telemetry process/dependencies if no reporter is planned. | about 71 lines, 2 dependencies |
| ARCH-006 | Low | open | Retain only used core components and remove forbidden DaisyUI code. | about 250-350 lines, 1 dependency |
| ARCH-007 | Low | open | Remove unused generated extension points and comments. | about 40-70 lines |
| ARCH-008 | Low | open | Remove translated response-label payload if not contractual. | about 65-95 lines |

Conservative cleanup ceiling: **808-938 lines and 3 direct dependencies**.

## Verified Findings

None yet.

## Latest Verification Baseline

| Date | Command | Result |
|---|---|---|
| 2026-08-08 | `mix test` | 38 tests passed |
| 2026-08-08 | `mix hex.audit` | No retired or security-advisory packages found |
| 2026-08-08 | `mix precommit` | Failed: unreachable `humanize/1` clause in `lib/payroll_api_web/live/payroll_live.ex:35` |
| 2026-08-08 | `mix deps.audit` | Task unavailable |
