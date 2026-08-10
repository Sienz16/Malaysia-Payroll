defmodule PayrollApi.Statutory.ScheduleTest do
  use ExUnit.Case, async: true

  alias PayrollApi.Statutory.Schedule

  # Structural guards on the transcribed tables. A bad edit to the CSVs — a
  # dropped row, a shifted column, a typo'd bound — should fail here rather
  # than quietly produce a wrong payslip.

  describe "EPF Third Schedule" do
    test "each part covers RM0.01 to RM20,000.00 with 401 bands" do
      for part <- [:a, :c, :e] do
        assert Schedule.epf_band_count(part) == 401
      end
    end

    test "the table ends at RM20,000 and hands over to percentage rules above" do
      assert Schedule.epf_table_ceiling() == 2_000_000

      assert {:ok, _} = Schedule.epf(:a, 2_000_000)
      assert :above_table = Schedule.epf(:a, 2_000_001)
    end

    test "every banded wage resolves to non-negative integer sen" do
      for part <- [:a, :c, :e], sen <- [1, 1000, 299_999, 300_000, 1_999_999, 2_000_000] do
        assert {:ok, %{employer: er, employee: ee}} = Schedule.epf(part, sen)
        assert is_integer(er) and er >= 0
        assert is_integer(ee) and ee >= 0
      end
    end

    test "employee share never decreases as wages rise" do
      for part <- [:a, :c, :e] do
        employees =
          1..2000
          |> Enum.map(fn thousand_sen ->
            {:ok, %{employee: ee}} = Schedule.epf(part, thousand_sen * 1000)
            ee
          end)

        assert employees == Enum.sort(employees), "#{part}: employee share not monotonic"
      end
    end

    test "employer share decreases only at the RM5,000 rate change" do
      # Genuine cliff in the schedule, not a transcription error: the employer
      # rate steps down above RM5,000 (13%→12% in Part A, 6.5%→6% in Part C),
      # so an employer pays less for a RM5,000.01 employee than a RM5,000 one.
      # Part E is a flat 4% and has no step.
      for {part, expected_drops} <- [a: [500_000], c: [500_000], e: []] do
        drops =
          1..2000
          |> Enum.map(fn thousand_sen ->
            {:ok, %{employer: er}} = Schedule.epf(part, thousand_sen * 1000)
            {thousand_sen * 1000, er}
          end)
          |> Enum.chunk_every(2, 1, :discard)
          |> Enum.filter(fn [{_, prev}, {_, next}] -> next < prev end)
          |> Enum.map(fn [{sen, _}, _] -> sen end)

        assert drops == expected_drops, "#{part}: unexpected employer step at #{inspect(drops)}"
      end
    end

    test "the RM5,000 employer cliff has the exact schedule amounts" do
      assert {:ok, %{employer: 65_000}} = Schedule.epf(:a, 500_000)
      assert {:ok, %{employer: 61_200}} = Schedule.epf(:a, 500_001)
    end

    test "Part E employees contribute nothing at any banded wage" do
      for thousand_sen <- 1..2000 do
        assert {:ok, %{employee: 0}} = Schedule.epf(:e, thousand_sen * 1000)
      end
    end
  end

  describe "SOCSO Act 4 table" do
    test "has 65 rows and the last one is open-ended" do
      assert Schedule.socso_row_count() == 65

      ceiling = Schedule.socso(:category1, 600_000)
      assert Schedule.socso(:category1, 100_000_000) == ceiling
    end

    test "Category 1 employee share is invalidity plus SKBBK" do
      # RM5,000 row: 24.75 invalidity + 37.15 SKBBK.
      assert Schedule.skbbk(500_000) == 3715
      assert Schedule.socso(:category1, 500_000) == %{employer: 8665, employee: 6190}
    end

    test "Category 2 employee share is SKBBK alone" do
      assert Schedule.socso(:category2, 500_000) == %{employer: 6190, employee: 3715}
      assert Schedule.socso(:category2, 500_000).employee == Schedule.skbbk(500_000)
    end

    test "contributions never decrease as wages rise" do
      for category <- [:category1, :category2] do
        shares =
          1..600
          |> Enum.map(&Schedule.socso(category, &1 * 1000))
          |> Enum.map(&{&1.employer, &1.employee})

        assert shares == Enum.sort(shares), "#{category}: share not monotonic"
      end
    end
  end
end
