# 🇲🇾 Malaysia Payroll Statutory API

**EPF · SOCSO · EIS · HRDF · PCB** — Malaysian statutory payroll calculations as a clean REST API. Built with Phoenix 1.8.9 / Elixir 1.18.

> Public statutory data, computed correctly, with current-year tables kept as data so budget changes are a one-file update.

---

## ✨ Features

| Endpoint | Description |
|---|---|
| `GET /api/v1/health` | Liveness probe (public) |
| `GET /api/v1/rates` | Current statutory rate tables (EPF/SOCSO/EIS/HRDF, min wage) |
| `POST /api/v1/calculate-payslip` | Full payslip: EPF + SOCSO + EIS + HRDF + PCB → net pay |
| `GET /api/v1/keys` | Manage API keys (auth required) |

## 🚀 Quickstart

```bash
# 1. Get an API key (master key is in your env file)
export PAYROLL_API_KEY="your-key"

# 2. Fetch current rates
curl https://payroll.dpnc.my/api/v1/rates \
  -H "Authorization: Bearer $PAYROLL_API_KEY"

# 3. Calculate a payslip
curl -X POST https://payroll.dpnc.my/api/v1/calculate-payslip \
  -H "Authorization: Bearer $PAYROLL_API_KEY" \
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
      "epf": 550.0, "socso": 20.0, "eis": 8.0, "hrdf": 0, "pcb": 110.0,
      "total": 688.0
    },
    "employer_contributions": {
      "epf": 650.0, "socso": 70.0, "eis": 8.0, "hrdf": 50.0,
      "total": 778.0
    },
    "net_pay": 4312.0,
    "total_statutory_cost": 5778.0
  }
}
```

## 📖 API Reference

### POST `/api/v1/calculate-payslip`

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `wage` | number | ✅ | — | Gross monthly wage (RM) |
| `include_hrdf` | bool | — | `true` | Apply HRDF levy |
| `married` | bool | — | `false` | Spouse tax relief (RM4,000/yr) |
| `children` | int | — | `0` | Children under 18 (RM2,000/yr each) |
| `year` | int | — | `2026` | Rate year |

### Errors

| Code | Meaning |
|---|---|
| `400` | Bad request (missing/invalid `wage`) |
| `401` | Missing/invalid API key |
| `429` | Rate limit exceeded |

## 🛠 Local Development

```bash
# Elixir 1.18+ / OTP 25+ required
mix deps.get
mix phx.server          # http://localhost:4000
mix test                # 30+ tests
```

## 📐 Architecture

```text
lib/payroll_api/
  statutory/
    rates.ex      ← Year-keyed rate tables (DATA, with sources)
    payslip.ex    ← Orchestrates the calculation
    pcb.ex        ← LHDN MTD income tax (brackets, reliefs, rebate)
  keys.ex         ← API key registry (env master + runtime keys)
  rate_limiter.ex ← In-memory sliding-window rate limiting

lib/payroll_api_web/
  controllers/    ← API + LiveView controllers
  live/           ← Payslip calculator UI
  plugs/          ← ApiKeyAuth, RateLimit
```

Rates are **data, not code**: update `Rates.rates_by_year/0` for a new budget year — no calculation logic changes.

## 📄 Data Sources & Credits

This API contains statutory data (rates, brackets, reliefs) sourced from
official publications and cross-verified against third-party references.
**All statutory tables must be verified against official circulars before
use in production payroll.**

| Data | Source | Status |
|---|---|---|
| **EPF/KWSP rates** (11% emp / 12–13% employer) | [KWSP](https://www.kwsp.gov.my) circulars; cross-checked vs [Payroll-Calculator-2026](https://github.com/yeerock/Malaysia-Payroll-Calculator-2026---PCB-EPF-SOCSO-EIS-Net-Salary-Calculator) `epf.json` | ✅ Verified 2026-08-07 |
| **SOCSO/PERKESO brackets** (Oct 2024 revision, RM6,000 ceiling, Cat 1 & 2) | [PERKESO rate of contribution](https://www.perkeso.gov.my/en/rate-of-contribution.html); cross-checked vs [Payroll-Calculator-2026](https://github.com/yeerock/Malaysia-Payroll-Calculator-2026---PCB-EPF-SOCSO-EIS-Net-Salary-Calculator) `socso.json` | ✅ Verified 2026-08-07 |
| **EIS/SIP brackets** (RM6,000 ceiling) | SIP Act 2017; cross-checked vs [Payroll-Calculator-2026](https://github.com/yeerock/Malaysia-Payroll-Calculator-2026---PCB-EPF-SOCSO-EIS-Net-Salary-Calculator) `eis.json` | ✅ Verified 2026-08-07 |
| **PCB income tax** (YA 2025/2026 brackets, reliefs, rebates) | [LHDN tax rates](https://www.hasil.gov.my/en/individual/individual-life-cycle/income-declaration/tax-rate/); cross-checked vs [L&Co Personal Tax Rate 2026](https://landco.my/taxation-en/personal-tax-rate/) and [Payroll-Calculator-2026](https://github.com/yeerock/Malaysia-Payroll-Calculator-2026---PCB-EPF-SOCSO-EIS-Net-Salary-Calculator) `pcb.json` | ✅ Verified 2026-08-07 |
| **HRDF levy** (1% employer) | PSMB Act 2001 / HRD Corp | ⚠️ Standard rate, verify applicability |
| **Minimum wage** (RM1,700) | Minimum Wages Order 2025 (gazetted) | ✅ Verified |

### Third-party references used for cross-verification

- [Payroll-Calculator-2026](https://github.com/yeerock/Malaysia-Payroll-Calculator-2026---PCB-EPF-SOCSO-EIS-Net-Salary-Calculator) (GitHub, `socso.json` / `epf.json` / `eis.json` / `pcb.json`) — primary cross-check for SOCSO/EIS/EPF/PCB tables
- [L&Co Accountants — Personal Tax Rate 2026](https://landco.my/taxation-en/personal-tax-rate/) — PCB bracket cross-check
- [PERKESO — Rate of Contribution](https://www.perkeso.gov.my/en/rate-of-contribution.html) — official SOCSO source
- [LHDN — Tax Rate](https://www.hasil.gov.my/en/individual/individual-life-cycle/income-declaration/tax-rate/) — official PCB source
- [KWSP](https://www.kwsp.gov.my) — official EPF source

### Data freshness

Rates are stored as year-keyed data in `lib/payroll_api/statutory/rates.ex`.
A new budget year = a data-only update; calculation code stays untouched.
Each snapshot carries `verified: true/false` and `verified_at`.

> **Disclaimer:** This API is an engineering tool, not financial or legal
> advice. Statutory rates change — always confirm against official
> publications before processing real payroll.

---

## 📄 License

MIT
