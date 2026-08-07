defmodule PayrollApiWeb.PayrollLive do
  use PayrollApiWeb, :live_view

  alias PayrollApi.Statutory.Payslip

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(wage: "5000", include_hrdf: true, result: nil, error: nil)}
  end

  @impl true
  def handle_event("calculate", %{"wage" => wage, "include_hrdf" => include_hrdf}, socket) do
    hrdf = include_hrdf == "true"

    case Float.parse(wage) do
      {w, _} ->
        case Payslip.calculate(%{wage: w, include_hrdf: hrdf}) do
          {:ok, result} ->
            {:noreply, socket |> assign(wage: wage, include_hrdf: hrdf, result: result, error: nil)}

          {:error, reason} ->
            {:noreply, socket |> assign(error: humanize(reason), result: nil)}
        end

      :error ->
        {:noreply, socket |> assign(error: "Please enter a valid wage", result: nil)}
    end
  end

  defp humanize(:wage_required), do: "Wage is required"
  defp humanize(:invalid_wage), do: "Wage must be a number"
  defp humanize(:negative_wage), do: "Wage cannot be negative"
  defp humanize(other), do: "Error: #{inspect(other)}"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-50 py-10 px-4">
      <div class="max-w-3xl mx-auto">
        <div class="text-center mb-8">
          <p class="text-sm font-semibold text-emerald-600 uppercase tracking-wide">Malaysia Statutory Payroll API</p>
          <h1 class="text-3xl font-bold text-slate-900 mt-1">Payslip Calculator</h1>
          <p class="text-slate-500 mt-2">EPF · SOCSO · EIS · HRDF — 2026 rates</p>
        </div>

        <form phx-submit="calculate" class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
          <label class="block text-sm font-medium text-slate-700 mb-1">Gross monthly wage (RM)</label>
          <div class="flex gap-3 items-center">
            <input
              type="number"
              name="wage"
              value={@wage}
              min="0"
              step="0.01"
              placeholder="e.g. 5000"
              class="flex-1 rounded-lg border border-slate-300 px-4 py-2.5 text-lg focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
            <button type="submit" class="bg-emerald-600 hover:bg-emerald-700 text-white font-semibold px-6 py-2.5 rounded-lg transition">
              Calculate
            </button>
          </div>

          <div class="mt-4 flex items-center gap-2">
            <input type="checkbox" name="include_hrdf" value="true" checked={@include_hrdf} class="h-4 w-4 text-emerald-600 rounded" />
            <label class="text-sm text-slate-600">Include HRDF levy (1% employer)</label>
          </div>

          <%= if @error do %>
            <div class="mt-4 bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg px-4 py-3">
              <%= @error %>
            </div>
          <% end %>
        </form>

        <%= if @result do %>
          <div class="mt-6 bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
            <div class="flex justify-between items-center border-b border-slate-200 pb-4">
              <h2 class="text-lg font-semibold text-slate-900">Breakdown</h2>
              <span class="text-xs bg-emerald-50 text-emerald-700 font-medium px-2.5 py-1 rounded-full">rates v<%= @result.rates_version %></span>
            </div>

            <div class="grid grid-cols-3 gap-4 py-4">
              <div>
                <p class="text-xs text-slate-500">Gross wage</p>
                <p class="text-xl font-bold text-slate-900">RM <%= fmt(@result.wage) %></p>
              </div>
              <div>
                <p class="text-xs text-slate-500">Employee total</p>
                <p class="text-xl font-bold text-rose-600">-RM <%= fmt(@result.employee_contributions.total) %></p>
              </div>
              <div>
                <p class="text-xs text-slate-500">Net pay</p>
                <p class="text-xl font-bold text-emerald-600">RM <%= fmt(@result.net_pay) %></p>
              </div>
            </div>

            <div class="grid md:grid-cols-2 gap-6">
              <div>
                <h3 class="text-sm font-semibold text-slate-700 mb-2">Employee contributions</h3>
                <table class="w-full text-sm">
                  <tbody>
                    <tr class="border-b border-slate-100"><td class="py-2 text-slate-600">EPF (11%)</td><td class="py-2 text-right font-medium">RM <%= fmt(@result.employee_contributions.epf) %></td></tr>
                    <tr class="border-b border-slate-100"><td class="py-2 text-slate-600">SOCSO (0.5%)</td><td class="py-2 text-right font-medium">RM <%= fmt(@result.employee_contributions.socso) %></td></tr>
                    <tr class="border-b border-slate-100"><td class="py-2 text-slate-600">EIS (0.2%)</td><td class="py-2 text-right font-medium">RM <%= fmt(@result.employee_contributions.eis) %></td></tr>
                    <tr class="border-b border-slate-100"><td class="py-2 text-slate-600">PCB (income tax)</td><td class="py-2 text-right font-medium">RM <%= fmt(@result.employee_contributions.pcb) %></td></tr>
                    <tr><td class="py-2 text-slate-600">HRDF</td><td class="py-2 text-right font-medium">RM <%= fmt(@result.employee_contributions.hrdf) %></td></tr>
                  </tbody>
                </table>
              </div>
              <div>
                <h3 class="text-sm font-semibold text-slate-700 mb-2">Employer contributions</h3>
                <table class="w-full text-sm">
                  <tbody>
                    <tr class="border-b border-slate-100"><td class="py-2 text-slate-600">EPF</td><td class="py-2 text-right font-medium">RM <%= fmt(@result.employer_contributions.epf) %></td></tr>
                    <tr class="border-b border-slate-100"><td class="py-2 text-slate-600">SOCSO</td><td class="py-2 text-right font-medium">RM <%= fmt(@result.employer_contributions.socso) %></td></tr>
                    <tr class="border-b border-slate-100"><td class="py-2 text-slate-600">EIS</td><td class="py-2 text-right font-medium">RM <%= fmt(@result.employer_contributions.eis) %></td></tr>
                    <tr><td class="py-2 text-slate-600">HRDF</td><td class="py-2 text-right font-medium">RM <%= fmt(@result.employer_contributions.hrdf) %></td></tr>
                  </tbody>
                </table>
                <div class="mt-3 pt-3 border-t border-slate-200 flex justify-between text-sm font-semibold">
                  <span class="text-slate-700">Total employer cost</span>
                  <span class="text-emerald-700">RM <%= fmt(@result.total_statutory_cost) %></span>
                </div>
              </div>
            </div>

            <div class="mt-6 pt-4 border-t border-slate-200">
              <h3 class="text-sm font-semibold text-slate-700 mb-2">PCB tax details (annual)</h3>
              <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
                <div class="bg-slate-50 rounded-lg p-3">
                  <p class="text-xs text-slate-500">Annual gross</p>
                  <p class="font-semibold text-slate-800">RM <%= fmt(@result.tax_details.annual_gross) %></p>
                </div>
                <div class="bg-slate-50 rounded-lg p-3">
                  <p class="text-xs text-slate-500">Reliefs</p>
                  <p class="font-semibold text-slate-800">-RM <%= fmt(@result.tax_details.annual_reliefs) %></p>
                </div>
                <div class="bg-slate-50 rounded-lg p-3">
                  <p class="text-xs text-slate-500">Chargeable</p>
                  <p class="font-semibold text-slate-800">RM <%= fmt(@result.tax_details.annual_chargeable) %></p>
                </div>
                <div class="bg-slate-50 rounded-lg p-3">
                  <p class="text-xs text-slate-500">Annual tax</p>
                  <p class="font-semibold text-emerald-700">RM <%= fmt(@result.tax_details.annual_tax) %></p>
                </div>
              </div>
            </div>
          </div>
        <% end %>

        <div class="mt-8 text-center">
          <a href="/api-docs" class="text-emerald-600 hover:text-emerald-700 text-sm font-medium">View API docs →</a>
        </div>
      </div>
    </div>
    """
  end

  defp fmt(v) when is_number(v), do: :erlang.float_to_binary(v / 1, decimals: 2)
  defp fmt(v), do: to_string(v)
end
