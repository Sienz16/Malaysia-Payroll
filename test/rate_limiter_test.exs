defmodule PayrollApi.RateLimiterTest do
  use ExUnit.Case, async: false

  alias PayrollApi.RateLimiter

  setup do
    # Isolate from any real configured limit.
    old = System.get_env("PAYROLL_RATE_LIMIT")
    System.put_env("PAYROLL_RATE_LIMIT", "1000")

    on_exit(fn ->
      case old do
        nil -> System.delete_env("PAYROLL_RATE_LIMIT")
        val -> System.put_env("PAYROLL_RATE_LIMIT", val)
      end
    end)

    :ok
  end

  test "concurrent checks for the same key do not lose updates" do
    key = "concurrent-test-key"

    # 100 concurrent callers each recording one request. With an atomic
    # counter every caller below the limit must see {:ok, remaining} and
    # the final remaining must reflect all 100 requests.
    results =
      1..100
      |> Task.async_stream(fn _ -> RateLimiter.check(key) end, max_concurrency: 50, timeout: 5000)
      |> Enum.map(fn {:ok, res} -> res end)

    assert Enum.count(results, &match?({:ok, _}, &1)) == 100

    # After 100 hits, the next check is the 101st request, so remaining is
    # exactly limit - 101.
    assert {:ok, 899} = RateLimiter.check(key)
  end

  test "rate limit is enforced once quota is exhausted" do
    old = System.get_env("PAYROLL_RATE_LIMIT")
    System.put_env("PAYROLL_RATE_LIMIT", "3")

    on_exit(fn ->
      case old do
        nil -> System.delete_env("PAYROLL_RATE_LIMIT")
        val -> System.put_env("PAYROLL_RATE_LIMIT", val)
      end
    end)

    key = "quota-key"
    assert {:ok, 2} = RateLimiter.check(key)
    assert {:ok, 1} = RateLimiter.check(key)
    assert {:ok, 0} = RateLimiter.check(key)
    assert {:error, :rate_limited} = RateLimiter.check(key)
    assert {:error, :rate_limited} = RateLimiter.check(key)
  end

  test "keys are tracked independently" do
    assert {:ok, remaining_a} = RateLimiter.check("key-a")
    assert {:ok, remaining_b} = RateLimiter.check("key-b")
    assert remaining_a == remaining_b
    assert remaining_a == RateLimiter.limit() - 1
  end
end
