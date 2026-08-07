defmodule PayrollApiWeb.KeyController do
  use PayrollApiWeb, :controller

  alias PayrollApi.Keys

  @doc "GET /api/v1/keys — list registered keys (redacted)"
  def index(conn, _params) do
    keys =
      :ets.tab2list(:payroll_api_keys)
      |> Enum.map(fn {k, %{source: source, created_at: created}} ->
        %{key_prefix: String.slice(k, 0, 8), source: source, created_at: created}
      end)

    json(conn, %{success: true, data: keys})
  end

  @doc "POST /api/v1/keys — register a new API key"
  def create(conn, %{"key" => key}) do
    case Keys.add(key) do
      :ok -> json(conn, %{success: true, message: "key added"})
      {:error, reason} -> json(conn, %{success: false, error: inspect(reason)})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{success: false, error: "key is required"})
  end

  @doc "DELETE /api/v1/keys/:key — remove a key"
  def delete(conn, %{"key" => key}) do
    case Keys.remove(key) do
      :ok -> json(conn, %{success: true, message: "key removed"})
      {:error, reason} -> json(conn, %{success: false, error: inspect(reason)})
    end
  end
end
