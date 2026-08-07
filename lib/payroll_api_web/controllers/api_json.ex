defmodule PayrollApiWeb.ApiJSON do
  @moduledoc """
  JSON renderers for the payroll API.
  """

  def rates(%{rates: rates, version: version}) do
    %{
      success: true,
      version: version,
      data: rates,
      sources: PayrollApi.Statutory.Rates.sources(rates.year),
      supported_years: PayrollApi.Statutory.Rates.supported_years()
    }
  end

  def payslip(%{result: result}) do
    %{
      success: true,
      data: result
    }
  end
end
