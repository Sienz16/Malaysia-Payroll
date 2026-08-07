defmodule PayrollApiWeb.HealthController do
  use PayrollApiWeb, :controller

  @doc "GET /api/v1/health — liveness probe (no auth)"
  def health(conn, _params) do
    json(conn, %{
      success: true,
      status: "ok",
      version: PayrollApi.Statutory.Rates.version(),
      time: DateTime.utc_now()
    })
  end
end
