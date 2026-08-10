# Current Audit Backlog

Last broad audit: 2026-08-10 (reconciled against code after 2026-08-10 statutory updates)
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
| PAY-003 | High | open | Omitted `month` still permits 2025 calculation using current-law tables; only a stated historical period is refused. | Require an explicit covered period, or mark omitted-period results as current-law estimates. | `Rates.rates(2025)` and `Payslip.calculate(%{year: 2025})` succeed without period validation. |
| PAY-005 | High | open | Bulk request-level `hrdf_category` is parsed but discarded; only per-row categories take effect. | Preserve request default unless a row explicitly overrides it; add bulk HTTP/domain regression tests. | `ApiController` passes category; `Payslip.calculate_bulk/1` drops it from defaults. |
| PAY-006 | Critical | open | `permanent_resident` selects correct EPF Part in `Rates.epf/3`, but is absent from public single/bulk API and payslip propagation. | Parse, document, and forward PR status through API, bulk, and payslip; add regression tests. | Non-Malaysian PR API requests currently fall back to Part F 2%/2%. |

### Cleared

| ID | Finding | Resolution |
|---|---|---|
| PAY-001 | KWSP Third Schedule assumed to be a scanned PDF. | **Assumption was wrong** — the 1 October 2025 edition has a clean text layer. Parts A/C/E transcribed to `priv/statutory/epf_third_schedule_2025-10/` (401 bands each), validated for contiguity and printed totals. Percentage-based EPF was confirmed wrong for every wage off a band boundary (RM2,985: was 328.35/388.05, correct 330.00/390.00). |
| PAY-006 | No official PR/category matrix. | Matrix taken from the schedule's own Part definitions. `:permanent_resident` option exists in `Rates.epf/3`; public-path propagation remains open. Parts B and D confirmed deleted by Act A1760/2025. |
| PAY-008 | EIS (Act 800) table was still the untranscribed prototype. | Source PDF (`151124-Rate Contribution ACT 800.pdf`) is a scanned image with no text layer, so it was transcribed by reading the rendered page directly (200dpi, 6 crops) rather than regex-parsed. All 65 rows transcribed to `priv/statutory/eis_act800_2024-11/rates.csv`, validated by `priv/statutory/tools/extract_eis.py` (component sums, band tiling) the same way as SOCSO. `Schedule.eis/1` replaces the old hardcoded `@eis_brackets`; the transcribed values were identical to the prototype's, so no payslip totals changed. `Rates` now marks `:eis` verified. |
| PAY-009 | Rates were keyed by year only; SKBBK began mid-year (1 June 2026) and a year can't express that. | `Rates.rates/2` accepts an optional `month` (and the API a `month` param on `/rates`, `/calculate-payslip`, `/calculate-payslip/bulk`, `/payslip.pdf`); a stated period before 1 June 2026 gets `{:error, :period_not_covered}` instead of a silently wrong SOCSO figure. This is a refusal, not a real superseded-edition system — pre-June-2026 SOCSO and pre-October-2025 EPF still can't be *served* correctly, only declined. `rates/1` without a month is unchanged (still "2026 as current law"). |
| PAY-005 | HRD Corp eligibility and wage-base rules had no primary-source citation. | Fetched the PSMB Act 2001 (Akta 612) text directly (`eakta.mohr.gov.my`). Confirmed against ss.14(1)/15(1)-(2): 1% mandatory for 10+ Malaysian employees, 0.5% optional for 5-9, no employee share exists in the Act at all — matches the existing `:standard_1pct`/`:reduced_0_5pct`/`:exempt` rates exactly. Wage base (s.2 "upah"): basic salary + fixed allowances/emoluments paid in cash + leave pay/arrears, excluding retirement-fund contributions, travel allowance/concession, special-expense reimbursement, retrenchment/retirement benefit, bonus, commission, and apprentice allowance — documented on `Rates.hrdf/3`, since this module takes one wage figure with no component breakdown (same as EPF/SOCSO/EIS) and relies on the caller to pass the qualifying wage. `:hrdf` now in `verified_schemes`. |
| TEST-001 | Internal formula tests only. | `test/statutory/schedule_test.exs` plus known-answer tests in `rates_test.exs` assert values read directly off the source documents, with band citations in comments. |
| TEST-002 | 2 `CalculatorLiveTest` failures were intermittently present earlier in this work. | No longer reproduce: `mix test` is 123/123 clean across 3 consecutive runs. Likely stale compiled artifacts earlier in the session, not a real regression — no source change targeted these tests. |

## Deferred By Scope

