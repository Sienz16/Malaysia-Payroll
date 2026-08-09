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

  test "zero wage rejected instead of creating impossible deductions" do
    assert {:error, :zero_wage} = Payslip.calculate(%{wage: 0})
    assert {:error, :zero_wage} = Payslip.calculate(%{wage: 0.0})
  end

  test "bulk row with zero wage gets a row error, not a negative payslip" do
    assert {:ok, %{results: [%{ok: false, error: :zero_wage}]}} =
             Payslip.calculate_bulk(%{employees: [%{wage: 0}]})
  end

  test "bulk batch over 500 employees rejected without calculation" do
    employees = Enum.map(1..501, fn i -> %{wage: 5000, name: "E#{i}"} end)
    assert {:error, :bulk_too_large} = Payslip.calculate_bulk(%{employees: employees})
  end

  test "bulk batch exactly at limit still processes" do
    employees = Enum.map(1..500, fn _ -> %{wage: 5000} end)
    assert {:ok, %{count: 500}} = Payslip.calculate_bulk(%{employees: employees})
  end

  test "unsupported year rejected at domain boundary" do
    assert {:error, :unsupported_year} = Payslip.calculate(%{wage: 5000, year: 2099})
  end

  test "selected year controls returned rates version" do
    {:ok, result} = Payslip.calculate(%{wage: 5000, year: 2025})
    assert result.year == 2025
    assert result.rates_version == "2025.2"
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

  test "bulk preserves employee statutory profiles" do
    {:ok, %{results: [foreign, older, spouse]}} =
      Payslip.calculate_bulk(%{
        employees: [
          %{name: "Foreign", wage: 21_250, citizenship: :non_malaysian},
          %{name: "Older", wage: 21_250, age_60_plus: true},
          %{name: "Spouse", wage: 5000, spouse_eligible: true}
        ],
        include_hrdf: false
      })

    assert foreign.data.employee_contributions.epf == 425.0
    assert older.data.employee_contributions.epf == 0.0
    assert spouse.data.tax_details.annual_reliefs == 17_000.0
  end

  test "include_hrdf false removes HRDF" do
    {:ok, result} = Payslip.calculate(%{wage: 5000, include_hrdf: false})
    assert result.employer_contributions.hrdf == 0
    # 794.45 - 50 = 744.45
    assert result.employer_contributions.total == 744.45
  end

  describe "employee statutory profile reaches payslip (PAY-006)" do
    test "age 60+ uses SOCSO Category 2 (no employee share) and zero EIS" do
      {:ok, result} = Payslip.calculate(%{wage: 5000, age_60_plus: true})

      # Category 2 at RM5,000: employer 60.30, employee 0.00
      assert result.employee_contributions.socso == 0.0
      assert result.employer_contributions.socso == 60.3
      # EIS does not cover 60+ (SIP Act 2017)
      assert result.employee_contributions.eis == 0.0
      assert result.employer_contributions.eis == 0.0
      # EPF 60+: employee 0%, employer 4%
      assert result.employee_contributions.epf == 0.0
      assert result.employer_contributions.epf == 200.0
    end

    test "non-Malaysian profile: flat EPF 2%/2%, zero EIS" do
      {:ok, result} = Payslip.calculate(%{wage: 5000, citizenship: :non_malaysian})

      # EPF non-Malaysian: 2% employee + 2% employer
      assert result.employee_contributions.epf == 100.0
      assert result.employer_contributions.epf == 100.0
      # EIS excludes foreign workers
      assert result.employee_contributions.eis == 0.0
      assert result.employer_contributions.eis == 0.0
      # SOCSO Category 1 still applies to foreign workers below 60
      assert result.employee_contributions.socso == 24.75
    end

    test "default Malaysian below 60 keeps full EIS and Category 1 SOCSO" do
      {:ok, result} = Payslip.calculate(%{wage: 5000})
      assert result.employee_contributions.eis == 9.9
      assert result.employee_contributions.socso == 24.75
      assert result.employee_contributions.epf == 550.0
    end
  end
end
