defmodule PayrollApi.Statutory.Pcb do
  @moduledoc """
  Monthly PCB (Potongan Cukai Bulanan) — Malaysian income tax deduction.

  Implements the MTD (Monthly Tax Deduction) Method 1 calculation per
  LHDN guidelines:

    1. Compute annual income: monthly remuneration x 12
    2. Apply statutory reliefs (EPF capped at RM4,000/yr, individual RM9,000,
       spouse, children, etc.)
    3. Apply tax brackets to annual chargeable income (YA 2025 resident rates)
    4. Deduct rebate (RM400 if chargeable income <= RM35,000)
    5. Monthly PCB = annual tax / 12 (Method 1, no zakat handling here)

  All arithmetic is done in integer sen (see `PayrollApi.Statutory.Money`);
  ringgit floats appear only at the public boundary.

  NOTE: Rates/brackets are YA 2025 LHDN resident rates and live as data
  (see `brackets/0` and `reliefs/0`) so they can be updated per budget year.
  Full MTD also includes Method 2 (additional remuneration) — out of scope
  for v1.
  """

  alias PayrollApi.Statutory.Money

  @doc "YA 2025 resident income tax brackets: {lower_exclusive, rate_pct, cumulative_tax_at_lower}"
  def brackets, do: brackets(nil)

  def brackets(nil) do
    [
      {0, 0, 0},
      {5_000, 1, 0},
      {20_000, 3, 150},
      {35_000, 6, 600},
      {50_000, 11, 1_500},
      {70_000, 19, 3_700},
      {100_000, 25, 9_400},
      {400_000, 26, 84_400},
      {600_000, 28, 136_400},
      {2_000_000, 30, 528_400}
    ]
  end

  def brackets(rates), do: Map.get(rates, :pcb, %{}) |> Map.get(:brackets, brackets())

  @doc "Statutory reliefs (annual, RM)."
  def reliefs, do: reliefs(nil)

  def reliefs(nil) do
    %{
      individual: 9_000,
      # EPF/SOCSO contribution relief cap
      epf: 4_000,
      # per non-working spouse (additional)
      spouse: 4_000,
      life_insurance: 3_000,
      medical_insurance: 4_000,
      education_fees: 7_000,
      # per child under 18 (additional)
      child: 2_000
    }
  end

  def reliefs(rates), do: Map.get(rates, :pcb, %{}) |> Map.get(:reliefs, reliefs())

  @doc "Tax rebates (RM400 each) for chargeable income <= RM35,000."
  def rebate_threshold, do: rebate_threshold(nil)
  def rebate_threshold(nil), do: 35_000
  def rebate_threshold(rates), do: get_in(rates, [:pcb, :rebate_threshold]) || rebate_threshold()
  def rebate_amount, do: rebate_amount(nil)
  def rebate_amount(nil), do: 400
  def rebate_amount(rates), do: get_in(rates, [:pcb, :rebate_amount]) || rebate_amount()

  @doc """
  Calculate annual tax for a chargeable income (after reliefs).

  Returns `{tax, brackets_applied}` in ringgit (float, 2 dp). Internal
  arithmetic is integer sen. Applies the individual rebate; the spouse rebate
  (RM400) also applies when spouse relief was claimed.
  """
  def annual_tax(chargeable) when is_number(chargeable) and chargeable <= 0, do: {0.0, []}

  def annual_tax(chargeable, opts \\ %{}) when is_number(chargeable) do
    {tax_sen, applied} = annual_tax_sen(Money.to_sen(chargeable), opts)
    {Money.to_ringgit(tax_sen), applied}
  end

  # Integer-sen core. Returns {tax_sen, brackets_applied}.
  defp annual_tax_sen(chargeable_sen, _opts) when chargeable_sen <= 0, do: {0, []}

  defp annual_tax_sen(chargeable_sen, opts) do
    rates = Map.get(opts, :rates)

    {tax_sen, applied} =
      brackets(rates)
      |> Enum.reduce_while({0, []}, fn {lower_rm, pct, cum_rm}, {acc, list} ->
        lower_sen = Money.to_sen(lower_rm)

        if chargeable_sen > lower_sen do
          marginal_sen = Money.percentage(chargeable_sen - lower_sen, pct, 100)
          {:cont, {Money.to_sen(cum_rm) + marginal_sen, [{lower_rm, pct, cum_rm} | list]}}
        else
          {:halt, {acc, list}}
        end
      end)

    rebate_sen =
      cond do
        chargeable_sen > Money.to_sen(rebate_threshold(rates)) -> 0
        Map.get(opts, :spouse_relief, false) -> Money.to_sen(rebate_amount(rates)) * 2
        true -> Money.to_sen(rebate_amount(rates))
      end

    {max(tax_sen - rebate_sen, 0), Enum.reverse(applied)}
  end

  @doc """
  Compute monthly PCB from gross monthly wage + profile.

  Profile options:
    * `:wage` — gross monthly wage (RM)
    * `:spouse_eligible` — bool, non-working spouse relief applies (default false)
    * `:children` — int, number of children under 18 (default 0)
    * `:epf_monthly` — monthly EPF paid (defaults to 11% of wage, capped)
  """
  def monthly(%{wage: wage} = opts) when is_number(wage) and wage >= 0 do
    children = Map.get(opts, :children, 0)

    if not is_integer(children) or children < 0 do
      {:error, :invalid_children}
    else
      monthly_valid(opts, wage, children)
    end
  end

  def monthly(_), do: {:error, :invalid_wage}

  defp monthly_valid(opts, wage, children) do
    r = Map.get(opts, :rates, PayrollApi.Statutory.Rates.rates())
    wage_sen = Money.to_sen(wage)

    # Callers normally pass the EPF already computed for this payslip. The
    # fallback goes through the Third Schedule too — a percentage of wage would
    # disagree with the band tables and quietly shift the relief.
    epf_monthly_sen =
      case Map.fetch(opts, :epf_monthly) do
        {:ok, epf_monthly} -> epf_monthly
        :error -> PayrollApi.Statutory.Rates.epf(wage).employee
      end
      |> Money.to_sen()

    spouse_eligible = Map.get(opts, :spouse_eligible, false)
    reliefs = reliefs(r)

    annual_gross_sen = wage_sen * 12
    epf_annual_sen = min(epf_monthly_sen * 12, Money.to_sen(reliefs.epf))

    relief_total_sen =
      Money.to_sen(reliefs.individual) + epf_annual_sen +
        if(spouse_eligible, do: Money.to_sen(reliefs.spouse), else: 0) +
        children * Money.to_sen(reliefs.child)

    chargeable_sen = max(annual_gross_sen - relief_total_sen, 0)

    {annual_tax_sen_value, _} =
      annual_tax_sen(chargeable_sen, %{spouse_relief: spouse_eligible, rates: r})

    # Monthly PCB = annual tax / 12, rounded to the nearest sen (half up).
    monthly_pcb_sen = div(annual_tax_sen_value + 6, 12)

    %{
      annual_gross: Money.to_ringgit(annual_gross_sen),
      annual_reliefs: Money.to_ringgit(relief_total_sen),
      annual_chargeable: Money.to_ringgit(chargeable_sen),
      annual_tax: Money.to_ringgit(annual_tax_sen_value),
      monthly_pcb: Money.to_ringgit(monthly_pcb_sen)
    }
  end
end
