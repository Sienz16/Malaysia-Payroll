defmodule PayrollApi.Statutory.Rates do
  @moduledoc """
  Malaysian statutory rates and contribution tables — keyed by year.

  Rates are DATA, not code: every statutory figure lives in `rates_by_year/0`
  with its effective date range and source reference. Updating a year's rates
  is a data-only change (no calculation code touched).

  Verification status differs per scheme — see `verified_schemes` on a snapshot:

  * EPF, SOCSO and EIS are computed from official tables transcribed into
    `priv/statutory/` and covered by known-answer tests. See `Schedule`.
  * HRDF and PCB are still prototype approximations. PCB in particular is
    a simplified annualised bracket calculation, **not** the LHDN MTD
    specification, and will disagree with a real payslip.

  A snapshot's `verified` flag stays false while any scheme is unverified, so
  no caller can mistake the whole result for filing-safe output.

  - Minimum wage: RM1,700 (2025 gazette)
  """

  @default_year 2026

  alias PayrollApi.Statutory.Money
  alias PayrollApi.Statutory.Schedule

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
        table_edition: "2024-11"
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
        eis: "PERKESO Act 800 Second Schedule contribution table, ceiling RM6,000",
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

  # EPF, SOCSO and EIS are backed by transcribed official tables; HRDF and PCB
  # are not, so they are never reported as verified.
  defp verified_schemes(true), do: [:epf, :socso, :eis]
  defp verified_schemes(false), do: [:eis]

  # The loaded tables (EPF edition 1 Oct 2025, SOCSO edition 1 Jun 2026 incl.
  # SKBBK) are only correct for periods on/after the later of the two —
  # earlier periods need superseded editions this repo does not have
  # transcribed. `rates(year)` alone still returns the 2026 "current law"
  # snapshot unchanged (callers not stating a period keep prior behaviour);
  # `rates(year, month)` is how a caller states a period, and gets a refusal
  # instead of a silently wrong SOCSO figure. See PAY-009.
  @tables_effective_from {2026, 6}

  @doc "Current statutory rates snapshot, or `{:error, :unsupported_year}`."
  def rates, do: Map.fetch!(rates_by_year(), @default_year)

  @doc """
  Rates for `year`, or for a specific `year`/`month` period.

  Without `month`, behaves as before — no period check. With `month`, returns
  `{:error, :period_not_covered}` when the period predates the tables this
  module has (1 June 2026), rather than silently computing SOCSO without
  SKBBK as if it were included.
  """
  def rates(year, month \\ nil)

  def rates(year, nil) do
    case Map.fetch(rates_by_year(), year) do
      {:ok, snapshot} -> snapshot
      :error -> {:error, :unsupported_year}
    end
  end

  def rates(year, month) when is_integer(month) do
    cond do
      month not in 1..12 -> {:error, :invalid_month}
      not Map.has_key?(rates_by_year(), year) -> {:error, :unsupported_year}
      {year, month} < @tables_effective_from -> {:error, :period_not_covered}
      true -> rates(year, nil)
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
  EIS contribution from the PERKESO Act 800 Second Schedule, wage ceiling
  RM6,000. Equal employer/employee shares per band.

  Eligibility (SIP Act 2017): Malaysian citizens and PRs aged 18-59.
  Foreign workers are not covered, and employees aged 60+ are not covered
  (they may be covered by SOCSO Category 2 instead). Pass
  `age_60_plus: true` or `citizenship: :non_malaysian` to get zero
  contribution for those profiles.
  """
  def eis(wage, _rates \\ nil, opts \\ []) do
    age_60_plus = Keyword.get(opts, :age_60_plus, false)
    citizenship = Keyword.get(opts, :citizenship, :malaysian)

    if age_60_plus or citizenship == :non_malaysian do
      %{employee: 0, employer: 0}
    else
      %{employer: employer_sen, employee: employee_sen} = Schedule.eis(Money.to_sen(wage))

      %{
        employee: Money.to_ringgit(employee_sen),
        employer: Money.to_ringgit(employer_sen)
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

  @doc "Round to nearest sen (2 decimal places) — pure Float arithmetic."
  def round_money(value) do
    value
    |> Kernel.*(100)
    |> Kernel.round()
    |> Kernel./(100)
  end
end
