# UI Modernization Brief

Status: first implementation complete; verification and polish pending
Priority: high
Product: Malaysia Payroll Statutory API

## Goal

Turn current calculator-first UI into a credible API product landing experience that attracts developers and payroll teams, explains product value quickly, enables a safe first calculation, and leads users to API documentation and integration.

## Target Experience

1. Visitor understands product value within one screen: Malaysia payroll statutory calculations through a developer-friendly API.
2. Visitor sees a working, safe demo without creating an account or exposing real credentials.
3. Developer can copy a valid authenticated API request and inspect JSON output.
4. Payroll buyer sees coverage, limitations, source provenance, and production-readiness status without misleading statutory claims.
5. Experience works on mobile and desktop, supports keyboard navigation, and respects reduced-motion preferences.

## Phoenix-Native Direction

- Keep Phoenix LiveView and existing Tailwind CSS v4 setup.
- Use server-rendered HEEx and LiveView events for calculator/playground behavior.
- Use bundled `assets/js/app.js` only for small browser enhancements; no inline scripts.
- Use existing Phoenix components where they reduce errors; remove unused generated UI rather than adding a component library.
- Do not add daisyUI or another design system dependency.
- Keep each key template element on a stable DOM ID for LiveView tests.
- Begin LiveView templates with `<Layouts.app flash={@flash} ...>` as required by project rules.

## Proposed Information Architecture

### Landing page `/`

- Compact navigation: product, coverage, API docs, calculator, GitHub/contact CTA.
- Hero: clear API promise, one primary CTA, one secondary docs CTA, code snippet or response preview.
- Proof strip: EPF, SOCSO, EIS, HRDF, PCB labels with “coverage” and “validation status” distinctions.
- Interactive calculator card: wage, year, HRDF, citizenship/age profile fields currently supported; clear disclaimer for simplified PCB and EPF schedule limitations.
- Developer section: request/response example, authentication explanation, bulk/PDF links.
- Trust section: source references, version/effective-date display, explicit limitations.
- Final CTA: “Run your first calculation” and “Read API docs”.
- Footer: source links, disclaimer, repository/product links.

### API docs `/api-docs`

- Authenticated endpoint examples with `Authorization: Bearer` header.
- Endpoint cards for rates, single calculation, bulk calculation, PDF, health, and OpenAPI.
- Request editor/playground only with non-sensitive sample values.
- Response preview with JSON formatting and copy action.
- Supported year and known limitation callouts.

### Calculator interaction

- Progressive disclosure for employee statutory profile.
- Explicit `spouse_eligible`, not implied spouse relief from marital status.
- Clear result groups: employee deductions, employer cost, tax details, rate/source version.
- Loading, validation, empty, and error states.
- No claim that simplified outputs are production statutory filing results.

## Visual Research Direction

Research before implementation should compare current August 2026 API-product patterns:

- editorial developer-tool landing pages with strong typography and restrained motion;
- dark technical hero paired with warm paper/light calculator surface;
- monospace code accents against a humanist sans-serif UI font stack;
- product proof through live output, source provenance, and transparent limitations instead of inflated metrics;
- generous whitespace, high-contrast calls to action, subtle borders, and purposeful hover/focus states;
- responsive layouts that preserve code readability and calculator usability on narrow screens;
- reduced-motion fallback and visible keyboard focus states.

Avoid generic SaaS gradients, fake customer logos, invented usage numbers, excessive glassmorphism, decorative animation, and claims unsupported by statutory validation.

## Implementation Order

1. Inspect current layout, CSS tokens, routes, and available assets. **Complete.**
2. Define visual tokens: color, type scale, spacing, radii, borders, shadows, motion. **Complete.**
3. Refactor shared root/app layout and navigation. **Complete.**
4. Build landing page sections with stable IDs. **Complete.**
5. Move calculator into focused interactive surface and expose supported profile inputs. **Complete for current wage/HRDF flow.**
6. Refactor API docs into accurate developer onboarding page. **Complete for documented current endpoints.**
7. Add responsive, accessibility, and LiveView interaction tests. **Pending.**
8. Run `mix precommit`, manual desktop/mobile review, and update audit backlog. **Automated gate complete; manual review pending.**

## Acceptance Criteria

- Landing page communicates product purpose without scrolling.
- Primary CTA reaches working calculator.
- Secondary CTA reaches accurate API docs.
- Every displayed endpoint/auth claim matches router and OpenAPI.
- No unsupported “fully compliant” or “production-ready” payroll claim.
- No inline JavaScript.
- Stable IDs cover navigation, hero CTAs, calculator form, result panel, docs sections, and code example.
- Mobile layout has no horizontal overflow.
- Keyboard navigation and focus states work.
- `mix test` and `mix precommit` pass.
- Screenshot/manual review confirms polished desktop and mobile output.
