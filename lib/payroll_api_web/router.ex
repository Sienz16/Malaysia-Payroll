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

  pipeline :api_auth do
    plug PayrollApiWeb.Plug.ApiKeyAuth
    plug PayrollApiWeb.Plug.RateLimit
  end

  # Public endpoints — no auth.
  scope "/api/v1", PayrollApiWeb do
    pipe_through :api

    get "/health", HealthController, :health
  end

  # Authenticated API — Bearer key required.
  scope "/api/v1", PayrollApiWeb do
    pipe_through [:api, :api_auth]

    get "/rates", ApiController, :rates
    post "/calculate-payslip", ApiController, :calculate_payslip
    post "/calculate-payslip/bulk", ApiController, :calculate_payslip_bulk
    get "/keys", KeyController, :index
    post "/keys", KeyController, :create
    delete "/keys/:key", KeyController, :delete
  end

  # Web UI (LiveView calculator).
  scope "/", PayrollApiWeb do
    pipe_through :browser

    live "/", PayrollLive
    get "/api-docs", PageController, :docs
  end
end
