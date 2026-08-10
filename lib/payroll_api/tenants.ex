defmodule PayrollApi.Tenants do
  alias PayrollApi.Repo
  alias PayrollApi.Tenants.ApiKey
  alias PayrollApi.Tenants.Tenant

  import Ecto.Query

  def create_tenant(attrs) do
    %Tenant{}
    |> Tenant.changeset(attrs)
    |> Repo.insert()
  end

  def create_api_key(%Tenant{id: tenant_id}, attrs) do
    token = "pay_" <> Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)

    attrs =
      attrs
      |> Map.put(:tenant_id, tenant_id)
      |> Map.put(:token_hash, :crypto.hash(:sha256, token))
      |> Map.put(:token_prefix, String.slice(token, 0, 12))

    with {:ok, api_key} <- %ApiKey{} |> ApiKey.changeset(attrs) |> Repo.insert() do
      {:ok, %{token: token, api_key: api_key}}
    end
  end

  def authenticate_api_key(token) when is_binary(token) do
    token_hash = :crypto.hash(:sha256, token)

    api_key =
      from(key in ApiKey,
        where: key.token_hash == ^token_hash and is_nil(key.revoked_at),
        where: is_nil(key.expires_at) or key.expires_at > ^DateTime.utc_now(),
        preload: [:tenant]
      )
      |> Repo.one()

    if api_key, do: {:ok, api_key}, else: :error
  end

  def authenticate_api_key(_), do: :error

  def revoke_api_key(%ApiKey{} = api_key) do
    api_key
    |> Ecto.Changeset.change(revoked_at: DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.update()
  end
end
