defmodule PayrollApi.Statutory.PcbTest do
  use ExUnit.Case, async: true

  alias PayrollApi.Statutory.Pcb

  describe "annual_tax/1" do
    test "below 5,000 → 0 tax" do
      {tax, _} = Pcb.annual_tax(5_000)
      assert tax == 0.0
    end

    test "bracket 5,001-20,000 → 1% but rebate wipes it" do
      {tax, _} = Pcb.annual_tax(20_000)
      # bracket tax = 150; rebate 400 applies (<= 35k) → 0
      assert tax == 0.0
    end

    test "bracket 20,001-35,000 → 3% minus rebate" do
      {tax, _} = Pcb.annual_tax(35_000)
      # bracket tax = 600; rebate 400 → 200
      assert tax == 200.0
    end

    test "35,001-50,000 → 6% plus cumulative 600" do
      {tax, _} = Pcb.annual_tax(50_000)
      # 600 + (50000-35000)*6% = 600 + 900 = 1500
      assert tax == 1_500.0
    end

    test "rebate RM400 applies at chargeable <= 35,000" do
      {tax, _} = Pcb.annual_tax(30_000)
      # bracket tax = 150 + 10000*3% = 450; rebate 400 → 50
      assert tax == 50.0
    end

    test "high income 100,000 → 25% bracket" do
      {tax, _} = Pcb.annual_tax(100_000)
      # 9400 + (100000-100000)*25% = 9400
      assert tax == 9_400.0
    end
  end

  describe "monthly/1" do
    test "RM5,000 single → reasonable PCB" do
      result = Pcb.monthly(%{wage: 5000})
      assert result.annual_gross == 60_000.0
      assert result.annual_reliefs == 13_000.0  # 9000 + 4000 EPF
      assert result.annual_chargeable == 47_000.0
      # tax on 47000: 600 + 12000*6% = 600+720 = 1320
      assert result.annual_tax == 1_320.0
      assert result.monthly_pcb == 110.0
    end

    test "married with 2 children reduces tax" do
      single = Pcb.monthly(%{wage: 5000})
      married = Pcb.monthly(%{wage: 5000, married: true, children: 2})
      assert married.monthly_pcb < single.monthly_pcb
      assert married.annual_reliefs == 13_000.0 + 4_000.0 + 2 * 2_000.0
    end

    test "RM2,500 wage → chargeable 17,700, rebate zeroes tax" do
      result = Pcb.monthly(%{wage: 2500})
      # annual gross 30000; reliefs = 9000 + 3300 EPF = 12300 → 17700 chargeable
      assert result.annual_chargeable == 17_700.0
      # 17700 in 1% bracket → 127 tax, rebate 400 → 0
      assert result.monthly_pcb == 0.0
    end
  end
end
