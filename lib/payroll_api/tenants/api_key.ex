defmodule PayrollApi.Tenants.ApiKey do
  use Ecto.Schema

  import Ecto.Changeset

  schema "api_keys" do
    field(:name, :string)
    field(:token_hash, :binary)
    field(:token_prefix, :string)
    field(:scopes, {:array, :string}, default: [])
    field(:expires_at, :utc_datetime)
    field(:revoked_at, :utc_datetime)
    belongs_to(:tenant, PayrollApi.Tenants.Tenant)
    timestamps(type: :utc_datetime)
  end

  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:name, :token_hash, :token_prefix, :scopes, :expires_at, :tenant_id])
    |> validate_required([:name, :token_hash, :token_prefix, :tenant_id])
    |> validate_length(:name, min: 1, max: 160)
  end
end
