defmodule PayrollApiWeb.PayrollLive do
  use PayrollApiWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <section class="hero">
        <div class="shell hero-grid">
          <div class="animate-in">
            <div class="eyebrow">
              <span class="eyebrow-dot"></span> Statutory payroll infrastructure
            </div>
            <h1>Payroll math,<br /><em>without the maze.</em></h1>
            <p class="hero-copy">
              A developer-first API for Malaysia's statutory payroll calculations. Run a clean payslip breakdown, inspect the rules, and ship your integration faster.
            </p>
            <div class="hero-actions">
              <.link
                id="hero-calculator-cta"
                navigate={~p"/calculator"}
                class="button button-mint button-small"
              >Run a calculation <span aria-hidden="true">↗</span></.link>
              <.link id="hero-docs-cta" navigate={~p"/api-docs"} class="button button-ghost">Read the API docs</.link>
            </div>
            <div class="hero-meta">
              <span><b>105</b> automated tests</span>
              <span><b>2025–26</b> rate snapshots</span>
              <span><b>JSON</b> + PDF output</span>
            </div>
          </div>

          <div
            id="hero-code-preview"
            class="terminal animate-in delay-1"
            aria-label="API response preview"
          >
            <div class="terminal-bar">
              <span class="terminal-dot"></span><span class="terminal-dot"></span><span class="terminal-dot"></span><span class="terminal-label">POST /api/v1/calculate-payslip</span>
            </div>
            <div class="terminal-body">
              <div>
                <span class="code-muted">$ </span><span class="code-key">curl</span>
                -X POST /api/v1/calculate-payslip
              </div>
              <div class="code-muted">-H "Authorization: Bearer $KEY"</div>
              <div class="code-muted">-d '&#123;&quot;wage&quot;: 5000&#125;'</div>
              <div class="terminal-result">
                <div><span class="code-muted">&#123;</span></div>
                <div>
                  &nbsp; <span class="code-key">"net_pay"</span>: <span class="code-number">4305.35</span>,
                </div>
                <div>
                  &nbsp; <span class="code-key">"employee_contributions"</span>:
                  <span class="code-muted">&#123;</span>
                </div>
                <div>
                  &nbsp;&nbsp;&nbsp; <span class="code-key">"epf"</span>: <span class="code-number">550.00</span>,
                </div>
                <div>
                  &nbsp;&nbsp;&nbsp; <span class="code-key">"socso"</span>: <span class="code-number">24.75</span>,
                </div>
                <div>
                  &nbsp;&nbsp;&nbsp; <span class="code-key">"pcb"</span>:
                  <span class="code-number">110.00</span>
                </div>
                <div>&nbsp; <span class="code-muted">&#125;</span></div>
                <div><span class="code-muted">&#125;</span></div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section id="coverage" class="section section-paper-deep">
        <div class="shell">
          <div class="section-heading">
            <div class="eyebrow"><span class="eyebrow-dot"></span> One endpoint, clear output</div>
            <h2>Every deduction has a place.</h2>
            <p>
              See employee deductions and employer cost together, with rate versioning attached to every calculation.
            </p>
          </div>
          <div class="coverage-grid">
            <div class="coverage-card">
              <strong>EPF</strong><p>Employee and employer contribution paths.</p><small>KWSP</small>
            </div>
            <div class="coverage-card">
              <strong>SOCSO</strong><p>Category 1 and Category 2 bracket tables.</p><small>PERKESO</small>
            </div>
            <div class="coverage-card">
              <strong>EIS</strong><p>Employment insurance contribution bands.</p><small>SIP</small>
            </div>
            <div class="coverage-card">
              <strong>HRDF</strong><p>Standard, reduced, and exempt modes.</p><small>HRD Corp</small>
            </div>
            <div class="coverage-card">
              <strong>PCB</strong><p>YA snapshot with transparent Method 1 limits.</p><small>LHDN · limited</small>
            </div>
          </div>
        </div>
      </section>

      <section id="developer" class="section section-dark">
        <div class="shell developer-grid">
          <div>
            <div class="eyebrow">
              <span class="eyebrow-dot"></span> Built for the next integration
            </div>
            <h2>Less payroll plumbing. More product.</h2>
            <p>
              Bring statutory calculations into HRIS, fintech, accounting, and payroll products through one predictable JSON API.
            </p>
            <div class="developer-links">
              <.link navigate={~p"/api-docs"} class="button button-mint button-small">Explore endpoints ↗</.link><a
                href="/#coverage"
                class="button button-small button-outline-dark"
              >See coverage</a>
            </div>
          </div>
          <div class="code-window">
            <div class="terminal-bar">
              <span class="terminal-dot"></span><span class="terminal-dot"></span><span class="terminal-dot"></span><span class="terminal-label">response.json</span>
            </div><div class="code-preview-lines">
              <div>success: true</div><div>net_pay: 4305.35</div><div>rates_version: 2026.2</div><div>
                employee_contributions: ...
              </div>
            </div>
          </div>
        </div>
      </section>

      <footer class="footer">
        <div class="shell footer-inner">
          <span>Malaysia Payroll API · statutory tooling in progress</span><div class="footer-links">
            <.link navigate={~p"/api-docs"}>API docs</.link><a href="https://github.com/Sienz16/Malaysia-Payroll">GitHub</a>
          </div>
        </div>
      </footer>
    </Layouts.app>
    """
  end
end
