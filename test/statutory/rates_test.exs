defmodule PayrollApi.Statutory.RatesTest do
  use ExUnit.Case, async: true

  alias PayrollApi.Statutory.Rates

  test "epf: 11% employee, 12% employer below 5k" do
    result = Rates.epf(4800)
    # 4800 * 0.11 = 528.0 ; 4800 * 0.12 = 576.0
    assert result.employee == 528.0
    assert result.employer == 576.0
  end

  test "epf: employer rate 13% at/above 5k" do
    result = Rates.epf(5000)
    # wage == threshold → over 5k rate (13%)
    assert result.employee == 550.0
    assert result.employer == 650.0
  end

  test "socso: capped at wage ceiling" do
    result = Rates.socso(10_000)
    # capped at 4000: 0.5% = 20, 1.75% = 70
    assert result.employee == 20.0
    assert result.employer == 70.0
  end

  test "eis: 0.2% each side capped at ceiling" do
    result = Rates.eis(10_000)
    assert result.employee == 8.0
    assert result.employer == 8.0
  end

  test "hrdf: 1% employer only" do
    result = Rates.hrdf(5000)
    assert result.employee == 0
    assert result.employer == 50.0
  end

  test "round_money rounds to 2 decimals" do
    assert Rates.round_money(99.999) == 100.0
    assert Rates.round_money(10.555) == 10.56
  end
end
