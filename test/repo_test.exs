defmodule PayrollApi.RepoTest do
  use ExUnit.Case, async: true

  test "queries PostgreSQL" do
    assert %{rows: [[1]]} = PayrollApi.Repo.query!("SELECT 1")
  end
end
