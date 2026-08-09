defmodule PayrollApiWeb.OpenApiContractTest do
  use ExUnit.Case, async: true

  alias PayrollApiWeb.Router

  @spec_path Path.expand("../../priv/static/openapi.yaml", __DIR__)

  defp spec_content, do: File.read!(@spec_path)

  test "openapi spec file exists and is non-empty" do
    content = spec_content()
    assert content =~ "openapi: 3.1.0"
    assert content =~ "paths:"
  end

  test "every router API route is present in the openapi spec" do
    content = spec_content()

    for path <- router_api_paths() do
      assert content =~ path, "router path #{path} missing from openapi spec"
    end
  end

  test "documented paths cover the full public contract" do
    content = spec_content()

    for path <- [
          "/health",
          "/openapi.yaml",
          "/rates",
          "/calculate-payslip",
          "/calculate-payslip/bulk",
          "/payslip.pdf",
          "/keys",
          "/keys/{key}"
        ] do
      assert content =~ path, "missing spec path #{path}"
    end
  end

  test "auth and rate limit responses are documented" do
    content = spec_content()
    assert content =~ "BearerAuth"
    assert content =~ "type: http"
    assert content =~ "scheme: bearer"
    assert content =~ "RateLimited"
    assert content =~ "Retry-After"
    assert content =~ "Unauthorized"
    assert content =~ "Forbidden"
  end

  test "SOCSO/EIS schema documents the current bracket table shape" do
    content = spec_content()
    assert content =~ "category1_brackets"
    assert content =~ "category2_brackets"
    assert content =~ "wage_ceiling: { type: number, example: 6000 }"
  end

  test "stale rate directions are not present" do
    content = spec_content()
    refute content =~ "employer_rate_under_5k"
    assert content =~ "employer_rate_at_or_under_5k: { type: number, example: 0.13 }"
    assert content =~ "employer_rate_over_5k: { type: number, example: 0.12 }"
  end

  defp router_api_paths do
    Router.__routes__()
    |> Enum.filter(fn route -> String.starts_with?(route.path, "/api/v1") end)
    |> Enum.map(fn route ->
      route.path
      |> String.replace_prefix("/api/v1", "")
      |> params_to_glob()
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp params_to_glob(path) do
    path
    |> String.split("/")
    |> Enum.map(fn seg ->
      if String.starts_with?(seg, ":"), do: "{" <> String.trim_leading(seg, ":") <> "}", else: seg
    end)
    |> Enum.join("/")
  end
end
