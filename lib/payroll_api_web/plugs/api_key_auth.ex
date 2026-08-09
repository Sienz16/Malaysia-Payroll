defmodule PayrollApiWeb.Plug.ApiKeyAuth do
  @moduledoc """
  Bearer API key authentication for the public API.

  **Security Limitation**: This implementation only provides basic bearer key validation.
  It does **not** implement employer tenancy, role-based access control, or multi-tenant
  authorization boundaries. No per-employer data scoping exists because there is no
  persistence layer yet.

  Reads `Authorization: Bearer <key>` and compares against configured keys:
    1. `PAYROLL_API_KEY` env (master key)
    2. Keys in `PayrollApi.Keys` (DB-backed, added via /api/keys — Sprint 3+)

  Sets `conn.assigns[:api_key]` on success, halts with 401 on failure.
  """

  import Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> key] ->
        if valid_key?(key) do
          conn
          |> assign(:api_key, key)
          |> Plug.Conn.register_before_send(fn c ->
            put_resp_header(c, "x-api-key-used", String.slice(key, 0, 8))
          end)
        else
          unauthorized(conn)
        end

      _ ->
        unauthorized(conn)
    end
  end

  defp valid_key?(key) do
    PayrollApi.Keys.valid?(key)
  end

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{error: %{message: "invalid or missing API key"}}))
    |> halt()
  end
end
