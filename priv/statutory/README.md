# Statutory source tables

Transcribed from primary sources. Each CSV is the authority for its scheme —
the Elixir code performs lookups, it does not carry rates.

| Directory | Source | Edition |
|---|---|---|
| `epf_third_schedule_2025-10/` | KWSP Third Schedule, EPF Act 1991 | Effective 1 October 2025 |
| `socso_act4_2026-06/` | PERKESO Act 4 contribution table incl. SKBBK | Effective 1 June 2026 |

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

## Adding an edition

Rates are currently keyed by year, which cannot express a mid-year change
(SKBBK began 1 June 2026). Adding a superseded edition needs the effective-date
work tracked as PAY-009 in `docs/audits/current-backlog.md`.
