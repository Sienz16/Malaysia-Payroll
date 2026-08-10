# 🇲🇾 Malaysia Payroll Statutory API

**EPF · SOCSO · EIS · HRDF · PCB** — Malaysian statutory payroll calculations as a clean REST API. Built with Phoenix 1.8.9 / Elixir 1.18.

> Stateless statutory calculation prototype with explicit source and compliance limitations.

---

## ✨ Features

| Endpoint | Description |
|---|---|
| `GET /api/v1/health` | Liveness probe (public) |
| `GET /api/v1/ready` | Readiness probe (public) |
| `GET /api/v1/rates` | Current statutory rate tables (EPF/SOCSO/EIS/HRDF, min wage) |
| `POST /api/v1/calculate-payslip` | Statutory breakdown: EPF + SOCSO + EIS + HRDF + simplified PCB |
| `POST /api/v1/calculate-payslip/bulk` | Calculate up to 500 employee rows |
| `GET /api/v1/payslip.pdf` | Download sample PDF output |
| `GET /api/v1/openapi.yaml` | OpenAPI contract (public) |

## 🚀 Quickstart

```bash
# 1. Fetch current rates
curl https://payroll.dpnc.my/api/v1/rates

# 2. Calculate a payslip
curl -X POST https://payroll.dpnc.my/api/v1/calculate-payslip \
  -H "Content-Type: application/json" \
  -d '{"wage": 5000}'
```

### Response (wage RM5,000)

```json
{
  "success": true,
  "data": {
    "wage": 5000,
    "employee_contributions": {
      "epf": 550.0, "socso": 24.75, "eis": 9.9, "hrdf": 0, "pcb": 110.0,
      "total": 694.65
    },
    "employer_contributions": {
      "epf": 650.0, "socso": 84.55, "eis": 9.9, "hrdf": 50.0,
      "total": 794.45
    },
    "net_pay": 4305.35,
    "total_statutory_cost": 5794.45
  }
}
```

## 📖 API Reference

### POST `/api/v1/calculate-payslip`

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `wage` | number | ✅ | — | Gross monthly wage (RM) |
| `include_hrdf` | bool | — | `true` | Apply HRDF levy |
| `married` | bool | — | `false` | Marital status only; does not grant spouse relief |
| `spouse_eligible` | bool | — | `false` | Non-working spouse qualifies for relief |
| `children` | int | — | `0` | Children under 18 (RM2,000/yr each) |
| `citizenship` | enum | — | `malaysian` | `malaysian` or `non_malaysian` |
| `age_60_plus` | bool | — | `false` | Selects age-60-plus contribution rules |
| `hrdf_category` | enum | — | `standard_1pct` | `standard_1pct`, `reduced_0_5pct`, or `exempt` |
| `year` | int | — | `2026` | Rate year |

### Errors

| Code | Meaning |
|---|---|
| `400` | Bad request (missing/invalid `wage`) |
| `429` | Rate limit exceeded |

## 🛠 Local Development

```bash
# Elixir 1.18+ / OTP 25+ required
mix deps.get
mix phx.server          # http://localhost:4000
mix test
mix precommit           # compile --warnings-as-errors + format + tests
```

## ⚠️ Production Limits

EPF wage-range schedules below RM20,000.01, full LHDN MTD/PCB workflows, HRD Corp eligibility rules, and payroll persistence are not complete. Do not use outputs for real payroll filing.

## 📐 Architecture

```text
lib/payroll_api/
  statutory/
    rates.ex      ← Year-keyed rate tables (DATA, with sources)
    payslip.ex    ← Orchestrates the calculation
    pcb.ex        ← LHDN MTD income tax (brackets, reliefs, rebate)
  rate_limiter.ex ← In-memory sliding-window IP rate limiting

lib/payroll_api_web/
  controllers/    ← API + LiveView controllers
  live/           ← Payslip calculator UI
  plugs/          ← RateLimit
```

Rates are **data, not code**: update `Rates.rates_by_year/0` for a new budget year — no calculation logic changes.

## 📄 Data Sources & Credits

This API contains statutory data (rates, brackets, reliefs) sourced from
official publications and cross-verified against third-party references.
**All statutory tables must be verified against official circulars before
use in production payroll.**

| Data | Source | Status |
|---|---|---|
| **EPF/KWSP rates** | [KWSP](https://www.kwsp.gov.my) Third Schedule effective October 2025 | ⚠️ Wage-range schedule import pending; not production-ready |
| **SOCSO/PERKESO brackets** (Oct 2024 revision, RM6,000 ceiling, Cat 1 & 2) | [PERKESO rate of contribution](https://www.perkeso.gov.my/en/rate-of-contribution.html); cross-checked vs [Payroll-Calculator-2026](https://github.com/yeerock/Malaysia-Payroll-Calculator-2026---PCB-EPF-SOCSO-EIS-Net-Salary-Calculator) `socso.json` | ✅ Verified 2026-08-07 |
| **EIS/SIP brackets** (RM6,000 ceiling) | SIP Act 2017; cross-checked vs [Payroll-Calculator-2026](https://github.com/yeerock/Malaysia-Payroll-Calculator-2026---PCB-EPF-SOCSO-EIS-Net-Salary-Calculator) `eis.json` | ✅ Verified 2026-08-07 |
| **PCB income tax** | [LHDN tax rates](https://www.hasil.gov.my/en/individual/individual-life-cycle/income-declaration/tax-rate/) | ⚠️ Simplified Method 1 only; full MTD validation pending |
| **HRDF levy** (1% employer) | PSMB Act 2001 / HRD Corp | ⚠️ Standard rate, verify applicability |
| **Minimum wage** (RM1,700) | Minimum Wages Order 2025 (gazetted) | ✅ Verified |

### Third-party references used for cross-verification

- [Payroll-Calculator-2026](https://github.com/yeerock/Malaysia-Payroll-Calculator-2026---PCB-EPF-SOCSO-EIS-Net-Salary-Calculator) (GitHub, `socso.json` / `epf.json` / `eis.json` / `pcb.json`) — primary cross-check for SOCSO/EIS/EPF/PCB tables
- [L&Co Accountants — Personal Tax Rate 2026](https://landco.my/taxation-en/personal-tax-rate/) — PCB bracket cross-check
- [PERKESO — Rate of Contribution](https://www.perkeso.gov.my/en/rate-of-contribution.html) — official SOCSO source
- [LHDN — Tax Rate](https://www.hasil.gov.my/en/individual/individual-life-cycle/income-declaration/tax-rate/) — official PCB source
- [KWSP](https://www.kwsp.gov.my) — official EPF source

### Data freshness

Rates and PCB values are stored as year-keyed data in `lib/payroll_api/statutory/rates.ex`.
A new budget year = a data-only update; calculation code stays untouched.
Each snapshot carries `verified: true/false` and `verified_at`.

> **Disclaimer:** This API is an engineering tool, not financial or legal
> advice. Statutory rates change — always confirm against official
> publications before processing real payroll.

---

## 📄 License

MIT
