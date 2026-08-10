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

  @doc "GET /api/v1/ready — readiness probe for required workers"
  def ready(conn, _params) do
    if Process.whereis(PayrollApi.RateLimiter) do
      json(conn, %{success: true, status: "ready"})
    else
      conn
      |> put_status(:service_unavailable)
      |> json(%{success: false, status: "not_ready"})
    end
  end
end
