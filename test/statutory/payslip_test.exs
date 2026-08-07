defmodule PayrollApi.Statutory.PayslipTest do
  use ExUnit.Case, async: true

  alias PayrollApi.Statutory.Payslip

  test "full payslip for RM5,000 wage" do
    {:ok, result} = Payslip.calculate(%{wage: 5000})

    assert result.wage == 5000
    assert result.net_pay == 4422.0
    assert result.employee_contributions.total == 578.0
    assert result.employer_contributions.total == 778.0
    assert result.total_statutory_cost == 5778.0
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
    assert result.employer_contributions.total == 728.0
  end
end
