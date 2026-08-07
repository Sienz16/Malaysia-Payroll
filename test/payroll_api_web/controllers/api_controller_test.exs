defmodule PayrollApiWeb.ApiControllerTest do
  use PayrollApiWeb.ConnCase

  @test_key "test-master-key-123"

  defp auth(conn) do
    put_req_header(conn, "authorization", "Bearer #{@test_key}")
  end

  test "GET /api/v1/rates requires auth", %{conn: conn} do
    conn = get(conn, ~p"/api/v1/rates")
    assert json_response(conn, 401)["error"]["message"] =~ "API key"
  end

  test "GET /api/v1/rates with auth returns rate tables", %{conn: conn} do
    conn = get(auth(conn), ~p"/api/v1/rates")
    body = json_response(conn, 200)
    assert body["success"] == true
    assert body["data"]["epf"]["employee_rate"] == 0.11
    assert body["sources"]["epf"] != ""
    assert body["supported_years"] == [2025, 2026]
  end

  test "POST /api/v1/calculate-payslip with wage", %{conn: conn} do
    conn = post(auth(conn), ~p"/api/v1/calculate-payslip", %{"wage" => 5000})

    body = json_response(conn, 200)
    assert body["success"] == true
    assert body["data"]["employee_contributions"]["epf"] == 550.0
    assert body["data"]["employee_contributions"]["pcb"] == 110.0
    assert body["data"]["net_pay"] == 4312.0
  end

  test "POST calculate-payslip with married + children reduces PCB", %{conn: conn} do
    single =
      post(auth(conn), ~p"/api/v1/calculate-payslip", %{"wage" => 5000})
      |> json_response(200)

    married =
      post(auth(conn), ~p"/api/v1/calculate-payslip", %{"wage" => 5000, "married" => "true", "children" => 2})
      |> json_response(200)

    assert married["data"]["employee_contributions"]["pcb"] <
             single["data"]["employee_contributions"]["pcb"]
  end

  test "POST calculate-payslip missing wage → 400", %{conn: conn} do
    conn = post(auth(conn), ~p"/api/v1/calculate-payslip", %{})
    assert json_response(conn, 400)["error"]["message"] =~ "wage"
  end

  test "GET /api/v1/health is public", %{conn: conn} do
    conn = get(conn, ~p"/api/v1/health")
    body = json_response(conn, 200)
    assert body["status"] == "ok"
  end
end
