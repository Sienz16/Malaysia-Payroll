defmodule PayrollApiWeb.CalculatorLiveTest do
  use PayrollApiWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "calculator renders the form with stable IDs", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/calculator")

    assert has_element?(view, "#payroll-calculator-form")
    assert has_element?(view, "#gross-wage")
    assert has_element?(view, "#include-hrdf")
    assert has_element?(view, "#calculate-payslip")
  end

  test "submitting a valid wage renders the result panel", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/calculator")

    view
    |> form("#payroll-calculator-form", %{"wage" => "5000", "include_hrdf" => "true"})
    |> render_submit()

    assert has_element?(view, "#calculation-result")
    assert view |> element("#calculation-result") |> render() =~ "4305.35"
  end

  test "submitting an invalid wage renders an error, not a crash", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/calculator")

    view
    |> form("#payroll-calculator-form", %{"wage" => "abc", "include_hrdf" => "false"})
    |> render_submit()

    assert has_element?(view, "#calculator-error")
    refute has_element?(view, "#calculation-result")
  end

  test "omitting the HRDF checkbox is treated as false without crashing", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/calculator")

    # Omit include_hrdf entirely: the form must not crash and must still
    # render a result (UI-001: omitted checkbox normalized to false).
    view
    |> form("#payroll-calculator-form", %{"wage" => "5000"})
    |> render_submit()

    assert has_element?(view, "#calculation-result")
    assert view |> element("#calculation-result") |> render() =~ "4305.35"
    refute has_element?(view, "#calculator-error")
  end

  test "zero wage shows a friendly error", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/calculator")

    view
    |> form("#payroll-calculator-form", %{"wage" => "0", "include_hrdf" => "false"})
    |> render_submit()

    assert has_element?(view, "#calculator-error")
    assert view |> element("#calculator-error") |> render() =~ "greater than zero"
  end

  test "landing page renders key sections and CTAs", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "#hero-calculator-cta")
    assert has_element?(view, "#hero-docs-cta")
    assert has_element?(view, "#hero-code-preview")
    assert has_element?(view, "#coverage")
    assert has_element?(view, "#developer")
  end

  test "docs page lists endpoints and auth", %{conn: conn} do
    conn = get(conn, ~p"/api-docs")
    html = html_response(conn, 200)
    assert html =~ "calculate-payslip"
    assert html =~ "Authorization"
  end
end
