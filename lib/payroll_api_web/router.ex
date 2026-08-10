defmodule PayrollApiWeb.Router do
  use PayrollApiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PayrollApiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :api_rate_limit do
    plug PayrollApiWeb.Plug.RateLimit
  end

  # Public endpoints — no auth.
  scope "/api/v1", PayrollApiWeb do
    pipe_through :api

    get "/health", HealthController, :health
    get "/ready", HealthController, :ready
    get "/openapi.yaml", ApiController, :openapi_spec
  end

  # Public calculator API — rate limited by client IP.
  scope "/api/v1", PayrollApiWeb do
    pipe_through [:api, :api_rate_limit]

    get "/rates", ApiController, :rates
    post "/calculate-payslip", ApiController, :calculate_payslip
    post "/calculate-payslip/bulk", ApiController, :calculate_payslip_bulk
    get "/payslip.pdf", ApiController, :payslip_pdf
  end

  # Web UI (LiveView calculator).
  scope "/", PayrollApiWeb do
    pipe_through :browser

    live "/", PayrollLive
    live "/calculator", CalculatorLive
    get "/api-docs", PageController, :docs
  end
end
