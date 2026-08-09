defmodule PayrollApiWeb.CalculatorLive do
  use PayrollApiWeb, :live_view

  alias PayrollApi.Statutory.Payslip

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       form: to_form(%{"wage" => "5000", "include_hrdf" => "true"}),
       include_hrdf: true,
       result: nil,
       error: nil
     )}
  end

  @impl true
  def handle_event("calculate", %{"wage" => wage} = params, socket) do
    include_hrdf = Map.get(params, "include_hrdf", "false") == "true"

    case Float.parse(wage) do
      {wage, ""} ->
        case Payslip.calculate(%{wage: wage, include_hrdf: include_hrdf}) do
          {:ok, result} ->
            form = to_form(%{"wage" => wage, "include_hrdf" => to_string(include_hrdf)})

            {:noreply,
             assign(socket, result: result, error: nil, include_hrdf: include_hrdf, form: form)}

          {:error, reason} ->
            {:noreply, assign(socket, error: humanize(reason), result: nil)}
        end

      _ ->
        {:noreply, assign(socket, error: "Enter a valid monthly wage.", result: nil)}
    end
  end

  defp humanize(:wage_required), do: "Enter a monthly wage."
  defp humanize(:invalid_wage), do: "Wage must be a number."
  defp humanize(:negative_wage), do: "Wage cannot be negative."
  defp humanize(:zero_wage), do: "Wage must be greater than zero."
  defp humanize(other), do: "Calculation error: #{inspect(other)}"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <section class="section calculator-page">
        <div class="shell calculator-page-grid">
          <div class="calculator-intro animate-in">
            <.link navigate={~p"/"} class="eyebrow"><span class="eyebrow-dot"></span> Back to overview</.link>
            <h1>Payroll<br /><em>playground.</em></h1>
            <p>
              Test a sample monthly wage and inspect the complete statutory breakdown returned by our calculation engine.
            </p>
            <div class="playground-notes">
              <div>
                <span>01</span><p>Enter gross monthly wage</p>
              </div>
              <div>
                <span>02</span><p>Choose levy behavior</p>
              </div>
              <div>
                <span>03</span><p>Inspect estimated net pay</p>
              </div>
            </div>
            <div class="disclaimer">
              Demo output only. EPF wage-range schedules and full LHDN MTD workflows remain under validation. Never use this playground for real payroll filing.
            </div>
          </div>

          <div id="calculator-playground" class="calc-card calculator-card animate-in delay-1">
            <div class="playground-header">
              <div><span class="eyebrow-dot"></span><span>LIVE REQUEST</span></div><span class="result-pill">POST /calculate-payslip</span>
            </div>
            <.form for={@form} id="payroll-calculator-form" phx-submit="calculate">
              <label for="gross-wage" class="calc-label">Gross monthly wage · RM</label>
              <.input
                field={@form[:wage]}
                id="gross-wage"
                type="number"
                min="0"
                step="0.01"
                placeholder="5000.00"
              />
              <div class="calc-checkbox">
                <.input
                  field={@form[:include_hrdf]}
                  id="include-hrdf"
                  type="checkbox"
                  checked={@include_hrdf}
                  label="Include HRDF levy (standard 1%)"
                />
              </div>
              <button
                id="calculate-payslip"
                type="submit"
                class="button button-mint calc-submit"
                phx-disable-with="Calculating..."
              >Run calculation <span aria-hidden="true">↗</span></button>
            </.form>

            <%= if @error do %>
              <div id="calculator-error" class="disclaimer" role="alert">{@error}</div>
            <% end %>
            <%= if @result do %>
              <div id="calculation-result" class="result-panel" role="status" aria-live="polite">
                <div class="result-top">
                  <h2>Estimated result</h2><span class="result-pill">rates v{@result.rates_version}</span>
                </div>
                <div class="result-stats">
                  <div class="result-stat">
                    <span>Gross wage</span><strong>RM {fmt(@result.wage)}</strong>
                  </div>
                  <div class="result-stat">
                    <span>Employee deductions</span><strong>-RM {fmt(
                      @result.employee_contributions.total
                    )}</strong>
                  </div>
                  <div class="result-stat net">
                    <span>Estimated net pay</span><strong>RM {fmt(@result.net_pay)}</strong>
                  </div>
                </div>
                <div class="result-details">
                  <div><span>EPF</span><b>RM {fmt(@result.employee_contributions.epf)}</b></div>
                  <div><span>SOCSO</span><b>RM {fmt(@result.employee_contributions.socso)}</b></div>
                  <div><span>EIS</span><b>RM {fmt(@result.employee_contributions.eis)}</b></div>
                  <div><span>PCB</span><b>RM {fmt(@result.employee_contributions.pcb)}</b></div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end

  defp fmt(v) when is_number(v), do: :erlang.float_to_binary(v / 1, decimals: 2)
  defp fmt(v), do: to_string(v)
end
