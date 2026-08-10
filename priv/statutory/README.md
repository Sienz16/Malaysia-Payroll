# Statutory source tables

Transcribed from primary sources. Each CSV is the authority for its scheme —
the Elixir code performs lookups, it does not carry rates.

| Directory | Source | Edition |
|---|---|---|
| `epf_third_schedule_2025-10/` | KWSP Third Schedule, EPF Act 1991 | Effective 1 October 2025 |
| `socso_act4_2026-06/` | PERKESO Act 4 contribution table incl. SKBBK | Effective 1 June 2026 |
| `eis_act800_2024-11/` | PERKESO Act 800 (EIS) Second Schedule | `151124-Rate Contribution ACT 800.pdf` |

## Why tables and not percentages

Both schemes publish fixed contribution amounts per wage band. Applying the
headline percentage instead is wrong for any wage that is not exactly on a band
boundary. A RM2,985 wage contributes the RM2,980.01–RM3,000.00 band amounts
(employer RM390.00, employee RM330.00), not 13%/11% of RM2,985.

The EPF employer share also steps *down* above RM5,000 (13% → 12%), so
contributions are not monotonic in wage. That is the schedule's behaviour, not
a transcription error, and `test/statutory/schedule_test.exs` pins it.

## Re-transcribing

Neither kwsp.gov.my nor perkeso.gov.my permits scripted download; both sit
behind a WAF that rejects non-browser requests. Fetch the PDF through a browser,
then:

```bash
pdftotext -layout third_schedule.pdf third_schedule.txt
python3 priv/statutory/tools/extract_epf.py third_schedule.txt priv/statutory/epf_third_schedule_2025-10
```

```bash
pdftotext -layout perkeso_rates.pdf perkeso_rates.txt
python3 priv/statutory/tools/extract_socso.py perkeso_rates.txt priv/statutory/socso_act4_2026-06/rates.csv
```

Both scripts validate before writing and exit non-zero rather than emit a table
they cannot verify. They check that printed components sum to printed totals,
and that bands tile their range with no gap, overlap, or duplicate.

The text layers are layout-scrambled in places — row numbers drift onto
neighbouring lines and interleave into band descriptions — so neither script
keys off line position or row numbering. Do not "simplify" them to do so.

The Act 800 (EIS) source PDF has no text layer at all (a scanned page), so
`extract_eis.py` cannot regex-parse it — the 65 rows are hardcoded in the
script as read directly off the rendered page image. It still validates the
same way (component sums, band tiling) before writing:

```bash
pdftoppm -png -r 200 act800_rates.pdf page   # then read page-1.png row by row
python3 priv/statutory/tools/extract_eis.py priv/statutory/eis_act800_2024-11/rates.csv
```

## Adding an edition

Rates are keyed by year, with a `year`/`month` period check on top
(`Rates.rates/2`) that refuses periods the loaded tables don't cover instead
of silently computing them wrong — see PAY-009 in
`docs/audits/current-backlog.md`. That refusal is a stopgap, not a real
superseded-edition system: it still can't *serve* a correct pre-June-2026
SOCSO or pre-October-2025 EPF figure, only decline to guess at one. Adding a
superseded edition for real needs effective-date-keyed snapshots, not just
year keys.
