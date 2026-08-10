# Current Audit Backlog

Last broad audit: 2026-08-10
Source: [`snapshots/2026-08-08-initial-project-audit.md`](snapshots/2026-08-08-initial-project-audit.md)

## Rules

- Keep finding IDs stable.
- Do not mark statutory findings verified without official known-answer evidence.
- Do not mark findings verified while `mix precommit` fails.

## Blocked Statutory Work

| ID | Severity | Status | Finding | Minimal acceptance criteria | Verification |
|---|---|---|---|---|---|
| PAY-001 | Critical | blocked | KWSP Third Schedule is a 55-page scanned PDF. Exact wage bands, categories, and rounding need verified transcription. | Effective-dated schedule data and official known-answer tests. | Official source retrieved; no reliable table extraction available |
| PAY-002 | Critical | blocked | PCB remains simplified Method 1. | Official LHDN MTD specification and ordinary/additional remuneration examples. | Selected-year and focused PCB tests pass |
| PAY-004 | High | blocked | Scheme rounding needs official boundary evidence. | Official boundary known-answer suite. | Integer-sen calculations covered by unit tests |
| PAY-005 | High | blocked | HRD Corp eligibility and wage-base rules need primary guidance. | Official eligibility rules and known-answer tests. | Declared rate-category tests pass |
| PAY-006 | High | blocked | Employee statutory profile lacks official PR/category matrix. | Official matrix and known-answer tests. | Current Malaysian/non-Malaysian/60+ paths tested |
| TEST-001 | High | blocked | Internal formula tests are not official statutory result tests. | Release-gating official known-answer suites. | `mix precommit` passes |

## Deferred By Scope

| ID | Severity | Status | Finding | Minimal acceptance criteria | Verification |
|---|---|---|---|---|---|
| SEC-004 | High | wont_fix | In-memory IP limiter resets on restart and is single-node. | Add gateway/distributed limits only for multi-node or quota requirements. | Explicitly documented in `docs/deployment.md` |
| API-002 | High | wont_fix | Identity, period, and payslip number require stored payroll data. | Add fields with persistence and tenant ownership design. | Endpoint PDF parser test passes |
| UI-003 | High | deferred | Responsive screenshot and browser accessibility review require browser/staging review. | Run desktop/tablet/mobile and keyboard checks. | LiveView interaction tests pass |
| OPS-004 | High | deferred | Parser limits, loopback bind, and proxy boundary docs are present; real ingress verification needs deployment. | Verify proxy-only ingress, HTTPS redirect, HSTS, and firewall on staging. | `docs/deployment.md` |
| SEC-006 | High | deferred | `force_ssl` trusts proxy header under documented proxy-only ingress model. | Verify network isolation on staging. | `docs/deployment.md` |
| OPS-001 | Medium | deferred | Readiness endpoint exists; production release needs real-host probe. | Probe `/api/v1/ready` after deployment. | Controller test passes |
| OPS-002 | Medium | deferred | Release/rollback runbook exists; CI and deployment environment are not configured. | Add CI release smoke test after deployment target exists. | `docs/deployment.md` |

## Verified Current Scope

| ID | Status | Verification |
|---|---|---|
| SEC-001, SEC-002, SEC-003, DATA-001 | verified | Public stateless API has no credentials, key administration, tenant data, or employee persistence claims. |
| PAY-003, PAY-007 | verified | Year and zero-wage boundaries reject at domain and API boundaries. |
| API-001, API-003 | verified | Bulk cap, per-row errors, and strict shared wage parsing covered by HTTP/domain tests. |
| DOC-001, DOC-002 | verified | Router, README, OpenAPI, changelog, and public API behavior align. |
| OPS-003 | verified | Removed unused telemetry reporter dependencies/process. |
| ARCH-003 to ARCH-006 | verified | Removed unreachable home, stale OpenAPI artifact, telemetry scaffolding, and unused generated UI helpers. |

## Latest Verification Baseline

| Date | Command | Result |
|---|---|---|
| 2026-08-10 | `mix precommit` | Passed (compile --warnings-as-errors, format, 97 tests) |
| 2026-08-08 | `mix hex.audit` | No retired or security-advisory packages found |

## Completion Baseline

- Working stateless public prototype: **yes**
- Safe for real payroll filing: **no**
- Remaining code audit work: blocked statutory source validation only
- Deferred environment verification: deployment proxy/HTTPS and browser responsive review
