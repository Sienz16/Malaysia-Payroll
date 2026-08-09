defmodule PayrollApiWeb.Plug.MasterKeyAuth do
  @moduledoc """
  Restricts a route to the configured master API key.

  Must be used after `PayrollApiWeb.Plug.ApiKeyAuth` so that a valid
  API key is already present in `conn.assigns[:api_key]`.
  """

  import Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    if PayrollApi.Keys.master_key?(conn.assigns[:api_key]) do
      conn
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(403, Jason.encode!(%{error: %{message: "forbidden: admin key required"}}))
      |> halt()
    end
  end
end
