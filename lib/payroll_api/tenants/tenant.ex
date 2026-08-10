defmodule PayrollApi.Tenants.Tenant do
  use Ecto.Schema

  import Ecto.Changeset

  schema "tenants" do
    field(:name, :string)
    has_many(:api_keys, PayrollApi.Tenants.ApiKey)
    timestamps(type: :utc_datetime)
  end

  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 160)
  end
end
