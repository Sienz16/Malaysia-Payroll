defmodule PayrollApiWeb.PageControllerTest do
  use PayrollApiWeb.ConnCase

  test "GET / renders product landing page", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)
    assert html =~ "Payroll math"
    assert html =~ "hero-calculator-cta"
    assert html =~ "API docs"
  end

  test "GET /api-docs shows API documentation", %{conn: conn} do
    conn = get(conn, ~p"/api-docs")
    html = html_response(conn, 200)
    assert html =~ "Developer reference"
    assert html =~ "calculate-payslip"
    assert html =~ "Open playground"
  end

  test "GET /calculator shows playground", %{conn: conn} do
    conn = get(conn, ~p"/calculator")
    assert html_response(conn, 200) =~ "Payroll"
    assert html_response(conn, 200) =~ "playground"
    assert html_response(conn, 200) =~ "payroll-calculator-form"
  end
end
