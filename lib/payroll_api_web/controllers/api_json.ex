defmodule PayrollApiWeb.ApiJSON do
  @moduledoc """
  JSON renderers for the payroll API.
  """

  alias PayrollApiWeb.I18n

  def rates(%{rates: rates, version: version, lang: lang}) do
    %{
      success: true,
      version: version,
      labels: %{
        wage: I18n.t(lang, :wage),
        rates: I18n.t(lang, :rates),
        minimum_wage: I18n.t(lang, :minimum_wage)
      },
      data: Map.delete(rates, :pcb),
      sources: PayrollApi.Statutory.Rates.sources(rates.year),
      supported_years: PayrollApi.Statutory.Rates.supported_years()
    }
  end

  def payslip(%{result: result, lang: lang}) do
    %{
      success: true,
      labels: %{
        wage: I18n.t(lang, :wage),
        employee_contributions: I18n.t(lang, :employee_contributions),
        employer_contributions: I18n.t(lang, :employer_contributions),
        epf: I18n.t(lang, :epf),
        socso: I18n.t(lang, :socso),
        eis: I18n.t(lang, :eis),
        hrdf: I18n.t(lang, :hrdf),
        pcb: I18n.t(lang, :pcb),
        net_pay: I18n.t(lang, :net_pay),
        total_statutory_cost: I18n.t(lang, :total_statutory_cost),
        tax_details: I18n.t(lang, :tax_details),
        annual_gross: I18n.t(lang, :annual_gross),
        annual_reliefs: I18n.t(lang, :annual_reliefs),
        annual_chargeable: I18n.t(lang, :annual_chargeable),
        annual_tax: I18n.t(lang, :annual_tax)
      },
      data: result
    }
  end
end
