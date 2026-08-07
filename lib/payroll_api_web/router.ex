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

  # Public API — no auth for v1 (statutory rates are public data).
  scope "/api/v1", PayrollApiWeb do
    pipe_through :api

    get "/rates", ApiController, :rates
    post "/calculate-payslip", ApiController, :calculate_payslip
  end

  # Web UI (LiveView calculator).
  scope "/", PayrollApiWeb do
    pipe_through :browser

    live "/", PayrollLive
    get "/api-docs", PageController, :docs
  end
end
