defmodule PayrollApi.Statutory.PayslipTest do
  use ExUnit.Case, async: true

  alias PayrollApi.Statutory.Payslip

  test "full payslip for RM5,000 wage" do
    {:ok, result} = Payslip.calculate(%{wage: 5000})

    assert result.wage == 5000
    # employee: 550 EPF + 24.75 SOCSO + 9.90 EIS + 110 PCB = 694.65
    # 5000 - 694.65 = 4305.35
    assert result.net_pay == 4305.35
    assert result.employee_contributions.socso == 24.75
    assert result.employee_contributions.eis == 9.9
    assert result.employee_contributions.pcb == 110.0
    assert result.employee_contributions.total == 694.65
    # employer: 650 EPF + 84.55 SOCSO + 9.90 EIS + 50 HRDF = 794.45
    assert result.employer_contributions.socso == 84.55
    assert result.employer_contributions.total == 794.45
    assert result.total_statutory_cost == 5794.45
  end

  test "wage required" do
    assert {:error, :wage_required} = Payslip.calculate(%{})
  end

  test "negative wage rejected" do
    assert {:error, :negative_wage} = Payslip.calculate(%{wage: -100})
  end

  test "unsupported year rejected at domain boundary" do
    assert {:error, :unsupported_year} = Payslip.calculate(%{wage: 5000, year: 2099})
  end

  test "non-numeric wage rejected" do
    assert {:error, :invalid_wage} = Payslip.calculate(%{wage: "abc"})
  end

  test "negative children rejected" do
    assert {:error, :invalid_children} = Payslip.calculate(%{wage: 5000, children: -1})
  end

  test "bulk rejects non-map employees without crashing" do
    assert {:ok, %{results: [%{ok: false, error: :invalid_input}]}} =
             Payslip.calculate_bulk(%{employees: [nil]})
  end

  test "include_hrdf false removes HRDF" do
    {:ok, result} = Payslip.calculate(%{wage: 5000, include_hrdf: false})
    assert result.employer_contributions.hrdf == 0
    # 794.45 - 50 = 744.45
    assert result.employer_contributions.total == 744.45
  end
end
