defmodule PayrollApi.Statutory.Schedule do
  @moduledoc """
  Official statutory lookup tables, transcribed from primary sources.

  These are wage-*band* tables, not percentage formulas. KWSP and PERKESO both
  publish fixed contribution amounts per band, and a percentage approximation
  disagrees with them for any wage that is not exactly on a band boundary — so
  the tables are the only correct implementation below their cut-offs.

  Data lives in CSV under `priv/statutory/` so each figure is auditable against
  the source document without reading Elixir. Files are read at compile time
  and registered as `@external_resource`, so editing a table forces a rebuild.

  ## Sources

  * EPF — KWSP Third Schedule, EPF Act 1991, effective 1 October 2025.
    Parts A/C/E carry band tables covering RM0.01–RM20,000.00. Parts B and D
    were deleted by Act A1760/2025. Part F (non-citizens) is a flat 2%/2% rule
    with no table, so it is implemented in `Rates` rather than loaded here.

  * SOCSO — PERKESO Act 4 contribution table including SKBBK
    (Skim Kemalangan Bukan Bencana Kerja / Lindung 24 Jam), the 24-hour
    non-occupational accident scheme mandatory from 1 June 2026.

  Every table was validated at transcription time: printed component amounts
  sum to their printed totals, and bands tile their range with no gap or
  overlap. See `test/statutory/schedule_test.exs` for the known-answer checks
  that keep them honest.
  """

  @priv Path.expand("../../../priv/statutory", __DIR__)

  @epf_parts %{a: "part_a.csv", c: "part_c.csv", e: "part_e.csv"}
  @epf_dir Path.join(@priv, "epf_third_schedule_2025-10")
  @socso_file Path.join([@priv, "socso_act4_2026-06", "rates.csv"])

  # Parsing runs inside self-invoking closures because module attributes are
  # evaluated at compile time, before this module's own functions exist.
  # Amounts are converted to integer sen here so no float reaches a calculation.
  @load_rows fn path ->
    sen = fn
      "" -> nil
      text -> text |> String.trim() |> String.to_float() |> Kernel.*(100) |> round()
    end

    path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.drop(1)
    |> Enum.map(fn line -> line |> String.split(",") |> Enum.map(sen) end)
  end

  # EPF bands: {upper bound in sen, employer sen, employee sen}, ascending.
  @epf_bands Map.new(@epf_parts, fn {part, file} ->
               bands =
                 @load_rows.(Path.join(@epf_dir, file))
                 |> Enum.map(fn [_from, to, employer, employee] -> {to, employer, employee} end)

               {part, bands}
             end)

  # SOCSO rows: {upper bound in sen or nil for the open-ended top row, ...}.
  @socso_bands @load_rows.(@socso_file)
               |> Enum.map(fn [to, c1_er, c1_inv, c1_skbbk, c2_er, c2_skbbk] ->
                 {to, c1_er, c1_inv, c1_skbbk, c2_er, c2_skbbk}
               end)

  for file <- Map.values(@epf_parts) do
    @external_resource Path.join(@epf_dir, file)
  end

  @external_resource @socso_file

  @epf_table_ceiling @epf_bands[:a] |> List.last() |> elem(0)

  @doc """
  Highest wage (in sen) still covered by the EPF band tables. Above this the
  Third Schedule switches to percentage rules.
  """
  def epf_table_ceiling, do: @epf_table_ceiling

  @doc "Number of bands loaded for an EPF part — used by the data-integrity tests."
  def epf_band_count(part), do: length(Map.fetch!(@epf_bands, part))

  @doc "Number of SOCSO rows loaded."
  def socso_row_count, do: length(@socso_bands)

  @doc """
  EPF contribution for `wage_sen` from Third Schedule part `:a`, `:c`, or `:e`.

  Returns `{:ok, %{employer: sen, employee: sen}}`, or `:above_table` when the
  wage exceeds RM20,000.00 and the caller must apply the percentage rule.
  """
  def epf(part, wage_sen) when is_integer(wage_sen) do
    bands = Map.fetch!(@epf_bands, part)

    case Enum.find(bands, fn {max, _er, _ee} -> wage_sen <= max end) do
      nil -> :above_table
      {_max, employer, employee} -> {:ok, %{employer: employer, employee: employee}}
    end
  end

  @doc """
  SOCSO contribution for `wage_sen`.

  `category` is `:category1` (employment injury + invalidity + SKBBK, for
  employees under 60) or `:category2` (employment injury + SKBBK, for employees
  aged 60 and over). The employee side of Category 1 is the invalidity share
  plus SKBBK; Category 2 employees pay SKBBK only.

  The final row is open-ended, so every wage resolves to a band.
  """
  def socso(category, wage_sen) when is_integer(wage_sen) do
    {_max, c1_er, c1_inv, c1_skbbk, c2_er, c2_skbbk} = socso_row(wage_sen)

    case category do
      :category1 -> %{employer: c1_er, employee: c1_inv + c1_skbbk}
      :category2 -> %{employer: c2_er, employee: c2_skbbk}
    end
  end

  @doc "SKBBK component alone for `wage_sen`, for reporting and tests."
  def skbbk(wage_sen) when is_integer(wage_sen) do
    {_max, _c1_er, _c1_inv, c1_skbbk, _c2_er, _c2_skbbk} = socso_row(wage_sen)
    c1_skbbk
  end

  defp socso_row(wage_sen) do
    Enum.find(@socso_bands, fn {max, _, _, _, _, _} ->
      is_nil(max) or wage_sen <= max
    end)
  end
end
