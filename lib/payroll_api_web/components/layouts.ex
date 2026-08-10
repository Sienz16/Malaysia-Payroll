defmodule PayrollApiWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use PayrollApiWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <a href="#main-content" class="sr-only focus:not-sr-only">Skip to content</a>
    <nav id="site-navigation" class="site-nav">
      <div class="shell nav-inner">
        <.link navigate={~p"/"} class="brand-mark" aria-label="Malaysia Payroll API home">
          <span class="brand-glyph" aria-hidden="true">M</span>
          <span>malaysia<span class="brand-accent">/</span>payroll</span>
        </.link>
        <div class="nav-links">
          <.link navigate={~p"/#coverage"} class="nav-link">Coverage</.link>
          <.link navigate={~p"/#developer"} class="nav-link">For developers</.link>
          <.link navigate={~p"/calculator"} class="nav-link">Playground</.link>
          <.link navigate={~p"/api-docs"} class="nav-link">API docs</.link>
        </div>
        <div class="nav-actions">
          <button
            id="theme-toggle"
            type="button"
            class="theme-button"
            aria-label="Switch to dark theme"
            aria-pressed="false"
          >
            <.icon name="hero-sun" class="h-4 w-4" />
          </button>
          <.link navigate={~p"/calculator"} class="button button-small button-dark">Try playground
          <span aria-hidden="true">↗</span></.link>
        </div>
      </div>
    </nav>

    <main id="main-content">
      {render_slot(@inner_block)}
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title="We can't find the internet"
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="Something went wrong!"
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end
end
