defmodule PayrollApi.Input do
  def parse_wage(wage) when is_number(wage), do: {:ok, wage}

  def parse_wage(wage) when is_binary(wage) do
    case Float.parse(wage) do
      {value, ""} -> {:ok, value}
      _ -> {:error, :invalid_wage}
    end
  end

  def parse_wage(_), do: {:error, :invalid_wage}
end
