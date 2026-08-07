defmodule PayrollApiWeb.PageController do
  use PayrollApiWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: "/")
  end

  def docs(conn, _params) do
    render(conn, :docs)
  end
end
