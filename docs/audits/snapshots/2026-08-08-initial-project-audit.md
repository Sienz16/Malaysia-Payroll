# Initial Project Audit

Audit date: 2026-08-08
Repository: Malaysia-Payroll
Audit type: product coverage, statutory correctness, architecture, security, tests, and production readiness
Change policy: snapshot is immutable; track remediation in [`../current-backlog.md`](../current-backlog.md)

## Executive Verdict

Production use is blocked. Repository is a useful statutory-calculation prototype, not a completed Malaysia payroll system.

| Target | Estimated completion |
|---|---:|
| Calculation demo | 65-70% |
| Claimed sprint scope | 55-60% |
| Production statutory payroll API | 45% |
| Full employer payroll system | below 25% |

Code is not broadly spaghetti. Core modules are small and mostly readable. Main risks are statutory correctness, authorization, persistence, validation, and inaccurate completion claims.

## Weighted Completion Rubric

| Area | Weight | Earned | Evidence summary |
|---|---:|---:|---|
| Statutory correctness and coverage | 35 | 18 | SOCSO/EIS tables exist; EPF is materially wrong; PCB and HRDF are incomplete |
| Calculation and API workflows | 20 | 14 | Single, bulk, rates, labels, and PDF routes exist; validation and PDF are weak |
| Persistence and payroll lifecycle | 15 | 2 | No Repo, schemas, migrations, payroll runs, history, or YTD state |
| Documentation and API contract | 10 | 4 | Multiple docs exist but disagree with routes and runtime behavior |
| Web UI | 8 | 3 | Basic calculator only; incomplete profile and untested interactions |
| Security and production operations | 8 | 4 | Bearer auth, HSTS, health, and quota prototype exist; authorization and durability are unsafe |
| External/statutory integrations | 4 | 0 | No filing, payment, bank, accounting, or agency integration |
| **Total** | **100** | **45** | Production statutory API estimate |

## Critical Findings

### PAY-001: EPF calculation is not statutorily safe

Evidence:

- `lib/payroll_api/statutory/rates.ex:245-250`
- `lib/payroll_api/statutory/rates.ex:295-305`
- `test/statutory/rates_test.exs:6-18`

Code applies 12% employer contribution below RM5,000 and 13% at or above RM5,000. Applicable current rules generally use 13% at RM5,000 and below and 12% above RM5,000 for Malaysian employees below 60. More importantly, unrestricted percentage arithmetic does not implement mandatory KWSP Third Schedule wage bands and rounding.

Impact: wrong employer liability, employee contribution, net pay, accounting, and remittance. Existing tests preserve current assumptions rather than proving official correctness.

### PAY-002: PCB is simplified annual tax divided by 12

Evidence:

- `lib/payroll_api/statutory/pcb.ex:3-18`
- `lib/payroll_api/statutory/pcb.ex:86-117`
- `test/statutory/pcb_test.exs:6-75`

Missing material MTD rules include YTD remuneration and PCB, prior-employer data, remaining months, additional remuneration Method 2, bonuses, benefits-in-kind, zakat, CP38, residency, spouse eligibility, detailed relief categories, and mid-year joining/leaving.

Impact: potentially large tax under- or over-deduction. Tests validate internal annual-tax arithmetic, not official LHDN MTD examples.

### SEC-001: Every API key has key-administration power

Evidence:

- `lib/payroll_api_web/router.ex:31-42`
- `lib/payroll_api_web/controllers/key_controller.ex:6-36`
- `lib/payroll_api/keys.ex:37-60`

Calculation and key-management endpoints share one authentication pipeline. No admin role or credential scope exists. Any valid key can list key metadata, create unlimited keys, and attempt revocation.

### SEC-002: No tenant isolation exists

No employer, organization, account, user, role, owner, or tenant identifier exists. Current credential state is global. Persistent employee/payroll data cannot safely be added behind this model.

### DATA-001: Claimed employee persistence does not exist

Evidence:

- `mix.exs:41-69`
- `lib/payroll_api.ex:1-9`
- `lib/payroll_api/application.ex:9-20`
- `SPRINT_PLAN.md:96-103`

No Ecto dependency, Repo, schema, migration, DB configuration, employer profile, employee profile, payroll run, payslip history, YTD balance, audit record, or statutory submission state exists.

## High-Risk Correctness Findings

### PAY-003: Year fallback mislabels calculations

`lib/payroll_api/statutory/rates.ex:278-282` silently returns default 2026 rates for unsupported years. `lib/payroll_api/statutory/payslip.ex:78-97` reports caller-provided year. PCB separately loads default rates in `lib/payroll_api/statutory/pcb.ex:95-100`.

### PAY-004: Binary floats represent payroll money

Float arithmetic and duplicated rounding policies appear throughout:

- `lib/payroll_api/statutory/rates.ex:299-361`
- `lib/payroll_api/statutory/pcb.ex:63-123`
- `lib/payroll_api/statutory/payslip.ex:89-124`

Exact integer sen plus scheme-specific rounding is required for reproducible statutory results.

### PAY-005: HRDF eligibility is oversimplified

Only `include_hrdf` exists, defaulting to 1%. No registration, sector, Malaysian employee count, non-applicability, optional 0.5% category, or covered allowance base exists.

### PAY-006: Employee statutory categories are not modeled

SOCSO Category 2 exists internally but cannot reach payslip orchestration. No age, citizenship, PR status, foreign-worker category, EPF category, or EIS eligibility input exists.

### PAY-007: Zero wage creates impossible deductions

Zero wage is accepted and selects first SOCSO/EIS brackets, producing deductions and negative net pay.

### API-001: Bulk endpoint is unsafe

Evidence:

- `lib/payroll_api_web/controllers/api_controller.ex:39-47`
- `lib/payroll_api/statutory/payslip.ex:42-76`

