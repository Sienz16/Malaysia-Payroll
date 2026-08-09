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
| PAY-001 | Critical | in_progress | EPF percentage direction corrected, but KWSP Third Schedule schedules and statutory rounding remain absent. | Effective-dated KWSP Third Schedule data, employee categories, official rounding, and known-answer tests replace approximation. | Threshold tests pass; official KWSP validation still required |
| PAY-002 | Critical | open | PCB is annualized simplified tax, not production Malaysian MTD. | Implement and validate required LHDN computerized MTD scope, or remove production PCB claims and expose limitation clearly. | Official LHDN ordinary/additional remuneration examples; `mix precommit` |
| SEC-001 | Critical | in_progress | Key-management routes now require a master key, but route authorization and key-source behavior need full tests and durable credential design. | Separate admin authorization is tested; durable scoped credentials remain required for production. | Master-key configuration test passes; route 401/403 coverage pending |
| SEC-002 | Critical | open | No tenant, owner, role, or authorization boundary exists. | Documented security limitation in `ApiKeyAuth` and `Keys` modules; full tenancy requires persistence layer. | Cross-tenant access tests plus `mix precommit` |
| DATA-001 | Critical | open | Employee persistence is claimed but no Repo, schema, migration, or durable payroll state exists. | Either remove claim or add constrained employer/employee/payroll persistence with tenant ownership and auditability. | Migration/schema tests, restart persistence test, `mix precommit` |
| PAY-003 | High | fixed | Unsupported years now reject at domain and API boundaries; selected rates snapshot reaches PCB. | Reject unsupported years and apply one selected snapshot consistently. | Domain/API malformed-year tests; `mix test` |
| PAY-004 | High | in_progress | Money helper now drives EPF/HRDF percentage calculations, but PCB and aggregate calculations still use floats and statutory rounding is incomplete. | Integer sen and scheme-specific rounding throughout all payroll calculations. | Current tests pass; official boundary and Money unit coverage pending |
| PAY-005 | High | in_progress | HRDF supports declared 1%, 0.5%, and exempt modes, but employer eligibility, wage-base rules, and official category validation remain incomplete. | Model covered wage floor and categories from HRD Corp rules with known-answer tests. | HRDF mode tests pass; official HRD Corp validation pending |
| PAY-006 | High | open | Employee age, citizenship, PR status, foreign-worker category, and SOCSO Category 2 cannot reach payslip calculation. | Add validated employee statutory profile and route each scheme by eligibility. | Category matrix tests |
| API-001 | High | open | Bulk calculation bypasses normalization, allows malformed entries, and has no size limit. | One shared validation boundary; per-row errors; explicit maximum batch size; no crashes on valid JSON shapes. | Malformed and maximum-size request tests |
| SEC-003 | High | open | Keys are plaintext, ephemeral, unscoped, and inconsistent across nodes/restarts. | Store only durable hashes and metadata; support owner, scope, expiry, rotation, and audited revocation. | Restart, revocation, scope, and secret-leak tests |
| SEC-004 | High | open | Rate limiter has lost-update races, linear timestamp storage, and node/restart bypasses. | Use durable or explicitly single-node atomic counters matching documented quota semantics. | Concurrent quota and restart tests |
| API-002 | High | in_progress | PDF content stream and xref are now parser-valid, but payslip identity, period, numbering, and real endpoint parser test remain absent. | Produce parser-valid PDF with extractable payslip text and required payroll identity fields. | `pdfinfo`/`pdftotext` manual check passes; automated parser test pending |

## Important Follow-Up

