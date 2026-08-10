defmodule PayrollApiWeb.HealthControllerTest do
  use PayrollApiWeb.ConnCase, async: true

  test "GET /api/v1/ready reports required worker availability", %{conn: conn} do
    conn = get(conn, ~p"/api/v1/ready")

    assert %{"success" => true, "status" => "ready"} = json_response(conn, 200)
  end
end
