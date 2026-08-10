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
| PAY-002 | Critical | blocked | PCB remains simplified Method 1. | Official LHDN MTD specification and ordinary/additional remuneration examples. | `hasil.gov.my` unreachable from the build environment (connections time out; likely geo-restricted). Target file identified: `spesifikasi-kaedah-pengiraan-berkomputer-pcb-2026.pdf`. Needs manual retrieval. |
| PAY-004 | High | blocked | Rounding apportionment above RM20,000 needs official evidence. | Official boundary known-answer suite. | Schedule states only "total rounded to the next ringgit"; which side absorbs it is an assumption — see `round_epf_total/2`. |
| PAY-005 | High | blocked | HRD Corp eligibility and wage-base rules need primary guidance. | Official eligibility rules and known-answer tests. | `hrdcorp.gov.my` reachable; not yet retrieved. |

### Cleared

| ID | Finding | Resolution |
|---|---|---|
| PAY-001 | KWSP Third Schedule assumed to be a scanned PDF. | **Assumption was wrong** — the 1 October 2025 edition has a clean text layer. Parts A/C/E transcribed to `priv/statutory/epf_third_schedule_2025-10/` (401 bands each), validated for contiguity and printed totals. Percentage-based EPF was confirmed wrong for every wage off a band boundary (RM2,985: was 328.35/388.05, correct 330.00/390.00). |
| PAY-006 | No official PR/category matrix. | Matrix taken from the schedule's own Part definitions. `:permanent_resident` option added; Parts A/C/E/F now selected by citizenship, PR status, and age. Parts B and D confirmed deleted by Act A1760/2025. |
| PAY-008 | EIS (Act 800) table was still the untranscribed prototype. | Source PDF (`151124-Rate Contribution ACT 800.pdf`) is a scanned image with no text layer, so it was transcribed by reading the rendered page directly (200dpi, 6 crops) rather than regex-parsed. All 65 rows transcribed to `priv/statutory/eis_act800_2024-11/rates.csv`, validated by `priv/statutory/tools/extract_eis.py` (component sums, band tiling) the same way as SOCSO. `Schedule.eis/1` replaces the old hardcoded `@eis_brackets`; the transcribed values were identical to the prototype's, so no payslip totals changed. `Rates` now marks `:eis` verified. |
| PAY-009 | Rates were keyed by year only; SKBBK began mid-year (1 June 2026) and a year can't express that. | `Rates.rates/2` accepts an optional `month` (and the API a `month` param on `/rates`, `/calculate-payslip`, `/calculate-payslip/bulk`, `/payslip.pdf`); a stated period before 1 June 2026 gets `{:error, :period_not_covered}` instead of a silently wrong SOCSO figure. This is a refusal, not a real superseded-edition system — pre-June-2026 SOCSO and pre-October-2025 EPF still can't be *served* correctly, only declined. `rates/1` without a month is unchanged (still "2026 as current law"). |
| TEST-001 | Internal formula tests only. | `test/statutory/schedule_test.exs` plus known-answer tests in `rates_test.exs` assert values read directly off the source documents, with band citations in comments. |

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

## New Findings

| ID | Severity | Status | Finding |
|---|---|---|---|
| PAY-007b | Critical | fixed | SOCSO omitted SKBBK (Lindung 24 Jam) entirely. Mandatory since 1 June 2026 at 0.75% employee, ceiling RM6,000. Employee share was under-deducted by up to RM44.65/month/head, and Category 2 (60+) was returning a zero employee share when SKBBK does apply. Table replaced from the official PERKESO Act 4 source. |
| TEST-002 | Medium | open | 4 `CalculatorLiveTest` failures exist on `main`, predating this work. The "Latest Verification Baseline" below claimed `mix precommit` passed with 97 tests; it does not currently pass. |

## Latest Verification Baseline

| Date | Command | Result |
|---|---|---|
| 2026-08-10 | `mix test` | 121/123. The 2 failures are pre-existing `CalculatorLiveTest` cases (TEST-002), unrelated to statutory work — confirmed by stashing this change and re-running (also 2 failures on unmodified `main`). |
| 2026-08-10 | `mix compile --warnings-as-errors`, `mix format --check-formatted` | Clean |
| 2026-08-08 | `mix hex.audit` | No retired or security-advisory packages found |

## Completion Baseline

- Working stateless public prototype: **yes**
- Safe for real payroll filing: **no**
- EPF, SOCSO and EIS: computed from transcribed official tables, known-answer tested
- PCB and HRDF: still prototype approximations. PCB is the largest deduction
  on most payslips and is not the LHDN MTD algorithm, so a payslip total cannot
  be relied on regardless of EPF/SOCSO/EIS now being correct.
- A stated pre-June-2026 period is refused rather than silently miscalculated
  (PAY-009), but no pre-June-2026 SOCSO / pre-October-2025 EPF figure can yet
  be *served* correctly — only declined.
- Deferred environment verification: deployment proxy/HTTPS and browser responsive review

## Source Documents

Transcribed tables live in `priv/statutory/`. All source PDFs were retrieved
from the issuing authority; none of the sites permit scripted download, so
all were fetched through a browser session (EPF/SOCSO) or supplied directly
(EIS).

| Table | Source | Edition |
|---|---|---|
| `epf_third_schedule_2025-10/part_{a,c,e}.csv` | KWSP Third Schedule, EPF Act 1991 | Effective 1 October 2025 |
| `socso_act4_2026-06/rates.csv` | PERKESO Act 4 contribution table incl. SKBBK | Effective 1 June 2026 |
| `eis_act800_2024-11/rates.csv` | PERKESO Act 800 (EIS) Second Schedule | `151124-Rate Contribution ACT 800.pdf` — scanned page, no text layer, transcribed from the rendered image |

Re-transcription is scripted and validating: extraction refuses to emit a table
whose printed components do not sum to their printed totals, or whose bands do
not tile their range without gap or overlap.
