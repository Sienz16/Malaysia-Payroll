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

## 📄 License

MIT
