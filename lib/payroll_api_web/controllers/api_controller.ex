defmodule PayrollApiWeb.ApiController do
  use PayrollApiWeb, :controller

  alias PayrollApi.Statutory.Payslip
  alias PayrollApi.Statutory.Rates

  @doc "GET /api/v1/rates — current statutory rates as JSON"
  def rates(conn, params) do
    year = parse_year(params["year"])
    render(conn, :rates, %{rates: Rates.rates(year), version: Rates.version()})
  end

  @doc "POST /api/v1/calculate-payslip — compute statutory breakdown for a wage"
  def calculate_payslip(conn, %{"wage" => wage} = params) do
    include_hrdf = parse_bool(params["include_hrdf"])
    year = parse_year(params["year"])

    case Payslip.calculate(%{wage: wage, include_hrdf: include_hrdf, year: year}) do
      {:ok, result} -> render(conn, :payslip, %{result: result})
      {:error, reason} -> render_error(conn, reason)
    end
  end

  def calculate_payslip(conn, _params) do
    render_error(conn, :wage_required)
  end

  defp parse_year(nil), do: 2026
  defp parse_year(y) when is_integer(y), do: y
  defp parse_year(y) when is_binary(y) do
    case Integer.parse(y) do
      {n, _} -> n
      :error -> 2026
    end
  end

  defp parse_bool(nil), do: true
  defp parse_bool("false"), do: false
  defp parse_bool(false), do: false
  defp parse_bool(_), do: true

  defp render_error(conn, reason) do
    conn
    |> put_status(400)
    |> json(%{error: %{message: reason_to_message(reason)}})
  end

  defp reason_to_message(:wage_required), do: "wage is required (number)"
  defp reason_to_message(:invalid_wage), do: "wage must be a number"
  defp reason_to_message(:negative_wage), do: "wage cannot be negative"
  defp reason_to_message(:invalid_input), do: "invalid input"
  defp reason_to_message(other), do: inspect(other)
end
