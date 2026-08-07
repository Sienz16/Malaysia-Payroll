defmodule PayrollApi.Statutory.Rates do
  @moduledoc """
  Malaysian statutory rates and contribution tables.

  Sources:
  - EPF/KWSP rates: KWSP circulars (2025) — 11% employee / 12% employer (below RM5,000 wage), 13% employer (above)
  - SOCSO (PERKESO) Act 1969 — employee share 0.5%, employer share 1.75% for wages >= RM4,000/mo;
    below RM4,000, employer pays per bracket table (approximated per Wage Ceiling RM4,000)
  - EIS (SIP) Act 2017 — 0.2% employee / 0.2% employer
  - HRDF (Pembangunan Sumber Manusia Berhad) — 1% employer (for companies registered under PSMB Act)

  NOTE: These tables are approximations for API development. The authoritative
  rates come from KWSP/PERKESO circulars which change yearly — the API design
  keeps rates as data (see `rates/0`) so they can be updated without code changes.
  """

  @wage_ceiling_socso 4000
  @wage_ceiling_eis 4000

  @doc "Current statutory rates snapshot (year)."
  def rates(year \\ 2026) do
    %{
      year: year,
      epf: %{
        employee_rate: 0.11,
        employer_rate_under_5k: 0.12,
        employer_rate_over_5k: 0.13,
        wage_threshold: 5000
      },
      socso: %{
        employee_rate: 0.005,
        employer_rate: 0.0175,
        wage_ceiling: @wage_ceiling_socso
      },
      eis: %{
        employee_rate: 0.002,
        employer_rate: 0.002,
        wage_ceiling: @wage_ceiling_eis
      },
      hrdf: %{
        employer_rate: 0.01,
        applicable: true
      },
      minimum_wage: 1700
    }
  end

  @doc "Human-readable version string for cache headers."
  def version do
    "2026.1"
  end

  @doc """
  Compute EPF contribution (employee + employer).
  Employer rate depends on wage: 12% below RM5,000, 13% at/above.
  """
  def epf(wage, rates \\ nil) do
    r = rates || rates()
    emp_rate = if wage >= r.epf.wage_threshold, do: r.epf.employer_rate_over_5k, else: r.epf.employer_rate_under_5k
    %{
      employee: round_money(wage * r.epf.employee_rate),
      employer: round_money(wage * emp_rate)
    }
  end

  @doc """
  SOCSO (PERKESO) contribution.
  Employee 0.5% capped at wage ceiling; employer 1.75% capped at ceiling.
  """
  def socso(wage, rates \\ nil) do
    r = rates || rates()
    capped = min(wage, r.socso.wage_ceiling)
    %{
      employee: round_money(capped * r.socso.employee_rate),
      employer: round_money(capped * r.socso.employer_rate)
    }
  end

  @doc """
  EIS (SIP) contribution — 0.2% each side, capped at wage ceiling.
  """
  def eis(wage, rates \\ nil) do
    r = rates || rates()
    capped = min(wage, r.eis.wage_ceiling)
    %{
      employee: round_money(capped * r.eis.employee_rate),
      employer: round_money(capped * r.eis.employer_rate)
    }
  end

  @doc """
  HRDF — employer 1% of wage (levy). Employee pays nothing.
  """
  def hrdf(wage, rates \\ nil) do
    r = rates || rates()
    %{
      employee: 0,
      employer: round_money(wage * r.hrdf.employer_rate)
    }
  end

  @doc "Round to nearest sen (2 decimal places) — pure Float arithmetic."
  def round_money(value) do
    value
    |> Kernel.*(100)
    |> Kernel.round()
    |> Kernel./(100)
  end
end