| ID | Severity | Status | Finding | Minimal acceptance criteria | Verification |
|---|---|---|---|---|---|
| SEC-004 | High | wont_fix | In-memory limiter resets on restart and is single-node; under documented proxy deployment it keys the observed proxy peer IP, not verified end-client IP. | Add gateway/distributed limiting and verified client-IP propagation only for multi-node, quotas, or per-client fairness. | `docs/deployment.md` documents proxy-wide current behavior. |
| API-002 | High | open | PDF parser validation passes, but OpenAPI omits implemented `month`; identity, period, and payslip number remain persistence-dependent. | Document tested period input now; add identity fields only with persistence and tenant ownership design. | Endpoint `pdftotext` test passes; OpenAPI contract drift open. |
| UI-003 | High | partial | Local viewport review was reported; committed tests cover IDs/results only, not accessible names, keyboard flow, contrast, or responsive layout. | Run browser desktop/tablet/mobile, keyboard-only, screen-reader, and contrast checks. | CSS includes focus/reduced-motion rules; no automated browser/a11y coverage. |
| OPS-004 | High | deferred | Parser limits, loopback bind, and proxy boundary docs are present; real ingress verification needs deployment. | Verify proxy-only ingress, HTTPS redirect, HSTS, and firewall on staging. | Config/docs assert intended model; no staging or production-config verification test. |
| SEC-006 | High | deferred | `force_ssl` trusts proxy header under documented proxy-only ingress model. | Verify network isolation and proxy-header behavior on staging. | Config/docs assert intended model; no ingress verification exists. |
| OPS-001 | Medium | deferred | Readiness endpoint exists; current test covers only ready `200`, not unavailable-worker `503` or real-host probe. | Add local unavailable-worker test and probe `/api/v1/ready` after deployment. | Ready controller test passes. |
| OPS-002 | Medium | open | Release/rollback runbook exists, but no CI release smoke test exists; CI does not require a deployment target. | Add CI build/assets/release smoke test. | `mix.exs` and `docs/deployment.md` supply runnable commands. |

## Verified Current Scope

| ID | Status | Verification |
|---|---|---|
| SEC-001, SEC-002, SEC-003, DATA-001 | verified | Public stateless API has no credentials, key administration, tenant data, or employee persistence claims. |
| PAY-003, PAY-007 | verified | Year and zero-wage boundaries reject at domain and API boundaries. |
| API-001, API-003 | verified | Bulk cap, per-row errors, and strict shared wage parsing covered by HTTP/domain tests. |
| DOC-001, DOC-002 | open | Public contract drift: README uses pre-SKBBK totals; README/OpenAPI omit `month` and PR profile; OpenAPI `/rates` schema is stale and needs YAML parse validation. |
| OPS-003 | verified | Removed unused telemetry reporter dependencies/process. |
| ARCH-003 to ARCH-006 | verified | Removed unreachable home, stale OpenAPI artifact, telemetry scaffolding, and unused generated UI helpers. |

## New Findings

| ID | Severity | Status | Finding |
|---|---|---|---|
| PAY-007b | Critical | fixed | SOCSO omitted SKBBK (Lindung 24 Jam) entirely. Mandatory since 1 June 2026 at 0.75% employee, ceiling RM6,000. Employee share was under-deducted by up to RM44.65/month/head, and Category 2 (60+) was returning a zero employee share when SKBBK does apply. Table replaced from the official PERKESO Act 4 source. |
| DOC-003 | Critical | open | OpenAPI YAML structure and `/rates` schema no longer match runtime fields; contract tests only search text and do not parse YAML. |
| DOC-004 | Medium | open | `SPRINT_PLAN.md` still claims removed bearer-key auth and 401 behavior. |

## Latest Verification Baseline

| Date | Command | Result |
|---|---|---|
| 2026-08-10 | `mix test` | 123/123, clean across 3 consecutive runs (TEST-002's earlier 2 failures no longer reproduce). |
| 2026-08-10 | `mix compile --warnings-as-errors`, `mix format --check-formatted` | Clean |
| 2026-08-08 | `mix hex.audit` | No retired or security-advisory packages found |

## Completion Baseline

- Working stateless public prototype: **yes**
- Safe for real payroll filing: **no**
- EPF, SOCSO and EIS: computed from transcribed official tables, known-answer tested
- HRDF: flat percentage confirmed against the PSMB Act 2001 (Akta 612) text directly
- PCB: still a prototype approximation, and not the LHDN MTD algorithm. It's
  the largest deduction on most payslips, so a payslip total cannot be relied
  on regardless of EPF/SOCSO/EIS/HRDF now being correct.
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
