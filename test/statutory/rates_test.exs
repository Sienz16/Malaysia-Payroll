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

  test "socso: Category 1 brackets, RM6,000 ceiling (verified 2024)" do
    # RM5,000 wage → employee 24.75, employer 84.55
    result = Rates.socso(5_000)
    assert result.employee == 24.75
    assert result.employer == 84.55

    # RM1,500 wage → employee 7.25, employer 25.05
    result2 = Rates.socso(1_500)
    assert result2.employee == 7.25
    assert result2.employer == 25.05

    # Above ceiling (RM7,000) caps at RM6,000 values
    result3 = Rates.socso(7_000)
    assert result3.employee == 29.75
    assert result3.employer == 101.55
  end

  test "socso: Category 2 (60+) employer-only rates" do
    result = Rates.socso(5_000, nil, %{age_60_plus: true})
    assert result.employee == 0.0
    assert result.employer == 60.3
  end

  test "eis: bracket table, RM6,000 ceiling" do
    result = Rates.eis(5_000)
    assert result.employee == 9.9
    assert result.employer == 9.9

    result2 = Rates.eis(1_500)
    assert result2.employee == 2.9
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
