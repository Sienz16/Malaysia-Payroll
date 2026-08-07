defmodule PayrollApi.Statutory.Rates do
  @moduledoc """
  Malaysian statutory rates and contribution tables — keyed by year.

  Rates are DATA, not code: every statutory figure lives in `rates_by_year/0`
  with its effective date range and source reference. Updating a year's rates
  is a data-only change (no calculation code touched).

  Source references (to be verified in Sprint 2 — see SPRINT_PLAN.md):
  - EPF/KWSP: KWSP circulars — 11% employee; 12% employer (wage < RM5,000),
    13% employer (wage >= RM5,000)
  - SOCSO (PERKESO) Act 1969: employee 0.5%, employer 1.75%, wage ceiling RM4,000
  - EIS (SIP) Act 2017: 0.2% employee / 0.2% employer, wage ceiling RM4,000
  - HRDF (PSMB Act): 1% employer
  - Minimum wage (2025 gazette): RM1,700/mo
  """

  @default_year 2026

  @doc """
  All known rate snapshots, keyed by year.

  Each snapshot: `%{year:, effective_from:, effective_to:, epf:, socso:, eis:,
  hrdf:, minimum_wage:, sources: %{...}}`.
  """
  def rates_by_year do
    %{
      2026 => %{
        year: 2026,
        effective_from: "2026-01-01",
        effective_to: "2026-12-31",
        epf: %{
          employee_rate: 0.11,
          employer_rate_under_5k: 0.12,
          employer_rate_over_5k: 0.13,
          wage_threshold: 5000
        },
        socso: %{
          employee_rate: 0.005,
          employer_rate: 0.0175,
          wage_ceiling: 4000
        },
        eis: %{
          employee_rate: 0.002,
          employer_rate: 0.002,
          wage_ceiling: 4000
        },
        hrdf: %{
          employer_rate: 0.01,
          applicable: true
        },
        minimum_wage: 1700,
        sources: %{
          epf: "KWSP circular (effective 2026-01-01)",
          socso: "PERKESO Act 1969 wage ceiling RM4,000",
          eis: "SIP Act 2017",
          hrdf: "PSMB Act 2001",
          minimum_wage: "Minimum Wages Order 2025 (gazetted, effective 2025-02-01)"
        }
      },
      2025 => %{
        year: 2025,
        effective_from: "2025-01-01",
        effective_to: "2025-12-31",
        epf: %{
          employee_rate: 0.11,
          employer_rate_under_5k: 0.12,
          employer_rate_over_5k: 0.13,
          wage_threshold: 5000
        },
        socso: %{
          employee_rate: 0.005,
          employer_rate: 0.0175,
          wage_ceiling: 4000
        },
        eis: %{
          employee_rate: 0.002,
          employer_rate: 0.002,
          wage_ceiling: 4000
        },
        hrdf: %{
          employer_rate: 0.01,
          applicable: true
        },
        minimum_wage: 1700,
        sources: %{
          epf: "KWSP circular (effective 2025-01-01)",
          socso: "PERKESO Act 1969 wage ceiling RM4,000",
          eis: "SIP Act 2017",
          hrdf: "PSMB Act 2001",
          minimum_wage: "Minimum Wages Order 2025 (gazetted, effective 2025-02-01)"
        }
      }
    }
  end

  @doc "Current statutory rates snapshot for a year (default current year)."
  def rates(year \\ @default_year) do
    rates_by_year()
    |> Map.get(year, Map.get(rates_by_year(), @default_year))
  end

  @doc "List of supported years."
  def supported_years, do: Map.keys(rates_by_year()) |> Enum.sort()

  @doc "Human-readable version string for cache headers."
  def version, do: "#{@default_year}.1"

  @doc "Source references for a given year."
  def sources(year \\ @default_year) do
    rates(year).sources
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
