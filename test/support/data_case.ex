defmodule PayrollApi.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias PayrollApi.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import PayrollApi.DataCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(PayrollApi.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(PayrollApi.Repo, {:shared, self()})
    end

    :ok
  end
end
