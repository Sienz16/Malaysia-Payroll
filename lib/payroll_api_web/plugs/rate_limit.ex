defmodule PayrollApiWeb.Plug.RateLimit do
  @moduledoc """
  Rate limiting plug for authenticated API requests.

  Uses `PayrollApi.RateLimiter` keyed by client IP. Returns 429 with
  Retry-After when exceeded.
  """

  import Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    client = conn.remote_ip |> :inet.ntoa() |> to_string()

    case PayrollApi.RateLimiter.check(client) do
      {:ok, remaining} ->
        conn
        |> put_resp_header(
          "x-ratelimit-limit",
          Integer.to_string(PayrollApi.RateLimiter.limit())
        )
        |> put_resp_header("x-ratelimit-remaining", Integer.to_string(remaining))

      {:error, :rate_limited} ->
        conn
        |> put_resp_header(
          "retry-after",
          Integer.to_string(PayrollApi.RateLimiter.retry_after(client))
        )
        |> put_resp_content_type("application/json")
        |> send_resp(429, Jason.encode!(%{error: %{message: "rate limit exceeded"}}))
        |> halt()
    end
  end
end
