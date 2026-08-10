defmodule PayrollApi.InputTest do
  use ExUnit.Case, async: true

  alias PayrollApi.Input

  test "parses complete numeric wage values only" do
    assert {:ok, 5000} = Input.parse_wage(5000)
    assert {:ok, 5000.5} = Input.parse_wage("5000.5")
    assert {:error, :invalid_wage} = Input.parse_wage("5000abc")
  end
end