| ID | Severity | Status | Finding | Minimal acceptance criteria | Verification |
|---|---|---|---|---|---|
| API-003 | Medium | open | Numeric parsers accept trailing garbage and silently substitute defaults. | Require complete parse; return structured validation errors. | Tests for `5000abc`, `2026junk`, negative/fractional children |
| PAY-007 | High | open | Zero wage receives SOCSO/EIS deductions and negative net pay. | Define valid zero-wage behavior from official rules and reject impossible payroll outcomes. | Zero and lower-bound tests |
| UI-001 | Medium | fixed | LiveView now defaults omitted HRDF checkbox to false. | Shared form normalization handles omitted checkbox as false without crashing. | Code path fixed; LiveView interaction test pending |
| UI-002 | Medium | in_progress | LiveView now uses `<Layouts.app>`, `to_form/2`, `<.form>`, `<.input>`, and key IDs; interaction/accessibility tests remain absent. | Use Phoenix 1.8 form/layout conventions with tested IDs. | `mix test` passes; LiveView interaction tests pending |
| ARCH-001 | Medium | open | Web layer calls internal calculators, PDF, keys, and raw ETS directly. | Use existing `PayrollApi` module as thin public context; keep storage internals private. | Compile plus focused context/controller tests |
| ARCH-002 | Medium | open | Parsing and error mapping differ across API, bulk, PDF, and LiveView. | One input normalization policy and stable public error mapper. | Same invalid input yields consistent outcomes on each boundary |
| DOC-001 | Medium | open | README, docs page, OpenAPI, router, versions, and examples disagree. | Make OpenAPI canonical; align routes, auth, schemas, examples, and versions. | Contract test comparing documented and routed endpoints |
| OPS-001 | Medium | open | Health endpoint is liveness-only and production may start without usable API key. | Fail invalid production configuration at startup; add separate readiness checks. | Production-config and readiness tests |
| OPS-002 | Medium | open | Claimed release/systemd deployment lacks repository artifacts, CI, runbook, or rollback process. | Add reproducible release/deployment artifacts or remove claims. | CI release smoke test |
| OPS-003 | Medium | open | Metrics exist without reporter; security/payroll audit events are absent. | Choose reporter and actionable signals, or remove unused telemetry until needed; persist security audit events before production. | Reporter smoke test and audit-event tests |
| TEST-001 | High | open | Tests validate internal formulas rather than official statutory results. | Add release-gating known-answer and boundary suites from official sources. | Focused statutory suites plus `mix precommit` |
| TEST-002 | Medium | open | Keys, limiter, LiveView, PDF validity, malformed bulk input, and OpenAPI drift lack tests. | Add focused boundary tests before expanding unit-test volume. | New tests plus `mix precommit` |
| TEST-003 | Medium | fixed | Removed unreachable `humanize/1` warning and restored fallback handling. | Remove or make clause reachable without suppressing warning. | `mix precommit` exits 0 |

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
| 2026-08-09 | `mix test` | 46 tests passed |
| 2026-08-09 | `mix precommit` | Passed |
| 2026-08-08 | `mix hex.audit` | No retired or security-advisory packages found |
| 2026-08-08 | `mix deps.audit` | Task unavailable |

## Recent Changes (2026-08-09)

- **PAY-001**: Fixed EPF employer rate direction (now 13% at/below RM5,000; 12% above). Still needs official KWSP Third Schedule validation.
- **PAY-003**: Domain/API reject unsupported years; selected rates snapshot reaches PCB.
- **PAY-004**: Integer-sen helper drives EPF/HRDF percentage calculations; full migration remains open.
- **PAY-005**: HRDF mode selection exists; official eligibility and wage-base validation remain open.
- **SEC-001**: Key-management routes use master-key pipeline; route authorization tests remain open.
- **API-002**: PDF syntax now parses and text extracts; automated and identity-field work remains open.
- **TEST-003**: Fixed unreachable `humanize/1` warning; `mix precommit` passes.

Pending: DaisyUI dependency removal blocked by file encoding issues.

## Remediation Pass Results (2026-08-09)

- Domain and API unsupported-year fallback removed; PCB receives selected rate snapshot.
- Master-key plug now uses same environment/application-config lookup as key seeding and constant-time comparison.
- PDF content stream now uses PDF text operators; xref points to xref start; `pdfinfo` and `pdftotext` parse generated output.
- API and LiveView reject trailing numeric garbage.
- LiveView handles omitted HRDF checkbox and uses Phoenix form/layout components with stable key IDs.
- Bulk calculation returns row errors for non-map employees; negative children reject.
- HRDF mode selection supports `standard_1pct`, `reduced_0_5pct`, and `exempt`; official eligibility and wage-base rules remain open.
- Integer-sen helper now drives EPF/HRDF percentage calculations; PCB and full aggregation still need migration.
- `mix test` and `mix precommit` pass with 46 tests.

Remaining release blockers: official KWSP Third Schedule implementation, official LHDN MTD scope, durable tenant-aware credentials/data, full integer-sen and scheme-specific rounding, automated PDF parser test, bulk limits, LiveView interaction tests, and deployment/operations controls.
