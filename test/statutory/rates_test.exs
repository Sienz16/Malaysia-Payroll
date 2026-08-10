defmodule PayrollApi.Statutory.RatesTest do
  use ExUnit.Case, async: true

  alias PayrollApi.Statutory.Rates

  # Known answers below are read straight off the KWSP Third Schedule effective
  # 1 October 2025 and the PERKESO Act 4 table including SKBBK. Each assertion
  # names the band it comes from so it can be checked against the source PDF.

  test "epf: mid-band wage takes the band amount, not a percentage of wage" do
    # Part A band RM2,980.01–RM3,000.00 → employer RM390.00, employee RM330.00.
    # A percentage of RM2,985 would give 328.35 / 388.05, which is the bug this
    # table replaced: every wage off a band boundary was wrong.
    assert Rates.epf(2985) == %{employee: 330.0, employer: 390.0}
    assert Rates.epf(2999.99) == %{employee: 330.0, employer: 390.0}
  end

  test "epf: band boundary RM5,000 (Part A)" do
    assert Rates.epf(5000) == %{employee: 550.0, employer: 650.0}
  end

  test "epf: Part E applies to Malaysian citizens aged 60+" do
    # Band RM4,980.01–RM5,000.00 → employer RM200.00, employee nil.
    assert Rates.epf(5000, nil, age_60_plus: true) == %{employee: 0.0, employer: 200.0}
  end

  test "epf: Part C applies to non-citizen permanent residents aged 60+" do
    # Band RM4,980.01–RM5,000.00 → employer RM325.00, employee RM275.00.
    assert Rates.epf(5000, nil,
             citizenship: :non_malaysian,
             permanent_resident: true,
             age_60_plus: true
           ) == %{employee: 275.0, employer: 325.0}
  end

  test "epf: non-citizen permanent residents under 60 follow Part A" do
    assert Rates.epf(5000, nil, citizenship: :non_malaysian, permanent_resident: true) ==
             Rates.epf(5000)
  end

  test "epf: RM20,000 is the last banded wage" do
    assert Rates.epf(20_000) == %{employee: 2200.0, employer: 2400.0}
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

  test "socso: Category 1 includes SKBBK in the employee share" do
    # RM5,000 row → employer 86.65, employee 24.75 invalidity + 37.15 SKBBK.
    result = Rates.socso(5_000)
    assert result.employee == 61.90
    assert result.employer == 86.65

    # RM1,500 row → employer 25.35, employee 7.25 + 10.85.
    result2 = Rates.socso(1_500)
    assert result2.employee == 18.10
    assert result2.employer == 25.35
  end

  test "socso: wages above the RM6,000 ceiling stay at the ceiling amounts" do
    result = Rates.socso(7_000)
    assert result.employee == 74.40
    assert result.employer == 104.15

    assert Rates.socso(1_000_000) == result
  end

  test "socso: Category 2 (60+) employee pays SKBBK only" do
    # SKBBK is not age-limited: 60+ employees contribute it even though they
    # pay no invalidity share.
    result = Rates.socso(5_000, nil, %{age_60_plus: true})
    assert result.employee == 37.15
    assert result.employer == 61.90
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
