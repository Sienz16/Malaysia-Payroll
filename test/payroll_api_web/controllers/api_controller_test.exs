defmodule PayrollApiWeb.ApiControllerTest do
  use PayrollApiWeb.ConnCase

  test "GET /api/v1/rates returns rate tables", %{conn: conn} do
    conn = get(conn, ~p"/api/v1/rates")
    assert json_response(conn, 200)["success"] == true
    assert json_response(conn, 200)["data"]["epf"]["employee_rate"] == 0.11
  end

  test "POST /api/v1/calculate-payslip with wage", %{conn: conn} do
    conn =
      post(conn, ~p"/api/v1/calculate-payslip", %{"wage" => 5000})

    body = json_response(conn, 200)
    assert body["success"] == true
    assert body["data"]["employee_contributions"]["epf"] == 550.0
    assert body["data"]["employee_contributions"]["pcb"] == 110.0
    assert body["data"]["net_pay"] == 4312.0
  end

  test "POST calculate-payslip with married + children reduces PCB", %{conn: conn} do
    single =
      post(conn, ~p"/api/v1/calculate-payslip", %{"wage" => 5000})
      |> json_response(200)

    married =
      post(conn, ~p"/api/v1/calculate-payslip", %{"wage" => 5000, "married" => "true", "children" => 2})
      |> json_response(200)

    assert married["data"]["employee_contributions"]["pcb"] <
             single["data"]["employee_contributions"]["pcb"]
  end

  test "POST calculate-payslip missing wage → 400", %{conn: conn} do
    conn = post(conn, ~p"/api/v1/calculate-payslip", %{})
    assert json_response(conn, 400)["error"]["message"] =~ "wage"
  end
end
