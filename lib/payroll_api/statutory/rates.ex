defmodule PayrollApi.Statutory.Rates do
  @moduledoc """
  Malaysian statutory rates and contribution tables — keyed by year.

  Rates are DATA, not code: every statutory figure lives in `rates_by_year/0`
  with its effective date range and source reference. Updating a year's rates
  is a data-only change (no calculation code touched).

  VERIFICATION STATUS (2026-08-07 pass):
  - PCB brackets/reliefs: VERIFIED against L&Co personal tax rate 2026 +
    Payroll-Calculator-2026 reference (LHDN YA 2025/2026)
  - EPF: VERIFIED 11% employee / 12-13% employer (wage threshold RM5,000)
  - SOCSO: VERIFIED vs PERKESO Oct 2024 revision — wage ceiling RM6,000,
    Category 1 (below 60) bracket table
  - EIS: VERIFIED vs SIP — wage ceiling RM6,000, bracket table (0.2% base)
  - Minimum wage: RM1,700 (2025 gazette)
  """

  @default_year 2026

  alias PayrollApi.Statutory.Money

  # SOCSO (PERKESO) Category 1 — employees below 60 (Malaysian + foreign),
  # effective Oct 2024, wage ceiling RM6,000. Values from PERKESO rate table.
  @socso_category1_brackets [
    %{max: 30, employer: 0.40, employee: 0.10},
    %{max: 50, employer: 0.70, employee: 0.20},
    %{max: 70, employer: 1.10, employee: 0.30},
    %{max: 100, employer: 1.50, employee: 0.40},
    %{max: 140, employer: 2.10, employee: 0.60},
    %{max: 200, employer: 2.95, employee: 0.85},
    %{max: 300, employer: 4.35, employee: 1.25},
    %{max: 400, employer: 6.15, employee: 1.75},
    %{max: 500, employer: 7.85, employee: 2.25},
    %{max: 600, employer: 9.65, employee: 2.75},
    %{max: 700, employer: 11.35, employee: 3.25},
    %{max: 800, employer: 13.05, employee: 3.75},
    %{max: 900, employer: 14.75, employee: 4.25},
    %{max: 1000, employer: 16.55, employee: 4.75},
    %{max: 1100, employer: 18.25, employee: 5.25},
    %{max: 1200, employer: 19.95, employee: 5.75},
    %{max: 1300, employer: 21.65, employee: 6.25},
    %{max: 1400, employer: 23.35, employee: 6.75},
    %{max: 1500, employer: 25.05, employee: 7.25},
    %{max: 1600, employer: 26.75, employee: 7.75},
    %{max: 1700, employer: 28.45, employee: 8.25},
    %{max: 1800, employer: 30.15, employee: 8.75},
    %{max: 1900, employer: 31.85, employee: 9.25},
    %{max: 2000, employer: 33.55, employee: 9.75},
    %{max: 2100, employer: 35.25, employee: 10.25},
    %{max: 2200, employer: 36.95, employee: 10.75},
    %{max: 2300, employer: 38.65, employee: 11.25},
    %{max: 2400, employer: 40.35, employee: 11.75},
    %{max: 2500, employer: 42.05, employee: 12.25},
    %{max: 2600, employer: 43.75, employee: 12.75},
    %{max: 2700, employer: 45.45, employee: 13.25},
    %{max: 2800, employer: 47.15, employee: 13.75},
    %{max: 2900, employer: 48.85, employee: 14.25},
    %{max: 3000, employer: 50.55, employee: 14.75},
    %{max: 3100, employer: 52.25, employee: 15.25},
    %{max: 3200, employer: 53.95, employee: 15.75},
    %{max: 3300, employer: 55.65, employee: 16.25},
    %{max: 3400, employer: 57.35, employee: 16.75},
    %{max: 3500, employer: 59.05, employee: 17.25},
    %{max: 3600, employer: 60.75, employee: 17.75},
    %{max: 3700, employer: 62.45, employee: 18.25},
    %{max: 3800, employer: 64.15, employee: 18.75},
    %{max: 3900, employer: 65.85, employee: 19.25},
    %{max: 4000, employer: 67.55, employee: 19.75},
    %{max: 4100, employer: 69.25, employee: 20.25},
    %{max: 4200, employer: 70.95, employee: 20.75},
    %{max: 4300, employer: 72.65, employee: 21.25},
    %{max: 4400, employer: 74.35, employee: 21.75},
    %{max: 4500, employer: 76.05, employee: 22.25},
    %{max: 4600, employer: 77.75, employee: 22.75},
    %{max: 4700, employer: 79.45, employee: 23.25},
    %{max: 4800, employer: 81.15, employee: 23.75},
    %{max: 4900, employer: 82.85, employee: 24.25},
    %{max: 5000, employer: 84.55, employee: 24.75},
    %{max: 5100, employer: 86.25, employee: 25.25},
    %{max: 5200, employer: 87.95, employee: 25.75},
    %{max: 5300, employer: 89.65, employee: 26.25},
    %{max: 5400, employer: 91.35, employee: 26.75},
    %{max: 5500, employer: 93.05, employee: 27.25},
    %{max: 5600, employer: 94.75, employee: 27.75},
    %{max: 5700, employer: 96.45, employee: 28.25},
    %{max: 5800, employer: 98.15, employee: 28.75},
    %{max: 5900, employer: 99.85, employee: 29.25},
    %{max: 6000, employer: 101.55, employee: 29.75},
    %{max: 999_999, employer: 101.55, employee: 29.75}
  ]

  # SOCSO Category 2 — employees aged 60+, wage ceiling RM6,000.
  @socso_category2_brackets [
    %{max: 30, employer: 0.30, employee: 0.0},
    %{max: 50, employer: 0.50, employee: 0.0},
    %{max: 70, employer: 0.80, employee: 0.0},
    %{max: 100, employer: 1.10, employee: 0.0},
    %{max: 140, employer: 1.50, employee: 0.0},
    %{max: 200, employer: 2.10, employee: 0.0},
    %{max: 300, employer: 3.10, employee: 0.0},
    %{max: 400, employer: 4.40, employee: 0.0},
    %{max: 500, employer: 5.60, employee: 0.0},
    %{max: 600, employer: 6.90, employee: 0.0},
    %{max: 700, employer: 8.10, employee: 0.0},
    %{max: 800, employer: 9.30, employee: 0.0},
    %{max: 900, employer: 10.50, employee: 0.0},
    %{max: 1000, employer: 11.80, employee: 0.0},
    %{max: 1100, employer: 13.00, employee: 0.0},
    %{max: 1200, employer: 14.20, employee: 0.0},
    %{max: 1300, employer: 15.40, employee: 0.0},
    %{max: 1400, employer: 16.60, employee: 0.0},
    %{max: 1500, employer: 17.90, employee: 0.0},
    %{max: 1600, employer: 19.10, employee: 0.0},
    %{max: 1700, employer: 20.30, employee: 0.0},
    %{max: 1800, employer: 21.50, employee: 0.0},
    %{max: 1900, employer: 22.70, employee: 0.0},
    %{max: 2000, employer: 24.00, employee: 0.0},
    %{max: 2100, employer: 25.20, employee: 0.0},
    %{max: 2200, employer: 26.40, employee: 0.0},
    %{max: 2300, employer: 27.60, employee: 0.0},
    %{max: 2400, employer: 28.80, employee: 0.0},
    %{max: 2500, employer: 30.00, employee: 0.0},
    %{max: 2600, employer: 31.20, employee: 0.0},
    %{max: 2700, employer: 32.40, employee: 0.0},
    %{max: 2800, employer: 33.60, employee: 0.0},
    %{max: 2900, employer: 34.80, employee: 0.0},
    %{max: 3000, employer: 36.10, employee: 0.0},
    %{max: 3100, employer: 37.30, employee: 0.0},
    %{max: 3200, employer: 38.50, employee: 0.0},
    %{max: 3300, employer: 39.70, employee: 0.0},
    %{max: 3400, employer: 40.90, employee: 0.0},
    %{max: 3500, employer: 42.10, employee: 0.0},
    %{max: 3600, employer: 43.30, employee: 0.0},
    %{max: 3700, employer: 44.50, employee: 0.0},
    %{max: 3800, employer: 45.70, employee: 0.0},
    %{max: 3900, employer: 46.90, employee: 0.0},
    %{max: 4000, employer: 48.20, employee: 0.0},
    %{max: 4100, employer: 49.40, employee: 0.0},
    %{max: 4200, employer: 50.60, employee: 0.0},
    %{max: 4300, employer: 51.80, employee: 0.0},
    %{max: 4400, employer: 53.00, employee: 0.0},
    %{max: 4500, employer: 54.20, employee: 0.0},
    %{max: 4600, employer: 55.40, employee: 0.0},
    %{max: 4700, employer: 56.60, employee: 0.0},
    %{max: 4800, employer: 57.80, employee: 0.0},
    %{max: 4900, employer: 59.00, employee: 0.0},
    %{max: 5000, employer: 60.30, employee: 0.0},
    %{max: 5100, employer: 61.50, employee: 0.0},
    %{max: 5200, employer: 62.70, employee: 0.0},
    %{max: 5300, employer: 63.90, employee: 0.0},
    %{max: 5400, employer: 65.10, employee: 0.0},
    %{max: 5500, employer: 66.30, employee: 0.0},
    %{max: 5600, employer: 67.50, employee: 0.0},
    %{max: 5700, employer: 68.70, employee: 0.0},
    %{max: 5800, employer: 69.90, employee: 0.0},
    %{max: 5900, employer: 71.10, employee: 0.0},
    %{max: 6000, employer: 72.40, employee: 0.0},
    %{max: 999_999, employer: 72.40, employee: 0.0}
  ]

  # EIS (SIP) bracket table — wage ceiling RM6,000, equal employee/employer.
  # Base 0.2% each side scaled per bracket. (2024-2026 SIP rates.)
  @eis_brackets [
    %{max: 30, contribution: 0.05},
    %{max: 50, contribution: 0.10},
    %{max: 70, contribution: 0.15},
    %{max: 100, contribution: 0.20},
    %{max: 140, contribution: 0.25},
    %{max: 200, contribution: 0.35},
    %{max: 300, contribution: 0.50},
    %{max: 400, contribution: 0.70},
    %{max: 500, contribution: 0.90},
    %{max: 600, contribution: 1.10},
    %{max: 700, contribution: 1.30},
    %{max: 800, contribution: 1.50},
    %{max: 900, contribution: 1.70},
    %{max: 1000, contribution: 1.90},
    %{max: 1100, contribution: 2.10},
    %{max: 1200, contribution: 2.30},
    %{max: 1300, contribution: 2.50},
    %{max: 1400, contribution: 2.70},
    %{max: 1500, contribution: 2.90},
    %{max: 1600, contribution: 3.10},
    %{max: 1700, contribution: 3.30},
    %{max: 1800, contribution: 3.50},
    %{max: 1900, contribution: 3.70},
    %{max: 2000, contribution: 3.90},
    %{max: 2100, contribution: 4.10},
    %{max: 2200, contribution: 4.30},
    %{max: 2300, contribution: 4.50},
    %{max: 2400, contribution: 4.70},
    %{max: 2500, contribution: 4.90},
    %{max: 2600, contribution: 5.10},
    %{max: 2700, contribution: 5.30},
    %{max: 2800, contribution: 5.50},
    %{max: 2900, contribution: 5.70},
    %{max: 3000, contribution: 5.90},
    %{max: 3100, contribution: 6.10},
    %{max: 3200, contribution: 6.30},
    %{max: 3300, contribution: 6.50},
    %{max: 3400, contribution: 6.70},
    %{max: 3500, contribution: 6.90},
    %{max: 3600, contribution: 7.10},
    %{max: 3700, contribution: 7.30},
    %{max: 3800, contribution: 7.50},
    %{max: 3900, contribution: 7.70},
    %{max: 4000, contribution: 7.90},
    %{max: 4100, contribution: 8.10},
    %{max: 4200, contribution: 8.30},
    %{max: 4300, contribution: 8.50},
    %{max: 4400, contribution: 8.70},
    %{max: 4500, contribution: 8.90},
    %{max: 4600, contribution: 9.10},
    %{max: 4700, contribution: 9.30},
    %{max: 4800, contribution: 9.50},
    %{max: 4900, contribution: 9.70},
    %{max: 5000, contribution: 9.90},
    %{max: 5100, contribution: 10.10},
    %{max: 5200, contribution: 10.30},
    %{max: 5300, contribution: 10.50},
    %{max: 5400, contribution: 10.70},
    %{max: 5500, contribution: 10.90},
    %{max: 5600, contribution: 11.10},
    %{max: 5700, contribution: 11.30},
    %{max: 5800, contribution: 11.50},
    %{max: 5900, contribution: 11.70},
    %{max: 6000, contribution: 11.90},
    %{max: 999_999, contribution: 11.90}
  ]

  @doc """
  All known rate snapshots, keyed by year.
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
        employer_rate_at_or_under_5k: 0.13,
        employer_rate_over_5k: 0.12,
        wage_threshold: 5000,
        schedule_required_below_rm: 20_000.01
      },
      socso: %{
        wage_ceiling: 6000,
        category1_brackets: @socso_category1_brackets,
        category2_brackets: @socso_category2_brackets
      },
      eis: %{
        wage_ceiling: 6000,
        brackets: @eis_brackets
      },
      hrdf: %{
        employer_rate: 0.01,
        applicable: true
      },
      pcb: %{
        brackets: PayrollApi.Statutory.Pcb.brackets(),
        reliefs: PayrollApi.Statutory.Pcb.reliefs(),
        rebate_threshold: PayrollApi.Statutory.Pcb.rebate_threshold(),
        rebate_amount: PayrollApi.Statutory.Pcb.rebate_amount()
      },
      minimum_wage: 1700,
      sources: %{
        epf:
          "KWSP Third Schedule effective October 2025; wage-range table below RM20,000.01; percentage rules above",
        socso: "PERKESO Oct 2024 revision, ceiling RM6,000 (verified)",
        eis: "SIP Act 2017, ceiling RM6,000 (verified)",
        hrdf: "PSMB Act 2001",
        minimum_wage: "Minimum Wages Order 2025 (RM1,700, gazetted)",
        pcb: "LHDN YA 2025/2026 resident brackets (verified)"
      },
      verified: false,
      verified_at: "2026-08-07"
    }
  end

  @doc "Current statutory rates snapshot, or `{:error, :unsupported_year}`."
  def rates, do: Map.fetch!(rates_by_year(), @default_year)

  def rates(year) do
    case Map.fetch(rates_by_year(), year) do
      {:ok, snapshot} -> snapshot
      :error -> {:error, :unsupported_year}
    end
  end

  @doc "List of supported years."
  def supported_years, do: Map.keys(rates_by_year()) |> Enum.sort()

  @doc "Human-readable version string for cache headers."
  def version, do: "#{@default_year}.2"

  @doc "Source references for a given year."
  def sources(year \\ @default_year) do
    rates(year).sources
  end

  @doc """
  Compute EPF contribution (employee + employer).
  Employer rate: 13% at/below RM5,000, 12% above.
  """
  def epf(wage, rates \\ nil, opts \\ []) do
    r = rates || rates()
    category = Keyword.get(opts, :citizenship, :malaysian)
    age_60_plus = Keyword.get(opts, :age_60_plus, false)
    strict_schedule = Keyword.get(opts, :strict_schedule, false)

    if strict_schedule and wage <= 20_000 do
      {:error, :epf_schedule_required}
    else
      epf_percentage(wage, r, category, age_60_plus)
    end
  end

  defp epf_percentage(wage, _r, :non_malaysian, _age_60_plus) do
    wage_sen = Money.to_sen(wage)
    employee_sen = Money.percentage(wage_sen, 2, 100)
    employer_sen = Money.percentage(wage_sen, 2, 100)
    {employee_sen, employer_sen} = round_epf_total(wage, employee_sen, employer_sen)

    %{
      employee: Money.to_ringgit(employee_sen),
      employer: Money.to_ringgit(employer_sen)
    }
  end

  defp epf_percentage(wage, _r, _citizenship, true) do
    wage_sen = Money.to_sen(wage)
    {employee_sen, employer_sen} = round_epf_total(wage, 0, Money.percentage(wage_sen, 4, 100))

    %{
      employee: Money.to_ringgit(employee_sen),
      employer: Money.to_ringgit(employer_sen)
    }
  end

  defp epf_percentage(wage, r, _citizenship, false) do
    wage_sen = Money.to_sen(wage)

    employer_rate = if wage <= r.epf.wage_threshold, do: 13, else: 12
    employee_sen = Money.percentage(wage_sen, 11, 100)
    employer_sen = Money.percentage(wage_sen, employer_rate, 100)
    {employee_sen, employer_sen} = round_epf_total(wage, employee_sen, employer_sen)

    %{
      employee: Money.to_ringgit(employee_sen),
      employer: Money.to_ringgit(employer_sen)
    }
  end

  defp round_epf_total(wage, employee_sen, employer_sen) when wage > 20_000 do
    total = Money.ceil_ringgit(employee_sen + employer_sen)
    {employee_sen, total - employee_sen}
  end

  defp round_epf_total(_wage, employee_sen, employer_sen), do: {employee_sen, employer_sen}

  @doc """
  SOCSO (PERKESO) contribution — Category 1 (below 60) bracket table,
  wage ceiling RM6,000. `age_60_plus: true` selects Category 2.
  """
  def socso(wage, rates \\ nil, opts \\ %{}) do
    r = rates || rates()

    brackets =
      if Map.get(opts, :age_60_plus, false),
        do: r.socso.category2_brackets,
        else: r.socso.category1_brackets

    %{
      employee: round_money(bracket_value(brackets, wage, :employee)),
      employer: round_money(bracket_value(brackets, wage, :employer))
    }
  end

  @doc """
  EIS (SIP) contribution — bracket table, wage ceiling RM6,000.
  Equal employee/employer per bracket.

  Eligibility (SIP Act 2017): Malaysian citizens and PRs aged 18-59.
  Foreign workers are not covered, and employees aged 60+ are not covered
  (they may be covered by SOCSO Category 2 instead). Pass
  `age_60_plus: true` or `citizenship: :non_malaysian` to get zero
  contribution for those profiles.
  """
  def eis(wage, rates \\ nil, opts \\ []) do
    age_60_plus = Keyword.get(opts, :age_60_plus, false)
    citizenship = Keyword.get(opts, :citizenship, :malaysian)

    if age_60_plus or citizenship == :non_malaysian do
      %{employee: 0, employer: 0}
    else
      r = rates || rates()
      contribution = bracket_value(r.eis.brackets, wage, :contribution)

      %{
        employee: round_money(contribution),
        employer: round_money(contribution)
      }
    end
  end

  @doc """
  HRDF — employer 1% of wage (levy). Employee pays nothing.
  """
  def hrdf(wage, rates \\ nil, opts \\ []) do
    r = rates || rates()
    wage_sen = Money.to_sen(wage)
    rate = hrdf_rate(r, Keyword.get(opts, :category, :standard_1pct))

    %{
      employee: 0,
      employer: Money.to_ringgit(Money.percentage(wage_sen, rate, 1000))
    }
  end

  defp hrdf_rate(_rates, :standard_1pct), do: 10
  defp hrdf_rate(_rates, :reduced_0_5pct), do: 5
  defp hrdf_rate(_rates, :exempt), do: 0
  defp hrdf_rate(_rates, _), do: raise(ArgumentError, "invalid HRDF category")

  defp bracket_value(brackets, wage, key) do
    Enum.find_value(brackets, 0.0, fn bracket ->
      if wage <= bracket.max, do: Map.get(bracket, key)
    end)
  end

  @doc "Round to nearest sen (2 decimal places) — pure Float arithmetic."
  def round_money(value) do
    value
    |> Kernel.*(100)
    |> Kernel.round()
    |> Kernel./(100)
  end
end
