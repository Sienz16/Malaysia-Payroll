defmodule PayrollApi.Statutory.Money do
  @moduledoc """
  Internal monetary representation in Malaysian sen (1 RM = 100 sen).

  All statutory calculations store values as integer sen to avoid binary
  floating-point drift. Conversion to ringgit happens only at presentation
  boundaries (API responses, LiveView, PDF). Rounding rules are explicit per
  scheme because PERKESO, KWSP, and LHDN define their own rounding modes.

  Current scope:
  - EPF: nearest sen (banker's rounding would be ideal; uses standard round for now)
  - SOCSO/EIS: table lookup values are already per-sen; no rounding needed
  - HRDF: nearest sen
  - PCB: nearest sen (placeholder for LHDN MTD rounding)
  """

  @typedoc "Amount in sen, stored as integer."
  @type sen :: integer()

  @doc "Convert ringgit (integer or float) to sen."
  def to_sen(value) when is_integer(value), do: value * 100
  def to_sen(value) when is_float(value), do: round(value * 100)

  @doc "Convert sen back to ringgit float for presentation."
  def to_ringgit(sen) when is_integer(sen), do: sen / 100

  @doc "Round a ringgit float to the nearest sen and return sen."
  def round_to_sen(value) when is_number(value), do: round(value * 100)

  @doc "Round a ringgit float to the nearest sen and return ringgit."
  def round_ringgit(value) when is_number(value), do: round(value * 100) / 100

  @doc "Add two sen values exactly."
  def add(a, b) when is_integer(a) and is_integer(b), do: a + b

  @doc "Subtract two sen values exactly."
  def sub(a, b) when is_integer(a) and is_integer(b), do: a - b

  @doc "Scale a sen value by a percentage rate, returning sen."
  def percentage(sen, rate) when is_integer(sen) and is_number(rate),
    do: round(sen * rate)

  @doc "Sum a list of sen values."
  def sum(values) when is_list(values), do: Enum.sum(values)
end
