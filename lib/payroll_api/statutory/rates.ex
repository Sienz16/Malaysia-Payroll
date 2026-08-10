defmodule PayrollApi.Statutory.Rates do
  @moduledoc """
  Malaysian statutory rates and contribution tables — keyed by year.

  Rates are DATA, not code: every statutory figure lives in `rates_by_year/0`
  with its effective date range and source reference. Updating a year's rates
  is a data-only change (no calculation code touched).

  Verification status differs per scheme — see `verified_schemes` on a snapshot:

  * EPF and SOCSO are computed from official tables transcribed into
    `priv/statutory/` and covered by known-answer tests. See `Schedule`.
  * EIS, HRDF and PCB are still prototype approximations. PCB in particular is
    a simplified annualised bracket calculation, **not** the LHDN MTD
    specification, and will disagree with a real payslip.

  A snapshot's `verified` flag stays false while any scheme is unverified, so
  no caller can mistake the whole result for filing-safe output.

  - Minimum wage: RM1,700 (2025 gazette)
  """

  @default_year 2026

  alias PayrollApi.Statutory.Money
  alias PayrollApi.Statutory.Schedule

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

  # The EPF and SOCSO tables in `Schedule` are the editions in force now: KWSP
  # Third Schedule from 1 October 2025, and PERKESO Act 4 including SKBBK from
  # 1 June 2026. They are the correct basis for 2026 only.
  #
  # 2025 is deliberately left unverified. Jan–Sep 2025 predates the current
  # Third Schedule, and all of 2025 predates SKBBK, so calculating a 2025
  # payroll from these tables overstates the employee SOCSO share. Transcribing
  # the superseded editions is the fix; until then a 2025 result is an estimate.
  defp table_basis(2026), do: %{epf: "2025-10", socso: "2026-06", verified: true}
  defp table_basis(_year), do: %{epf: "2025-10", socso: "2026-06", verified: false}

  defp snapshot(year, from, to) do
    basis = table_basis(year)

    %{
      year: year,
      effective_from: from,
      effective_to: to,
      epf: %{
        # Percentage rules apply only above the Third Schedule's RM20,000
        # ceiling; at or below it the band tables in `Schedule` govern.
        employee_rate_above_table: 0.11,
        employer_rate_above_table: 0.12,
        table_ceiling: 20_000,
        table_edition: basis.epf
      },
      socso: %{
        wage_ceiling: 6000,
        table_edition: basis.socso,
        includes_skbbk: true
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
          "KWSP Third Schedule (EPF Act 1991) effective 1 October 2025, Parts A/C/E transcribed to band tables; percentage rules above RM20,000",
        socso: "PERKESO Act 4 contribution table including SKBBK, mandatory from 1 June 2026",
        eis: "SIP Act 2017, ceiling RM6,000 (NOT yet verified against source)",
        hrdf: "PSMB Act 2001 (NOT yet verified against source)",
        minimum_wage: "Minimum Wages Order 2025 (RM1,700, gazetted)",
        pcb: "Simplified annualised brackets — NOT the LHDN MTD specification"
      },
      # Scheme-level verification. `verified` stays false while any scheme in
      # the snapshot is unverified, so no caller can read it as filing-safe.
      verified: false,
      verified_schemes: verified_schemes(basis.verified),
      verified_at: "2026-08-10"
    }
  end

  # EPF and SOCSO are backed by transcribed official tables; EIS, HRDF and PCB
  # are not, so they are never reported as verified.
  defp verified_schemes(true), do: [:epf, :socso]
  defp verified_schemes(false), do: []

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

  def version(year) when is_integer(year), do: "#{year}.2"

  @doc "Source references for a given year."
  def sources(year \\ @default_year) do
    rates(year).sources
  end

  @doc """
  Compute EPF contribution (employee + employer) from the KWSP Third Schedule.

  At or below RM20,000 the schedule's band tables govern: each band carries a
  fixed ringgit amount, which is not the same as applying the headline
  percentage to the wage. Above RM20,000 the schedule switches to percentages.

  Options select the applicable Part:

    * `:citizenship` — `:malaysian` (default) or `:non_malaysian`
    * `:permanent_resident` — non-citizens with PR status, or who elected to
      contribute before 1 August 1998, follow the citizen tables
    * `:age_60_plus`

  | Profile | Part | Above RM20,000 |
  |---|---|---|
  | Citizen / PR / pre-1998 elector, under 60 | A | 11% employee, 12% employer |
  | Non-citizen PR or elector, 60+ | C | 5.5% employee, 6% employer |
  | Citizen, 60+ | E | 0% employee, 4% employer |
  | Other non-citizens (any age) | F | 2% employee, 2% employer (no table) |
  """
  def epf(wage, _rates \\ nil, opts \\ []) do
    wage_sen = Money.to_sen(wage)
    {employee_sen, employer_sen} = epf_contribution(epf_part(opts), wage_sen)

    %{
      employee: Money.to_ringgit(employee_sen),
      employer: Money.to_ringgit(employer_sen)
    }
  end

  defp epf_part(opts) do
    citizen? = Keyword.get(opts, :citizenship, :malaysian) == :malaysian
    schedule_resident? = citizen? or Keyword.get(opts, :permanent_resident, false)

    cond do
      not schedule_resident? -> :f
      not Keyword.get(opts, :age_60_plus, false) -> :a
      citizen? -> :e
      true -> :c
    end
  end

  # Part F has no band table: a flat 2%/2% at every wage, total rounded up.
  defp epf_contribution(:f, wage_sen) do
    share = Money.percentage(wage_sen, 2, 100)
    round_epf_total(share, share)
  end

  defp epf_contribution(part, wage_sen) do
    case Schedule.epf(part, wage_sen) do
      {:ok, %{employee: employee_sen, employer: employer_sen}} ->
        # Band amounts are already whole ringgit as printed; no rounding.
        {employee_sen, employer_sen}

      :above_table ->
        {employee_rate, employer_rate} = epf_rate_above_table(part)

        round_epf_total(
          Money.percentage(wage_sen, employee_rate, 1000),
          Money.percentage(wage_sen, employer_rate, 1000)
        )
    end
  end

  # Per-mille so Part C's 5.5% stays exact.
  defp epf_rate_above_table(:a), do: {110, 120}
  defp epf_rate_above_table(:c), do: {55, 60}
  defp epf_rate_above_table(:e), do: {0, 40}

  # "The total contribution which includes cents shall be rounded to the next
  # ringgit." The schedule does not say which side absorbs the rounding; this
  # keeps the employee share exact and adds the remainder to the employer, the
  # behaviour this module has always had. Unverified — see PAY-004.
  defp round_epf_total(employee_sen, employer_sen) do
    total = Money.ceil_ringgit(employee_sen + employer_sen)
    {employee_sen, total - employee_sen}
  end

  @doc """
  SOCSO (PERKESO) contribution from the official Act 4 table.

  Category 1 (under 60) covers employment injury, invalidity and SKBBK.
  Category 2 (`age_60_plus: true`) covers employment injury and SKBBK.

  SKBBK (Lindung 24 Jam) has been mandatory since 1 June 2026 and is included
  in the employee share for both categories.
  """
  def socso(wage, _rates \\ nil, opts \\ %{}) do
    category = if Map.get(opts, :age_60_plus, false), do: :category2, else: :category1

    %{employee: employee_sen, employer: employer_sen} =
      Schedule.socso(category, Money.to_sen(wage))

    %{
      employee: Money.to_ringgit(employee_sen),
      employer: Money.to_ringgit(employer_sen)
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
