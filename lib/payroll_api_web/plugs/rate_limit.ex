defmodule PayrollApiWeb.Plug.RateLimit do
  @moduledoc """
  Rate limiting plug for authenticated API requests.

  Uses `PayrollApi.RateLimiter` keyed by the API key already set in
  `conn.assigns[:api_key]`. Returns 429 with Retry-After when exceeded.
  """

  import Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case conn.assigns[:api_key] do
      nil ->
        conn

      key ->
        case PayrollApi.RateLimiter.check(key) do
          {:ok, remaining} ->
            conn
            |> put_resp_header("x-ratelimit-limit", Integer.to_string(PayrollApi.RateLimiter.limit()))
            |> put_resp_header("x-ratelimit-remaining", Integer.to_string(remaining))

          {:error, :rate_limited} ->
            conn
            |> put_resp_header("retry-after", "86400")
            |> put_resp_content_type("application/json")
            |> send_resp(429, Jason.encode!(%{error: %{message: "rate limit exceeded"}}))
            |> halt()
        end
    end
  end
end
