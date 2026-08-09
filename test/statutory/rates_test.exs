defmodule PayrollApi.Statutory.RatesTest do
  use ExUnit.Case, async: true

  alias PayrollApi.Statutory.Rates

  test "epf: strict mode requires wage schedule below RM20,000.01" do
    assert {:error, :epf_schedule_required} = Rates.epf(4800, nil, strict_schedule: true)
  end

  test "epf: strict mode requires wage schedule at RM20,000" do
    assert {:error, :epf_schedule_required} = Rates.epf(20_000, nil, strict_schedule: true)
  end

  test "epf: percentage calculation applies above RM20,000" do
    assert Rates.epf(21_250) == %{employee: 2337.5, employer: 2550.5}
  end

  test "epf: age 60 Malaysian uses employer-only rate above RM20,000" do
    assert Rates.epf(21_250, nil, age_60_plus: true) == %{employee: 0.0, employer: 850.0}
  end

  test "epf: non-Malaysian uses 2% shares" do
    assert Rates.epf(21_250, nil, citizenship: :non_malaysian) == %{
             employee: 425.0,
             employer: 425.0
           }
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

  test "hrdf supports reduced and exempt categories" do
    assert Rates.hrdf(5000, nil, category: :reduced_0_5pct).employer == 25.0
    assert Rates.hrdf(5000, nil, category: :exempt).employer == 0
  end

  test "round_money rounds to 2 decimals" do
    assert Rates.round_money(99.999) == 100.0
    assert Rates.round_money(10.555) == 10.56
  end
end
