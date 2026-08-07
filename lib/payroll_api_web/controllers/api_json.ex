defmodule PayrollApiWeb.ApiJSON do
  @moduledoc """
  JSON renderers for the payroll API.
  """

  def rates(%{rates: rates, version: version}) do
    %{
      success: true,
      version: version,
      data: rates
    }
  end

  def payslip(%{result: result}) do
    %{
      success: true,
      data: result
    }
  end
end
