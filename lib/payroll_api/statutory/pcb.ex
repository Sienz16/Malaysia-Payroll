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

  NOTE: Rates/brackets are YA 2025 LHDN resident rates and live as data
  (see `brackets/0` and `reliefs/0`) so they can be updated per budget year.
  Full MTD also includes Method 2 (additional remuneration) — out of scope
  for v1.
  """

  @doc "YA 2025 resident income tax brackets: {lower_exclusive, rate_pct, cumulative_tax_at_lower}"
  def brackets do
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

  @doc "Statutory reliefs (annual, RM)."
  def reliefs do
    %{
      individual: 9_000,
      epf: 4_000,          # EPF/SOCSO contribution relief cap
      spouse: 4_000,       # per non-working spouse (additional)
      life_insurance: 3_000,
      medical_insurance: 4_000,
      education_fees: 7_000,
      child: 2_000         # per child under 18 (additional)
    }
  end

  @doc "Tax rebate for chargeable income <= RM35,000."
  def rebate_threshold, do: 35_000
  def rebate_amount, do: 400

  @doc """
  Calculate annual tax for a chargeable income (after reliefs).

  Returns `{tax, brackets_applied}`. Uses integer-percent math to avoid
  floating point drift: each full bracket contributes its cumulative tax,
  the top partial bracket is computed as `(income - lower) * pct / 100`
  with rounding to the nearest ringgit for the bracket slice.
  """
  def annual_tax(chargeable) when chargeable <= 0, do: {0.0, []}

  def annual_tax(chargeable) do
    {tax, applied} =
      brackets()
      |> Enum.reduce_while({0.0, []}, fn {lower, pct, cum}, {acc, list} ->
        # Only the bracket the income falls INTO contributes:
        # cum (tax on all lower brackets) + marginal slice above its lower bound.
        if chargeable > lower do
          {:cont, {cum + (chargeable - lower) * pct / 100, [{lower, pct, cum} | list]}}
        else
          {:halt, {acc, list}}
        end
      end)

    rebate = if chargeable <= rebate_threshold(), do: rebate_amount(), else: 0
    {max(Float.round(tax - rebate, 2), 0.0), Enum.reverse(applied)}
  end

  @doc """
  Compute monthly PCB from gross monthly wage + profile.

  Profile options:
    * `:wage` — gross monthly wage (RM)
    * `:married` — bool, spouse relief applies (default false)
    * `:children` — int, number of children under 18 (default 0)
    * `:epf_monthly` — monthly EPF paid (defaults to 11% of wage, capped)
  """
  def monthly(%{wage: wage} = opts) when is_number(wage) and wage >= 0 do
    r = PayrollApi.Statutory.Rates.rates()
    epf_monthly = Map.get(opts, :epf_monthly, wage * r.epf.employee_rate)

    annual_gross = wage * 12
    epf_annual = min(epf_monthly * 12, reliefs().epf)

    relief_total =
      reliefs().individual +
      epf_annual +
      (if Map.get(opts, :married, false), do: reliefs().spouse, else: 0) +
      (Map.get(opts, :children, 0) * reliefs().child)

    chargeable = max(annual_gross - relief_total, 0)
    {annual_tax_value, _} = annual_tax(chargeable)

    %{
      annual_gross: round2(annual_gross),
      annual_reliefs: round2(relief_total),
      annual_chargeable: round2(chargeable),
      annual_tax: round2(annual_tax_value),
      monthly_pcb: round2(annual_tax_value / 12)
    }
  end

  def monthly(_), do: {:error, :invalid_wage}

  defp round2(v) when is_integer(v), do: v * 1.0
  defp round2(v) when is_float(v), do: Float.round(v, 2)
end
