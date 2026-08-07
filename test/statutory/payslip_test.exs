defmodule PayrollApi.Statutory.PayslipTest do
  use ExUnit.Case, async: true

  alias PayrollApi.Statutory.Payslip

  test "full payslip for RM5,000 wage" do
    {:ok, result} = Payslip.calculate(%{wage: 5000})

    assert result.wage == 5000
    # employee: 550 EPF + 31.80 SOCSO + 8 EIS + 110 PCB = 699.80
    # 5000 - 699.80 = 4300.20
    assert result.net_pay == 4300.2
    assert result.employee_contributions.socso == 31.8
    assert result.employee_contributions.pcb == 110.0
    assert result.employee_contributions.total == 699.8
    # employer: 650 EPF + 390.05 SOCSO + 8 EIS + 50 HRDF = 1098.05
    assert result.employer_contributions.socso == 390.05
    assert result.employer_contributions.total == 1098.05
    assert result.total_statutory_cost == 6098.05
  end

  test "wage required" do
    assert {:error, :wage_required} = Payslip.calculate(%{})
  end

  test "negative wage rejected" do
    assert {:error, :negative_wage} = Payslip.calculate(%{wage: -100})
  end

  test "non-numeric wage rejected" do
    assert {:error, :invalid_wage} = Payslip.calculate(%{wage: "abc"})
  end

  test "include_hrdf false removes HRDF" do
    {:ok, result} = Payslip.calculate(%{wage: 5000, include_hrdf: false})
    assert result.employer_contributions.hrdf == 0
    # 1098.05 - 50 = 1048.05
    assert result.employer_contributions.total == 1048.05
  end
end
