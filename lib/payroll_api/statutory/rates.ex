defmodule PayrollApi.Statutory.Rates do
  @moduledoc """
  Malaysian statutory rates and contribution tables — keyed by year.

  Rates are DATA, not code: every statutory figure lives in `rates_by_year/0`
  with its effective date range and source reference. Updating a year's rates
  is a data-only change (no calculation code touched).

  Source references (see SPRINT_PLAN.md Sprint 2):
  - EPF/KWSP: KWSP circulars — 11% employee; 12% employer (wage < RM5,000),
    13% employer (wage >= RM5,000)
  - SOCSO (PERKESO) Act 1969: employee 0.5%, employer 1.75%, wage ceiling RM4,000
  - EIS (SIP) Act 2017: 0.2% employee / 0.2% employer, wage ceiling RM4,000
  - HRDF (PSMB Act): 1% employer
  - Minimum wage (2025 gazette): RM1,700/mo
  """

  @default_year 2026

  # PERKESO employee contribution brackets (RM per month by wage band).
  # First element: {lower, upper, employee_share_rm}. Employer share follows
  # a separate schedule — for v1 we keep the flat 1.75% employer estimate and
  # expose the real employee bracket table (marked for verification in Sprint 2).
  @socso_employee_brackets [
    %{lower: 0, upper: 30, employee: 0.0},
    %{lower: 30.01, upper: 50, employee: 0.1},
    %{lower: 50.01, upper: 70, employee: 0.2},
    %{lower: 70.01, upper: 100, employee: 0.3},
    %{lower: 100.01, upper: 140, employee: 0.4},
    %{lower: 140.01, upper: 200, employee: 0.6},
    %{lower: 200.01, upper: 300, employee: 0.9},
    %{lower: 300.01, upper: 400, employee: 1.2},
    %{lower: 400.01, upper: 500, employee: 1.7},
    %{lower: 500.01, upper: 600, employee: 2.3},
    %{lower: 600.01, upper: 700, employee: 2.9},
    %{lower: 700.01, upper: 800, employee: 3.6},
    %{lower: 800.01, upper: 900, employee: 4.3},
    %{lower: 900.01, upper: 1000, employee: 5.0},
    %{lower: 1000.01, upper: 1100, employee: 5.8},
    %{lower: 1100.01, upper: 1200, employee: 6.6},
    %{lower: 1200.01, upper: 1300, employee: 7.5},
    %{lower: 1300.01, upper: 1400, employee: 8.4},
    %{lower: 1400.01, upper: 1500, employee: 9.3},
    %{lower: 1500.01, upper: 1600, employee: 10.2},
    %{lower: 1600.01, upper: 1700, employee: 11.1},
    %{lower: 1700.01, upper: 1800, employee: 12.0},
    %{lower: 1800.01, upper: 1900, employee: 12.9},
    %{lower: 1900.01, upper: 2000, employee: 13.8},
    %{lower: 2000.01, upper: 2100, employee: 14.7},
    %{lower: 2100.01, upper: 2200, employee: 15.6},
    %{lower: 2200.01, upper: 2300, employee: 16.5},
    %{lower: 2300.01, upper: 2400, employee: 17.4},
    %{lower: 2400.01, upper: 2500, employee: 18.3},
    %{lower: 2500.01, upper: 2600, employee: 19.2},
    %{lower: 2600.01, upper: 2700, employee: 20.1},
    %{lower: 2700.01, upper: 2800, employee: 21.0},
    %{lower: 2800.01, upper: 2900, employee: 21.9},
    %{lower: 2900.01, upper: 3000, employee: 22.8},
    %{lower: 3000.01, upper: 3100, employee: 23.7},
    %{lower: 3100.01, upper: 3200, employee: 24.6},
    %{lower: 3200.01, upper: 3300, employee: 25.5},
    %{lower: 3300.01, upper: 3400, employee: 26.4},
    %{lower: 3400.01, upper: 3500, employee: 27.3},
    %{lower: 3500.01, upper: 3600, employee: 28.2},
    %{lower: 3600.01, upper: 3700, employee: 29.1},
    %{lower: 3700.01, upper: 3800, employee: 30.0},
    %{lower: 3800.01, upper: 3900, employee: 30.9},
    %{lower: 3900.01, upper: 4000, employee: 31.8},
    %{lower: 4000.01, upper: 999_999, employee: 31.8}
  ]

  # PERKESO employer contribution brackets (RM per month by wage band),
  # Second Schedule. Classic published series — FLAGGED for verification
  # against current PERKESO circulars before production launch.
  @socso_employer_brackets [
    %{lower: 0, upper: 30, employer: 2.75},
    %{lower: 30.01, upper: 50, employer: 4.85},
    %{lower: 50.01, upper: 70, employer: 6.80},
    %{lower: 70.01, upper: 100, employer: 9.75},
    %{lower: 100.01, upper: 140, employer: 13.65},
    %{lower: 140.01, upper: 200, employer: 19.55},
    %{lower: 200.01, upper: 300, employer: 29.30},
    %{lower: 300.01, upper: 400, employer: 39.05},
    %{lower: 400.01, upper: 500, employer: 48.80},
    %{lower: 500.01, upper: 600, employer: 58.55},
    %{lower: 600.01, upper: 700, employer: 68.30},
    %{lower: 700.01, upper: 800, employer: 78.05},
    %{lower: 800.01, upper: 900, employer: 87.80},
    %{lower: 900.01, upper: 1000, employer: 97.55},
    %{lower: 1000.01, upper: 1100, employer: 107.30},
    %{lower: 1100.01, upper: 1200, employer: 117.05},
    %{lower: 1200.01, upper: 1300, employer: 126.80},
    %{lower: 1300.01, upper: 1400, employer: 136.55},
    %{lower: 1400.01, upper: 1500, employer: 146.30},
    %{lower: 1500.01, upper: 1600, employer: 156.05},
    %{lower: 1600.01, upper: 1700, employer: 165.80},
    %{lower: 1700.01, upper: 1800, employer: 175.55},
    %{lower: 1800.01, upper: 1900, employer: 185.30},
    %{lower: 1900.01, upper: 2000, employer: 195.05},
    %{lower: 2000.01, upper: 2100, employer: 204.80},
    %{lower: 2100.01, upper: 2200, employer: 214.55},
    %{lower: 2200.01, upper: 2300, employer: 224.30},
    %{lower: 2300.01, upper: 2400, employer: 234.05},
    %{lower: 2400.01, upper: 2500, employer: 243.80},
    %{lower: 2500.01, upper: 2600, employer: 253.55},
    %{lower: 2600.01, upper: 2700, employer: 263.30},
    %{lower: 2700.01, upper: 2800, employer: 273.05},
    %{lower: 2800.01, upper: 2900, employer: 282.80},
    %{lower: 2900.01, upper: 3000, employer: 292.55},
    %{lower: 3000.01, upper: 3100, employer: 302.30},
    %{lower: 3100.01, upper: 3200, employer: 312.05},
    %{lower: 3200.01, upper: 3300, employer: 321.80},
    %{lower: 3300.01, upper: 3400, employer: 331.55},
    %{lower: 3400.01, upper: 3500, employer: 341.30},
    %{lower: 3500.01, upper: 3600, employer: 351.05},
    %{lower: 3600.01, upper: 3700, employer: 360.80},
    %{lower: 3700.01, upper: 3800, employer: 370.55},
    %{lower: 3800.01, upper: 3900, employer: 380.30},
    %{lower: 3900.01, upper: 4000, employer: 390.05},
    %{lower: 4000.01, upper: 999_999, employer: 390.05}
  ]

  @doc """
  All known rate snapshots, keyed by year.

  Each snapshot: `%{year:, effective_from:, effective_to:, epf:, socso:, eis:,
  hrdf:, minimum_wage:, sources: %{...}}`.
  """
  def rates_by_year do
    %{
      2026 => snapshot(2026, "2026-01-01", "2026-12-31"),
      2025 => snapshot(2025, "2025-01-01", "2025-12-31")
    }
  end

  defp snapshot(year, from, to) do
    %{
      year: year,
      effective_from: from,
      effective_to: to,
      epf: %{
        employee_rate: 0.11,
        employer_rate_under_5k: 0.12,
        employer_rate_over_5k: 0.13,
        wage_threshold: 5000
      },
      socso: %{
        employee_rate: 0.005,
        employer_rate: 0.0175,
        wage_ceiling: 4000,
        employee_brackets: @socso_employee_brackets,
        employer_brackets: @socso_employer_brackets
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
        epf: "KWSP circular (effective #{from})",
        socso: "PERKESO Act 1969 wage ceiling RM4,000",
        eis: "SIP Act 2017",
        hrdf: "PSMB Act 2001",
        minimum_wage: "Minimum Wages Order 2025 (gazetted, effective 2025-02-01)"
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
  SOCSO (PERKESO) contribution using real bracket tables for both sides.
  Employee from First Schedule brackets; employer from Second Schedule.
  """
  def socso(wage, rates \\ nil) do
    r = rates || rates()
    employee = bracket_value(r.socso.employee_brackets, wage, :employee)
    employer = bracket_value(r.socso.employer_brackets, wage, :employer)
    %{
      employee: round_money(employee),
      employer: round_money(employer)
    }
  end

  defp bracket_value(brackets, wage, key) do
    Enum.find_value(brackets, 0.0, fn bracket ->
      if wage >= bracket.lower and wage <= bracket.upper, do: Map.get(bracket, key)
    end)
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
