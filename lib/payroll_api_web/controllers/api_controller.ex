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
    include_hrdf = parse_bool(params["include_hrdf"], true)
    year = parse_year(params["year"])
    married = parse_bool(params["married"], false)
    children = parse_int(params["children"], 0)

    case Payslip.calculate(%{
           wage: wage,
           include_hrdf: include_hrdf,
           year: year,
           married: married,
           children: children
         }) do
      {:ok, result} -> render(conn, :payslip, %{result: result})
      {:error, reason} -> render_error(conn, reason)
    end
  end

  def calculate_payslip(conn, _params) do
    render_error(conn, :wage_required)
  end

  @doc "POST /api/v1/calculate-payslip/bulk — multiple employees in one call"
  def calculate_payslip_bulk(conn, %{"employees" => employees} = params) do
    include_hrdf = parse_bool(params["include_hrdf"], true)
    year = parse_year(params["year"])

    case Payslip.calculate_bulk(%{employees: employees, include_hrdf: include_hrdf, year: year}) do
      {:ok, result} -> json(conn, %{success: true, data: result})
      {:error, reason} -> render_error(conn, reason)
    end
  end

  def calculate_payslip_bulk(conn, _params) do
    render_error(conn, :invalid_input)
  end

  @doc "GET /api/v1/openapi.yaml — serve the OpenAPI spec"
  def openapi_spec(conn, _params) do
    path = Application.app_dir(:payroll_api, "priv/static/openapi.yaml")

    case File.read(path) do
      {:ok, content} ->
        conn
        |> put_resp_content_type("application/yaml")
        |> send_resp(200, content)

      {:error, _} ->
        conn
        |> put_status(404)
        |> json(%{error: %{message: "openapi spec not found"}})
    end
  end

  defp parse_year(nil), do: 2026
  defp parse_year(y) when is_integer(y), do: y
  defp parse_year(y) when is_binary(y) do
    case Integer.parse(y) do
      {n, _} -> n
      :error -> 2026
    end
  end

  defp parse_bool(nil, default), do: default
  defp parse_bool("false", _), do: false
  defp parse_bool(false, _), do: false
  defp parse_bool("true", _), do: true
  defp parse_bool(true, _), do: true
  defp parse_bool(_, default), do: default

  defp parse_int(nil, default), do: default
  defp parse_int(v, _default) when is_integer(v), do: v

  defp parse_int(v, default) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      :error -> default
    end
  end

  defp parse_int(_, default), do: default

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
