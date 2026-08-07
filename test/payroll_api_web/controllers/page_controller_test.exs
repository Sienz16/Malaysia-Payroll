defmodule PayrollApiWeb.PageControllerTest do
  use PayrollApiWeb.ConnCase

  test "GET / redirects to LiveView root", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Payslip Calculator"
  end

  test "GET /api-docs shows API documentation", %{conn: conn} do
    conn = get(conn, ~p"/api-docs")
    assert html_response(conn, 200) =~ "API Documentation"
    assert html_response(conn, 200) =~ "calculate-payslip"
  end
end
