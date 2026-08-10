defmodule PayrollApi.TenantsTest do
  use PayrollApi.DataCase, async: true

  alias PayrollApi.Tenants

  test "creates tenant-owned API key without storing its secret" do
    {:ok, tenant} = Tenants.create_tenant(%{name: "Acme Payroll"})

    {:ok, %{token: token, api_key: api_key}} = Tenants.create_api_key(tenant, %{name: "CI"})

    assert "pay_" <> _ = token
    assert api_key.tenant_id == tenant.id
    assert api_key.token_hash != token
    refute Map.has_key?(api_key, :token)
  end

  test "authenticates active token and rejects revoked token" do
    {:ok, tenant} = Tenants.create_tenant(%{name: "Acme Payroll"})
    {:ok, %{token: token, api_key: api_key}} = Tenants.create_api_key(tenant, %{name: "CI"})

    assert {:ok, authenticated_key} = Tenants.authenticate_api_key(token)
    assert authenticated_key.id == api_key.id

    assert {:ok, _api_key} = Tenants.revoke_api_key(api_key)
    assert :error = Tenants.authenticate_api_key(token)
  end
end
