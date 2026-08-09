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
    children = Map.get(opts, :children, 0)

    cond do
      is_nil(wage) -> {:error, :wage_required}
      not is_number(wage) -> {:error, :invalid_wage}
      wage < 0 -> {:error, :negative_wage}
      not is_integer(children) or children < 0 -> {:error, :invalid_children}
      true -> do_calculate(wage, opts)
    end
  end

  def calculate(_), do: {:error, :invalid_input}

  @doc """
  Calculate payslips for multiple employees in one call.

  Accepts `%{employees: [%{name: ..., wage: ..., married: ..., children: ...}]}`
  plus optional `include_hrdf`/`year` defaults. Returns a list of results.
  """
  def calculate_bulk(%{employees: employees} = opts) when is_list(employees) do
    defaults = %{
      include_hrdf: Map.get(opts, :include_hrdf, true),
      year: Map.get(opts, :year, 2026)
    }

    results =
      employees
      |> Enum.with_index(1)
      |> Enum.map(fn {emp, idx} ->
        if is_map(emp) do
          name = emp_value(emp, :name, "Employee #{idx}")

          case calculate(
                 Map.merge(defaults, %{
                   wage: emp_value(emp, :wage, nil),
                   married: emp_value(emp, :married, false),
                   children: emp_value(emp, :children, 0)
                 })
               ) do
            {:ok, result} -> %{name: name, ok: true, data: result}
            {:error, reason} -> %{name: name, ok: false, error: reason}
          end
        else
          %{name: "Employee #{idx}", ok: false, error: :invalid_input}
        end
      end)

    {:ok, %{count: length(results), results: results}}
  end

  def calculate_bulk(_), do: {:error, :invalid_input}

  # Fetch a value by atom key, falling back to string key (JSON input).
  defp emp_value(map, key, default) do
    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, Atom.to_string(key)) -> Map.get(map, Atom.to_string(key))
      true -> default
    end
  end

  defp do_calculate(wage, opts) do
    year = opts[:year] || 2026

    with rates when is_map(rates) <- Rates.rates(year) do
      calculate_with_rates(wage, opts, year, rates)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp calculate_with_rates(wage, opts, year, rates) do
    include_hrdf = Map.get(opts, :include_hrdf, true)
    hrdf_category = Map.get(opts, :hrdf_category, :standard_1pct)

    epf =
      Rates.epf(wage, rates,
        citizenship: Map.get(opts, :citizenship, :malaysian),
        age_60_plus: Map.get(opts, :age_60_plus, false)
      )

    socso = Rates.socso(wage, rates)
    eis = Rates.eis(wage, rates)

    hrdf =
      if include_hrdf,
        do: Rates.hrdf(wage, rates, category: hrdf_category),
        else: %{employee: 0, employer: 0}

    pcb =
      Pcb.monthly(%{
        wage: wage,
        spouse_eligible: Map.get(opts, :spouse_eligible, false),
        children: Map.get(opts, :children, 0),
        epf_monthly: epf.employee,
        rates: rates
      })

    employee_total =
      epf.employee + socso.employee + eis.employee + hrdf.employee + pcb.monthly_pcb

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
