defmodule PayrollApiWeb.PageController do
  use PayrollApiWeb, :controller

  def docs(conn, _params) do
    render(conn, :docs)
  end
end
