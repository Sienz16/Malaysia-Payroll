defmodule PayrollApi.Statutory.MoneyTest do
  use ExUnit.Case, async: true

  alias PayrollApi.Statutory.Money

  describe "to_sen/1" do
    test "integers convert exactly" do
      assert Money.to_sen(5000) == 500_000
      assert Money.to_sen(0) == 0
    end

    test "floats round to nearest sen" do
      assert Money.to_sen(1.005) == 100
      assert Money.to_sen(0.1) == 10
    end
  end

  describe "percentage/3" do
    test "11% of 500,000 sen is 55,000 sen" do
      assert Money.percentage(500_000, 11, 100) == 55_000
    end

    test "13% of 500,000 sen is 65,000 sen" do
      assert Money.percentage(500_000, 13, 100) == 65_000
    end

    test "rounds half up" do
      # 1 sen * 1/2 = 0.5 -> rounds to 1
      assert Money.percentage(1, 1, 2) == 1
    end
  end

  describe "ceil_ringgit/1" do
    test "rounds up to whole ringgit" do
      assert Money.ceil_ringgit(1) == 100
      assert Money.ceil_ringgit(100) == 100
      assert Money.ceil_ringgit(101) == 200
    end
  end

  describe "sum/add/sub" do
    test "sums sen exactly" do
      assert Money.sum([100, 200, 300]) == 600
    end

    test "add/sub are exact integer math" do
      assert Money.add(500, 100) == 600
      assert Money.sub(500, 100) == 400
    end
  end
end
