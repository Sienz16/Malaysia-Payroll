defmodule PayrollApi.RateLimiter do
  @moduledoc """
  Simple in-memory sliding-window rate limiter keyed by API key.

  Default: 1,000 requests / month per key (free tier). Window is a rolling
  30-day bucket; `PAYROLL_RATE_LIMIT` env overrides the count.
  """

  use GenServer

  @table :payroll_rate_limits
  @window_seconds 30 * 24 * 60 * 60

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    :ets.new(@table, [:named_table, :set, :public, write_concurrency: true])
    {:ok, %{}}
  end

  def limit, do: String.to_integer(System.get_env("PAYROLL_RATE_LIMIT", "1000"))

  @doc """
  Record a request for key. Returns {:ok, remaining} or {:error, :rate_limited}.
  """
  def check(key) do
    now = System.system_time(:second)

    case :ets.lookup(@table, key) do
      [] ->
        :ets.insert(@table, {key, [now]})
        {:ok, limit() - 1}

      [{^key, hits}] ->
        # drop hits older than the window
        fresh = Enum.filter(hits, fn t -> now - t < @window_seconds end)

        if length(fresh) >= limit() do
          :ets.insert(@table, {key, fresh})
          {:error, :rate_limited}
        else
          :ets.insert(@table, {key, [now | fresh]})
          {:ok, limit() - length(fresh) - 1}
        end
    end
  end
end
