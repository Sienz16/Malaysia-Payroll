defmodule PayrollApi.Keys do
  @moduledoc """
  API key management.

  **Security Limitation**: Keys are stored in an ETS table in memory and are not
  tenant-aware or encrypted at rest. There is no audit trail for key usage.
  Replace with database-backed storage, encryption, and audit logging before
  production use.

  Master key comes from `PAYROLL_API_KEY` env. Additional keys can be
  registered at runtime (in-memory for v1 — replace with DB in a later
  sprint). Keys are compared in constant time where possible.
  """

  use GenServer

  @table :payroll_api_keys

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    seed_master()
    {:ok, %{}}
  end

  defp seed_master do
    key =
      System.get_env("PAYROLL_API_KEY") ||
        Application.get_env(:payroll_api, :api_key)

    case key do
      nil ->
        :ok

      "" ->
        :ok

      key ->
        :ets.insert(@table, {key, %{source: :master, created_at: System.system_time(:second)}})
    end
  end

  @doc "Register an additional API key."
  def add(key) when is_binary(key) and byte_size(key) >= 8 do
    :ets.insert(@table, {key, %{source: :manual, created_at: System.system_time(:second)}})
    :ok
  end

  def add(_), do: {:error, :key_too_short}

  @doc "Check a key is valid."
  def valid?(key) when is_binary(key) do
    :ets.lookup(@table, key) != []
  end

  def valid?(_), do: false

  @doc "Return configured master key from environment or application config."
  def master_key do
    System.get_env("PAYROLL_API_KEY") || Application.get_env(:payroll_api, :api_key, "")
  end

  @doc "Check whether key is configured master key."
  def master_key?(key) when is_binary(key) do
    master = master_key()

    master != "" and byte_size(key) == byte_size(master) and
      Plug.Crypto.secure_compare(key, master)
  end

  def master_key?(_), do: false

  @doc "Remove a key (master cannot be removed)."
  def remove(key) when is_binary(key) do
    case :ets.lookup(@table, key) do
      [{^key, %{source: :master}}] ->
        {:error, :master_key}

      [] ->
        {:error, :not_found}

      _ ->
        :ets.delete(@table, key)
        :ok
    end
  end
end
