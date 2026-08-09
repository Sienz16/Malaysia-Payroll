defmodule PayrollApi.RateLimiter do
  @moduledoc """
  In-memory sliding-window rate limiter keyed by API key.

  Default: 1,000 requests / month per key (free tier). Window is a rolling
  30-day bucket; `PAYROLL_RATE_LIMIT` env overrides the count.

  All quota state lives inside this GenServer's process, so every
  read/update cycle is atomic on a single node: concurrent requests are
  serialized and cannot lose updates. This is an explicitly single-node,
  in-memory limiter — a restart resets all counters, and it must not be
  treated as a durable quota across nodes or restarts.
  """

  use GenServer

  @window_seconds 30 * 24 * 60 * 60

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state), do: {:ok, state}

  def limit, do: String.to_integer(System.get_env("PAYROLL_RATE_LIMIT", "1000"))

  @doc """
  Record a request for key. Returns {:ok, remaining} or {:error, :rate_limited}.

  The check and counter update happen inside the GenServer process, making
  the read/filter/write cycle atomic.
  """
  def check(key) do
    GenServer.call(__MODULE__, {:check, key})
  end

  @impl true
  def handle_call({:check, key}, _from, state) do
    now = System.system_time(:second)
    limit = limit()
    hits = Map.get(state, key, [])

    fresh = Enum.filter(hits, fn t -> now - t < @window_seconds end)

    if length(fresh) >= limit do
      {:reply, {:error, :rate_limited}, Map.put(state, key, fresh)}
    else
      {:reply, {:ok, limit - length(fresh) - 1}, Map.put(state, key, [now | fresh])}
    end
  end
end
