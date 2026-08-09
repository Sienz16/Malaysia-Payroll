defmodule PayrollApi.Statutory.Payslip do
  @moduledoc """
  Prototype payslip calculation: gross wage -> statutory deductions -> net pay.

  Computes EPF, SOCSO, EIS, HRDF contributions (employee + employer shares),
  monthly PCB (income tax), and returns a breakdown ready for the API and
  the LiveView calculator.
  """

  alias PayrollApi.Statutory.Rates
  alias PayrollApi.Statutory.Pcb
  alias PayrollApi.Statutory.Money

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
      wage == 0 -> {:error, :zero_wage}
      not is_integer(children) or children < 0 -> {:error, :invalid_children}
      true -> do_calculate(wage, opts)
    end
  end

  def calculate(_), do: {:error, :invalid_input}

  @max_bulk_employees 500

  @doc """
  Calculate payslips for multiple employees in one call.

  Accepts `%{employees: [%{name: ..., wage: ..., married: ..., children: ...}]}`
  plus optional `include_hrdf`/`year` defaults. Returns a list of results.

  The batch is capped at #{@max_bulk_employees} employees; larger batches
  return `{:error, :bulk_too_large}` without touching the calculator.
  """
  def calculate_bulk(%{employees: employees} = opts) when is_list(employees) do
    if length(employees) > @max_bulk_employees do
      {:error, :bulk_too_large}
    else
      calculate_bulk_rows(employees, opts)
    end
  end

  def calculate_bulk(_), do: {:error, :invalid_input}

  defp calculate_bulk_rows(employees, opts) do
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

          case normalize_wage(emp_value(emp, :wage, nil)) do
            {:ok, wage} ->
              case calculate(
                     Map.merge(defaults, %{
                       wage: wage,
                       married: emp_value(emp, :married, false),
                       children: emp_value(emp, :children, 0),
                       spouse_eligible: normalize_bool(emp_value(emp, :spouse_eligible, false)),
                       citizenship:
                         normalize_citizenship(emp_value(emp, :citizenship, :malaysian)),
                       age_60_plus: normalize_bool(emp_value(emp, :age_60_plus, false)),
                       hrdf_category:
                         normalize_hrdf_category(emp_value(emp, :hrdf_category, :standard_1pct))
                     })
                   ) do
                {:ok, result} -> %{name: name, ok: true, data: result}
                {:error, reason} -> %{name: name, ok: false, error: reason}
              end

            {:error, reason} ->
              %{name: name, ok: false, error: reason}
          end
        else
          %{name: "Employee #{idx}", ok: false, error: :invalid_input}
        end
      end)

    {:ok, %{count: length(results), results: results}}
  end

  # Same wage contract as the API boundary: numbers pass through, complete
  # numeric strings convert, anything else is a row error.
  defp normalize_wage(wage) when is_number(wage), do: {:ok, wage}

  defp normalize_wage(wage) when is_binary(wage) do
    case Float.parse(wage) do
      {w, ""} -> {:ok, w}
      _ -> {:error, :invalid_wage}
    end
  end

  defp normalize_wage(_), do: {:error, :invalid_wage}

  # Fetch a value by atom key, falling back to string key (JSON input).
  defp emp_value(map, key, default) do
    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, Atom.to_string(key)) -> Map.get(map, Atom.to_string(key))
      true -> default
    end
  end

  defp normalize_bool(true), do: true
  defp normalize_bool("true"), do: true
  defp normalize_bool(_), do: false

  defp normalize_citizenship(:non_malaysian), do: :non_malaysian
  defp normalize_citizenship("non_malaysian"), do: :non_malaysian
  defp normalize_citizenship(_), do: :malaysian

  defp normalize_hrdf_category(:reduced_0_5pct), do: :reduced_0_5pct
  defp normalize_hrdf_category("reduced_0_5pct"), do: :reduced_0_5pct
  defp normalize_hrdf_category(:exempt), do: :exempt
  defp normalize_hrdf_category("exempt"), do: :exempt
  defp normalize_hrdf_category(_), do: :standard_1pct

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

    socso = Rates.socso(wage, rates, %{age_60_plus: Map.get(opts, :age_60_plus, false)})

    eis =
      Rates.eis(wage, rates,
        age_60_plus: Map.get(opts, :age_60_plus, false),
        citizenship: Map.get(opts, :citizenship, :malaysian)
      )

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

    employee_total_sen =
      Money.sum([
        Money.to_sen(epf.employee),
        Money.to_sen(socso.employee),
        Money.to_sen(eis.employee),
        Money.to_sen(hrdf.employee),
        Money.to_sen(pcb.monthly_pcb)
      ])

    employer_total_sen =
      Money.sum([
        Money.to_sen(epf.employer),
        Money.to_sen(socso.employer),
        Money.to_sen(eis.employer),
        Money.to_sen(hrdf.employer)
      ])

    employee_total = Money.to_ringgit(employee_total_sen)
    employer_total = Money.to_ringgit(employer_total_sen)
    net_pay = Money.to_ringgit(Money.sub(Money.to_sen(wage), employee_total_sen))

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
         total: employee_total
       },
       employer_contributions: %{
         epf: epf.employer,
         socso: socso.employer,
         eis: eis.employer,
         hrdf: hrdf.employer,
         total: employer_total
       },
       tax_details: %{
         annual_gross: pcb.annual_gross,
         annual_reliefs: pcb.annual_reliefs,
         annual_chargeable: pcb.annual_chargeable,
         annual_tax: pcb.annual_tax
       },
       total_statutory_cost: Money.to_ringgit(Money.add(Money.to_sen(wage), employer_total_sen)),
       net_pay: net_pay,
       rates_version: Rates.version(year)
     }}
  end
end
