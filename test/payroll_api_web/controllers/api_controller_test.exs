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
    assert body["data"]["employee_contributions"]["socso"] == 24.75
    assert body["data"]["employee_contributions"]["pcb"] == 110.0
    assert body["data"]["net_pay"] == 4305.35
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

  test "GET /api/v1/payslip.pdf returns a valid PDF", %{conn: conn} do
    conn = get(auth(conn), ~p"/api/v1/payslip.pdf?wage=5000")
    assert conn.status == 200
    assert List.first(get_resp_header(conn, "content-type")) =~ "application/pdf"
    body = conn.resp_body
    assert body |> String.starts_with?("%PDF-1.4")
    assert body =~ "xref"
    assert body =~ "%%EOF"
    assert body =~ "NET PAY"
  end

  test "GET /api/v1/payslip.pdf missing wage → 400", %{conn: conn} do
    conn = get(auth(conn), ~p"/api/v1/payslip.pdf")
    assert json_response(conn, 400)["error"]["message"] =~ "wage"
  end

  test "GET /api/v1/health is public", %{conn: conn} do
    conn = get(conn, ~p"/api/v1/health")
    body = json_response(conn, 200)
    assert body["status"] == "ok"
  end

  test "POST calculate-payslip with lang=ms returns BM labels", %{conn: conn} do
    conn = post(auth(conn), ~p"/api/v1/calculate-payslip", %{"wage" => 5000, "lang" => "ms"})
    body = json_response(conn, 200)
    assert body["labels"]["net_pay"] == "gaji_bersih"
    assert body["labels"]["epf"] == "KWSP"
    assert body["labels"]["socso"] == "PERKESO"
  end

  test "POST /api/v1/calculate-payslip/bulk processes multiple employees", %{conn: conn} do
    conn =
      post(auth(conn), ~p"/api/v1/calculate-payslip/bulk", %{
        "employees" => [
          %{"name" => "Ali", "wage" => 5000},
          %{"name" => "Siti", "wage" => 3000, "married" => "true", "children" => 1},
          %{"name" => "Bad", "wage" => -100}
        ]
      })

    body = json_response(conn, 200)
    assert body["success"] == true
    assert body["data"]["count"] == 3
    results = body["data"]["results"]

    ali = Enum.find(results, fn r -> r["name"] == "Ali" end)
    assert ali["ok"] == true
    assert ali["data"]["net_pay"] == 4305.35

    siti = Enum.find(results, fn r -> r["name"] == "Siti" end)
    assert siti["ok"] == true

    bad = Enum.find(results, fn r -> r["name"] == "Bad" end)
    assert bad["ok"] == false
  end
end
