defmodule PayrollApiWeb.ApiController do
  use PayrollApiWeb, :controller

  alias PayrollApi.Statutory.Payslip
  alias PayrollApi.Statutory.Rates
  alias PayrollApiWeb.I18n
  alias PayrollApi.Input

  @doc "GET /api/v1/rates — current statutory rates as JSON"
  def rates(conn, params) do
    with {:ok, year} <- parse_year(params["year"]) do
      lang = I18n.lang(params["lang"])
      render(conn, :rates, %{rates: Rates.rates(year), version: Rates.version(year), lang: lang})
    else
      {:error, :unsupported_year} -> render_error(conn, :unsupported_year)
    end
  end

  @doc "POST /api/v1/calculate-payslip — compute statutory breakdown for a wage"
  def calculate_payslip(conn, %{"wage" => wage} = params) do
    include_hrdf = parse_bool(params["include_hrdf"], true)
    hrdf_category = parse_hrdf_category(params["hrdf_category"])
    married = parse_bool(params["married"], false)
    lang = I18n.lang(params["lang"])

    with {:ok, wage} <- Input.parse_wage(wage),
         {:ok, year} <- parse_year(params["year"]),
         {:ok, children} <- parse_children(params["children"]) do
      case Payslip.calculate(%{
             wage: wage,
             include_hrdf: include_hrdf,
             hrdf_category: hrdf_category,
             citizenship: parse_citizenship(params["citizenship"]),
             age_60_plus: parse_bool(params["age_60_plus"], false),
             year: year,
             married: married,
             spouse_eligible: parse_bool(params["spouse_eligible"], false),
             children: children
           }) do
        {:ok, result} -> render(conn, :payslip, %{result: result, lang: lang})
        {:error, reason} -> render_error(conn, reason)
      end
    else
      {:error, :unsupported_year} -> render_error(conn, :unsupported_year)
      {:error, reason} -> render_error(conn, reason)
    end
  end

  def calculate_payslip(conn, _params) do
    render_error(conn, :wage_required)
  end

  @doc "POST /api/v1/calculate-payslip/bulk — multiple employees in one call"
  def calculate_payslip_bulk(conn, %{"employees" => employees} = params) do
    include_hrdf = parse_bool(params["include_hrdf"], true)
    hrdf_category = parse_hrdf_category(params["hrdf_category"])

    with {:ok, year} <- parse_year(params["year"]) do
      case Payslip.calculate_bulk(%{
             employees: employees,
             include_hrdf: include_hrdf,
             hrdf_category: hrdf_category,
             citizenship: parse_citizenship(params["citizenship"]),
             age_60_plus: parse_bool(params["age_60_plus"], false),
             year: year
           }) do
        {:ok, result} -> json(conn, %{success: true, data: result})
        {:error, reason} -> render_error(conn, reason)
      end
    else
      {:error, :unsupported_year} -> render_error(conn, :unsupported_year)
    end
  end

  def calculate_payslip_bulk(conn, _params) do
    render_error(conn, :invalid_input)
  end

  @doc "GET /api/v1/payslip.pdf?wage=5000 — download payslip as PDF"
  def payslip_pdf(conn, params) do
    with {:ok, wage} <- parse_wage_param(params),
         {:ok, year} <- parse_year(params["year"]) do
      include_hrdf = parse_bool(params["include_hrdf"], true)

      case Payslip.calculate(%{wage: wage, include_hrdf: include_hrdf, year: year}) do
        {:ok, result} ->
          pdf = PayrollApi.Pdf.payslip(result)

          conn
          |> put_resp_content_type("application/pdf")
          |> put_resp_header(
            "content-disposition",
            ~s(attachment; filename="payslip-#{wage}.pdf")
          )
          |> send_resp(200, pdf)

        {:error, reason} ->
          render_error(conn, reason)
      end
    else
      {:error, :unsupported_year} -> render_error(conn, :unsupported_year)
      {:error, reason} -> render_error(conn, reason)
    end
  end

  defp parse_wage_param(%{"wage" => wage}), do: Input.parse_wage(wage)

  defp parse_wage_param(_), do: {:error, :wage_required}

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

  defp parse_year(nil), do: {:ok, 2026}

  defp parse_year(y) when is_integer(y) do
    if y in Rates.supported_years(),
      do: {:ok, y},
      else: {:error, :unsupported_year}
  end

  defp parse_year(y) when is_binary(y) do
    case Integer.parse(y) do
      {n, ""} ->
        if n in Rates.supported_years(),
          do: {:ok, n},
          else: {:error, :unsupported_year}

      _ ->
        {:error, :unsupported_year}
    end
  end

  defp parse_year(_), do: {:error, :unsupported_year}

  defp parse_bool(nil, default), do: default
  defp parse_bool("false", _), do: false
  defp parse_bool(false, _), do: false
  defp parse_bool("true", _), do: true
  defp parse_bool(true, _), do: true
  defp parse_bool(_, default), do: default

  defp parse_hrdf_category("reduced_0_5pct"), do: :reduced_0_5pct
  defp parse_hrdf_category("exempt"), do: :exempt
  defp parse_hrdf_category(_), do: :standard_1pct

  defp parse_citizenship("non_malaysian"), do: :non_malaysian
  defp parse_citizenship(_), do: :malaysian

  # Strict children parsing: nil defaults to 0; any present value must be a
  # complete non-negative integer — trailing garbage or partial parses are
  # rejected instead of silently substituted.
  defp parse_children(nil), do: {:ok, 0}
  defp parse_children(v) when is_integer(v) and v >= 0, do: {:ok, v}
  defp parse_children(v) when is_integer(v), do: {:error, :invalid_children}

  defp parse_children(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, ""} when n >= 0 -> {:ok, n}
      _ -> {:error, :invalid_children}
    end
  end

  defp parse_children(_), do: {:error, :invalid_children}

  defp render_error(conn, reason) do
    conn
    |> put_status(400)
    |> json(%{error: %{message: reason_to_message(reason)}})
  end

  defp reason_to_message(:wage_required), do: "wage is required (number)"
  defp reason_to_message(:invalid_wage), do: "wage must be a number"
  defp reason_to_message(:negative_wage), do: "wage cannot be negative"
  defp reason_to_message(:zero_wage), do: "wage must be greater than zero"
  defp reason_to_message(:invalid_children), do: "children must be a non-negative integer"
  defp reason_to_message(:invalid_input), do: "invalid input"
  defp reason_to_message(:unsupported_year), do: "unsupported year"
  defp reason_to_message(:bulk_too_large), do: "bulk request exceeds maximum of 500 employees"
  defp reason_to_message(other), do: inspect(other)
end
