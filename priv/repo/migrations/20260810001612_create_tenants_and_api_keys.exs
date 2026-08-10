defmodule PayrollApi.Repo.Migrations.CreateTenantsAndApiKeys do
  use Ecto.Migration

  def change do
    create table(:tenants) do
      add :name, :string, null: false
      timestamps(type: :utc_datetime)
    end

    create table(:api_keys) do
      add :tenant_id, references(:tenants, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :token_hash, :binary, null: false
      add :token_prefix, :string, null: false
      add :scopes, {:array, :string}, null: false, default: []
      add :expires_at, :utc_datetime
      add :revoked_at, :utc_datetime
      timestamps(type: :utc_datetime)
    end

    create index(:api_keys, [:tenant_id])
    create unique_index(:api_keys, [:token_hash])
  end
end
