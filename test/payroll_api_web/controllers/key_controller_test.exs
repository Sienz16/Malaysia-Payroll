defmodule PayrollApiWeb.KeyControllerTest do
  use PayrollApiWeb.ConnCase, async: false

  @master_key "test-master-key-123"

  defp auth(conn, key), do: put_req_header(conn, "authorization", "Bearer #{key}")

  setup do
    # Register a plain (non-master) key for the authorization tests.
    PayrollApi.Keys.add("test-plain-key-456")
    :ok
  end

  test "GET /api/v1/keys without auth → 401", %{conn: conn} do
    conn = get(conn, ~p"/api/v1/keys")
    assert json_response(conn, 401)["error"]["message"] =~ "API key"
  end

  test "GET /api/v1/keys with plain key → 403", %{conn: conn} do
    conn = get(auth(conn, "test-plain-key-456"), ~p"/api/v1/keys")
    assert json_response(conn, 403)["error"]["message"] =~ "admin key"
  end

  test "GET /api/v1/keys with master key → 200 with key list", %{conn: conn} do
    conn = get(auth(conn, @master_key), ~p"/api/v1/keys")
    body = json_response(conn, 200)
    assert body["success"] == true
    assert is_list(body["data"])
  end

  test "POST /api/v1/keys with plain key → 403", %{conn: conn} do
    conn = post(auth(conn, "test-plain-key-456"), ~p"/api/v1/keys", %{"key" => "new-key-789"})
    assert json_response(conn, 403)["error"]["message"] =~ "admin key"
  end

  test "POST /api/v1/keys with master key adds a key", %{conn: conn} do
    conn = post(auth(conn, @master_key), ~p"/api/v1/keys", %{"key" => "new-key-789"})
    body = json_response(conn, 200)
    assert body["success"] == true
    assert PayrollApi.Keys.valid?("new-key-789")
  end

  test "DELETE /api/v1/keys/:key with plain key → 403", %{conn: conn} do
    conn = delete(auth(conn, "test-plain-key-456"), ~p"/api/v1/keys/test-plain-key-456")
    assert json_response(conn, 403)["error"]["message"] =~ "admin key"
  end

  test "DELETE /api/v1/keys/:key with master key removes a plain key", %{conn: conn} do
    conn = delete(auth(conn, @master_key), ~p"/api/v1/keys/test-plain-key-456")
    assert json_response(conn, 200)["success"] == true
    refute PayrollApi.Keys.valid?("test-plain-key-456")
  end

  test "DELETE /api/v1/keys/:key cannot remove the master key", %{conn: conn} do
    conn = delete(auth(conn, @master_key), ~p"/api/v1/keys/#{@master_key}")
    assert json_response(conn, 200)["success"] == false
    assert PayrollApi.Keys.valid?(@master_key)
  end
end
