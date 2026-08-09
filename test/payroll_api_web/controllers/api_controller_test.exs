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

  test "no tenant boundary: every valid key sees identical data (documented SEC-002)", %{
    conn: conn
  } do
    # There is no employer tenancy today: any valid key can read any data.
    # These tests pin the current behavior so introducing a tenant boundary
    # requires deliberately changing them. See docs/audits/current-backlog.md
    # SEC-002 for the documented limitation.
    PayrollApi.Keys.add("tenant-a-key-000")
    PayrollApi.Keys.add("tenant-b-key-111")

    key_a = put_req_header(conn, "authorization", "Bearer tenant-a-key-000")
    key_b = put_req_header(conn, "authorization", "Bearer tenant-b-key-111")

    a = get(key_a, ~p"/api/v1/rates?year=2026") |> json_response(200)
    b = get(key_b, ~p"/api/v1/rates?year=2026") |> json_response(200)

    assert a["data"] == b["data"]
  end

  test "plain key cannot administer keys (admin boundary enforced)", %{conn: conn} do
    PayrollApi.Keys.add("plain-key-999")
    conn = put_req_header(conn, "authorization", "Bearer plain-key-999")
    conn = get(conn, ~p"/api/v1/keys")
    assert json_response(conn, 403)["error"]["message"] =~ "admin key"
  end

  test "GET /api/v1/rates with auth returns rate tables", %{conn: conn} do
    conn = get(auth(conn), ~p"/api/v1/rates")
    body = json_response(conn, 200)
    assert body["success"] == true
    assert body["data"]["epf"]["employee_rate"] == 0.11
    assert body["sources"]["epf"] != ""
    assert body["supported_years"] == [2025, 2026]
  end

  test "GET /api/v1/rates rejects malformed year", %{conn: conn} do
    conn = get(auth(conn), ~p"/api/v1/rates?year=2026.0")
    assert json_response(conn, 400)["error"]["message"] =~ "unsupported year"
  end

  test "GET /api/v1/rates returns selected year version", %{conn: conn} do
    body = get(auth(conn), ~p"/api/v1/rates?year=2025") |> json_response(200)
    assert body["version"] == "2025.2"
    assert body["data"]["year"] == 2025
  end

  test "GET /api/v1/rates rejects non-numeric year values", %{conn: conn} do
    conn = get(auth(conn), ~p"/api/v1/rates?year[]=2026")
    assert json_response(conn, 400)["error"]["message"] =~ "unsupported year"
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
      post(auth(conn), ~p"/api/v1/calculate-payslip", %{
        "wage" => 5000,
        "married" => "true",
        "children" => 2
      })
      |> json_response(200)

    assert married["data"]["employee_contributions"]["pcb"] <
             single["data"]["employee_contributions"]["pcb"]
  end

  test "POST calculate-payslip missing wage → 400", %{conn: conn} do
    conn = post(auth(conn), ~p"/api/v1/calculate-payslip", %{})
    assert json_response(conn, 400)["error"]["message"] =~ "wage"
  end

  test "POST calculate-payslip zero wage → 400", %{conn: conn} do
    conn = post(auth(conn), ~p"/api/v1/calculate-payslip", %{"wage" => 0})
    assert json_response(conn, 400)["error"]["message"] =~ "greater than zero"
  end

  test "children trailing garbage rejected instead of defaulting", %{conn: conn} do
    conn =
      post(auth(conn), ~p"/api/v1/calculate-payslip", %{"wage" => 5000, "children" => "2abc"})

    assert json_response(conn, 400)["error"]["message"] =~ "children"

    conn =
      post(auth(build_conn()), ~p"/api/v1/calculate-payslip", %{
        "wage" => 5000,
        "children" => "2.5"
      })

    assert json_response(conn, 400)["error"]["message"] =~ "children"
  end

  test "negative children rejected", %{conn: conn} do
    conn = post(auth(conn), ~p"/api/v1/calculate-payslip", %{"wage" => 5000, "children" => -1})
    assert json_response(conn, 400)["error"]["message"] =~ "children"
  end

  test "year trailing garbage rejected", %{conn: conn} do
    conn =
      post(auth(conn), ~p"/api/v1/calculate-payslip", %{"wage" => 5000, "year" => "2026junk"})

    assert json_response(conn, 400)["error"]["message"] =~ "unsupported year"
  end

  test "wage trailing garbage rejected", %{conn: conn} do
    conn = post(auth(conn), ~p"/api/v1/calculate-payslip", %{"wage" => "5000abc"})
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
    assert body =~ "BT"
    assert body =~ "Tj"
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

  test "POST bulk over 500 employees → 400", %{conn: conn} do
    employees = Enum.map(1..501, fn i -> %{"name" => "E#{i}", "wage" => 5000} end)

    conn = post(auth(conn), ~p"/api/v1/calculate-payslip/bulk", %{"employees" => employees})
    assert json_response(conn, 400)["error"]["message"] =~ "500"
  end

  test "POST bulk accepts string wage for valid row", %{conn: conn} do
    conn =
      post(auth(conn), ~p"/api/v1/calculate-payslip/bulk", %{
        "employees" => [%{"name" => "Ali", "wage" => "5000"}]
      })

    body = json_response(conn, 200)
    ali = List.first(body["data"]["results"])
    assert ali["ok"] == true
  end

  test "POST bulk forwards employee statutory profiles", %{conn: conn} do
    body =
      post(auth(conn), ~p"/api/v1/calculate-payslip/bulk", %{
        "employees" => [
          %{"name" => "Foreign", "wage" => 21_250, "citizenship" => "non_malaysian"},
          %{"name" => "Older", "wage" => 21_250, "age_60_plus" => true}
        ],
        "include_hrdf" => false
      })
      |> json_response(200)

    [foreign, older] = body["data"]["results"]
    assert foreign["data"]["employee_contributions"]["epf"] == 425.0
    assert older["data"]["employee_contributions"]["epf"] == 0.0
  end

  test "POST calculate-payslip accepts numeric string wage", %{conn: conn} do
    conn = post(auth(conn), ~p"/api/v1/calculate-payslip", %{"wage" => "5000"})
    body = json_response(conn, 200)
    assert body["success"] == true
    assert body["data"]["net_pay"] == 4305.35
  end
end
