defmodule PayrollApi.Statutory.Payslip do
  @moduledoc """
  Full payslip calculation: gross wage -> statutory deductions -> net pay.

  Computes EPF, SOCSO, EIS, HRDF contributions (employee + employer shares),
  monthly PCB (income tax), and returns a breakdown ready for the API and
  the LiveView calculator.
  """

  alias PayrollApi.Statutory.Rates
  alias PayrollApi.Statutory.Pcb

  @doc """
  Calculate a full payslip breakdown.

  Options:
    * `:wage` - gross monthly wage (required)
    * `:include_hrdf` - whether HRDF levy applies (default true)
    * `:year` - rate year (default 2026)
    * `:married` - spouse tax relief applies (default false)
    * `:children` - number of children under 18 (default 0)
  """
  def calculate(opts) when is_map(opts) do
    wage = Map.get(opts, :wage)

    cond do
      is_nil(wage) -> {:error, :wage_required}
      not is_number(wage) -> {:error, :invalid_wage}
      wage < 0 -> {:error, :negative_wage}
      true -> do_calculate(wage, opts)
    end
  end

  def calculate(_), do: {:error, :invalid_input}

  defp do_calculate(wage, opts) do
    year = opts[:year] || 2026
    include_hrdf = Map.get(opts, :include_hrdf, true)
    rates = Rates.rates(year)

    epf = Rates.epf(wage, rates)
    socso = Rates.socso(wage, rates)
    eis = Rates.eis(wage, rates)
    hrdf = if include_hrdf, do: Rates.hrdf(wage, rates), else: %{employee: 0, employer: 0}
    pcb = Pcb.monthly(%{wage: wage, married: Map.get(opts, :married, false), children: Map.get(opts, :children, 0), epf_monthly: epf.employee})

    employee_total = epf.employee + socso.employee + eis.employee + hrdf.employee + pcb.monthly_pcb
    employer_total = epf.employer + socso.employer + eis.employer + hrdf.employer
    net_pay = wage - employee_total

    {:ok,
     %{
       wage: wage,
       year: year,
       employee_contributions: %{
         epf: epf.employee,
         socso: socso.employee,
         eis: eis.employee,
         hrdf: hrdf.employee,
         pcb: pcb.monthly_pcb,
         total: round2(employee_total)
       },
       employer_contributions: %{
         epf: epf.employer,
         socso: socso.employer,
         eis: eis.employer,
         hrdf: hrdf.employer,
         total: round2(employer_total)
       },
       tax_details: %{
         annual_gross: pcb.annual_gross,
         annual_reliefs: pcb.annual_reliefs,
         annual_chargeable: pcb.annual_chargeable,
         annual_tax: pcb.annual_tax
       },
       total_statutory_cost: round2(wage + employer_total),
       net_pay: round2(net_pay),
       rates_version: Rates.version()
     }}
  end

  defp round2(v), do: Float.round(v, 2)
end
