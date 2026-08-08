# Project Audit Tracker

This directory records codebase audits and remediation progress.

## Structure

- `snapshots/`: immutable, dated audit reports. Never rewrite old findings after fixes.
- `current-backlog.md`: living list of unresolved and recently verified findings.

## Workflow For Future Agents

1. Read the latest snapshot and `current-backlog.md` before changing code.
2. Reference finding IDs in changes, notes, and commits where useful.
3. Update a backlog item only after checking its current implementation and tests.
4. Record exact verification commands and results. Do not mark an item `verified` from code inspection alone.
5. Use `fixed` when code changed but full verification remains pending.
6. Use `verified` only when relevant focused tests and `mix precommit` pass.
7. Never delete completed findings. Move them to the completed section during backlog cleanup.
8. Create a new dated snapshot for each broad re-audit. Do not edit previous snapshots to make current code look better.
9. Recalculate completion estimates from evidence, not closed issue count.

## Status Values

| Status | Meaning |
|---|---|
| `open` | Confirmed issue, no active fix |
| `in_progress` | Work started |
| `blocked` | Cannot proceed until named dependency or decision is resolved |
| `fixed` | Code changed, final verification pending |
| `verified` | Fix confirmed by current tests and project gate |
| `wont_fix` | Deliberate decision recorded with reason |

## Finding ID Prefixes

| Prefix | Area |
|---|---|
| `PAY` | Payroll and statutory correctness |
| `SEC` | Authentication, authorization, tenancy, and data security |
| `DATA` | Persistence and data integrity |
| `API` | API contract and input handling |
| `UI` | LiveView and user experience |
| `ARCH` | Structure and maintainability |
| `OPS` | Deployment, observability, and operations |
| `TEST` | Test coverage and verification |
| `DOC` | Documentation accuracy |

## Required Backlog Evidence

Each updated item should contain:

- affected files and line references;
- root cause, not only symptom;
- minimal accepted fix;
- focused verification command;
- result and date;
- remaining limitations.

## Current Baseline

- Latest audit: [`snapshots/2026-08-08-initial-project-audit.md`](snapshots/2026-08-08-initial-project-audit.md)
- Current backlog: [`current-backlog.md`](current-backlog.md)
- Production payroll API completion estimate: **45%**
- Full payroll system completion estimate: **below 25%**
- Release status: **blocked for real payroll use**