Bulk input bypasses single-request normalization. Primitive entries, string children, and truthy string booleans can crash or miscalculate. No maximum employee count exists.

### API-002: PDF generator is structurally unreliable

Evidence:

- `lib/payroll_api/pdf.ex:55-89`
- `test/payroll_api_web/controllers/api_controller_test.exs:53-62`

Content stream lacks PDF text operators. `startxref` points after xref rather than its beginning. Test checks marker strings, not parser validity or extracted text.

### SEC-003: Credential storage is ephemeral and plaintext

Keys live in local ETS without hashes, owner, scope, expiry, durable revocation, or cross-node consistency. Raw secret appears in DELETE URL path and may enter logs and traces.

### SEC-004: Rate limiting is not trustworthy

`lib/payroll_api/rate_limiter.ex:20-48` uses a non-atomic ETS read/filter/write cycle and stores every timestamp. Concurrent requests can lose updates; restart and multiple nodes reset or multiply allowance.

## Architecture Assessment

### Strengths

- Domain calculation functions are mostly pure.
- Statutory tables are explicit and source-annotated.
- Payslip orchestration is readable.
- Router and supervision tree are small.
- No unnecessary service, repository, interface, or factory hierarchy exists.

### Smells

- Empty `PayrollApi` context leaves web code coupled to calculators, PDF, keys, and raw ETS.
- `KeyController` reads internal ETS tuple shape directly.
- Parsing differs between single, bulk, PDF, and LiveView entry points.
- Error mapping is duplicated and exposes inspected internal reasons.
- PCB tax data is outside year snapshots despite data-only update claims.
- Money formatting and default-year constants are duplicated.
- README, docs page, OpenAPI, router, changelog, and runtime behavior require manual synchronization and have drifted.
- LiveView bypasses required layout/form components and stable DOM IDs.
- Inline root-layout JavaScript violates bundled asset conventions.

Broad module splitting is not recommended. Add only thin trust/domain boundaries and delete dead generated code.

## Missing Product Work

1. Official effective-dated EPF schedules, categories, and rounding.
2. Official LHDN computerized MTD or explicit removal of production PCB claims.
3. Full SOCSO/EIS eligibility and boundary validation.
4. HRDF employer applicability and 0.5%/1% categories.
5. Exact money representation.
6. Shared payroll input validation.
7. Separate administrative authorization.
8. Employer tenancy and scoped users/credentials.
9. Durable employer, employee, payroll-period, payroll-run, and YTD data.
10. Earnings, overtime, allowance, commission, bonus, arrears, BIK, deductions, unpaid leave, and proration.
11. Approval, locking, rerun, reversal, and immutable audit history.
12. Valid stored/distributed payslips.
13. Bank payment, accounting export, and statutory submission outputs.
14. EA/EC forms and payroll registers.
15. CI, reproducible deployment, readiness, monitoring, alerting, rotation, rollback, and incident runbooks.
16. PDPA retention, access, redaction, breach, and data-processing controls.

## Missing Test Gates

- Official KWSP known-answer examples and every threshold.
- Official LHDN ordinary/additional remuneration MTD examples.
- SOCSO/EIS every bracket edge, zero wage, ceilings, and Category 2.
- HRDF non-covered, 0.5%, and 1% scenarios.
- Unsupported/malformed year and profile inputs.
- Bulk primitive, null, malformed, and maximum-size cases.
- Admin versus calculation-key authorization.
- Concurrent and restart quota behavior.
- LiveView unchecked-checkbox interaction.
- Real PDF parsing and text extraction.
- OpenAPI-to-router contract checks.
- Production startup and readiness checks.

## Documentation Drift

- Docs page says no authentication while routes require Bearer auth.
- OpenAPI omits bulk and PDF endpoints.
- OpenAPI DELETE key path does not match router.
- OpenAPI SOCSO/EIS schema and ceilings are stale.
- README response examples disagree with current tests.
- Mix, OpenAPI, changelog, and statutory rate versions disagree.
- Sprint plan marks persistence, CORS, and deployment work complete without repository evidence.

## Cleanup Ceiling

Potential cleanup after correctness/security work:

- dead generated home page/action: about 202 lines;
- duplicate digested OpenAPI artifact: 245 lines;
- unused telemetry without reporter: about 71 lines and 2 dependencies;
- unused generated components/DaisyUI: about 250-350 lines and 1 dependency;
- generated comments/extension points: about 40-70 lines;
- translated response labels, if non-contractual: about 65-95 lines.

Conservative total: **808-938 lines and 3 direct dependencies**.

## Verification Evidence

Executed on 2026-08-08:

| Command | Result |
|---|---|
| `mix test` | 38 tests passed |
| `mix hex.audit` | No retired or security-advisory packages found |
| `mix precommit` | Failed because unreachable `humanize/1` clause is a warning-as-error at `lib/payroll_api_web/live/payroll_live.ex:35` |
| `mix deps.audit` | Mix task unavailable |

Passing tests do not establish statutory correctness. Current tests largely validate implementation against its own formulas.

## Release Gate

Do not process real payroll or expose multi-customer key management until:

1. EPF schedules and category rules are corrected and officially validated.
2. PCB is completed and officially validated or removed from production claims.
3. Tenant-aware administrative authorization exists.
4. Unsupported years and malformed profiles fail closed.
5. HRDF, SOCSO, EIS, EPF, age, citizenship, and eligibility are modeled.
6. Exact monetary representation and scheme-specific rounding exist.
7. Keys and quotas are durable, scoped, auditable, and deployment-consistent.
8. Bulk limits and complete validation prevent crashes and abuse.
9. Official known-answer suites become release gates.
10. Deployment, readiness, telemetry, alerting, and operational procedures are reproducible.
