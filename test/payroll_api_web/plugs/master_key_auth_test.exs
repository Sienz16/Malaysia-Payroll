defmodule PayrollApiWeb.Plug.MasterKeyAuthTest do
  use ExUnit.Case, async: false

  import Plug.Test

  alias PayrollApiWeb.Plug.MasterKeyAuth

  test "accepts configured application master key" do
    conn = conn(:get, "/") |> Plug.Conn.assign(:api_key, "test-master-key-123")
    result = MasterKeyAuth.call(conn, [])

    assert result.halted == false
    assert result.status == nil
  end
end
