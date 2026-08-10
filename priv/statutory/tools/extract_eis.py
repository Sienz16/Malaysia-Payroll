"""Transcribe and validate the PERKESO Act 800 (EIS) Second Schedule rate
table. Source: `151124-Rate Contribution ACT 800.pdf` — a single scanned
page with no text layer, so this cannot regex a text extraction the way
extract_epf.py / extract_socso.py do. Rows below were read directly off the
rendered page image (200dpi, 6 overlapping crops, each row cross-checked).

Validates like the sibling scripts: every row's employer + employee sums to
its printed total, and the bands tile RM0.01-RM6,000.00 with no gap or
overlap, before writing the CSV. Refuses to write on any check failure.
"""
import sys

# (row_no, wage_to or None for the open-ended row, employer, employee, total)
# — all four amounts as printed in the "Employer's/Employee's Contribution"
# and "Total" columns.
ROWS = [
    (1, 30, 0.05, 0.05, 0.10),
    (2, 50, 0.10, 0.10, 0.20),
    (3, 70, 0.15, 0.15, 0.30),
    (4, 100, 0.20, 0.20, 0.40),
    (5, 140, 0.25, 0.25, 0.50),
    (6, 200, 0.35, 0.35, 0.70),
    (7, 300, 0.50, 0.50, 1.00),
    (8, 400, 0.70, 0.70, 1.40),
    (9, 500, 0.90, 0.90, 1.80),
    (10, 600, 1.10, 1.10, 2.20),
    (11, 700, 1.30, 1.30, 2.60),
    (12, 800, 1.50, 1.50, 3.00),
    (13, 900, 1.70, 1.70, 3.40),
    (14, 1000, 1.90, 1.90, 3.80),
    (15, 1100, 2.10, 2.10, 4.20),
    (16, 1200, 2.30, 2.30, 4.60),
    (17, 1300, 2.50, 2.50, 5.00),
    (18, 1400, 2.70, 2.70, 5.40),
    (19, 1500, 2.90, 2.90, 5.80),
    (20, 1600, 3.10, 3.10, 6.20),
    (21, 1700, 3.30, 3.30, 6.60),
    (22, 1800, 3.50, 3.50, 7.00),
    (23, 1900, 3.70, 3.70, 7.40),
    (24, 2000, 3.90, 3.90, 7.80),
    (25, 2100, 4.10, 4.10, 8.20),
    (26, 2200, 4.30, 4.30, 8.60),
    (27, 2300, 4.50, 4.50, 9.00),
    (28, 2400, 4.70, 4.70, 9.40),
    (29, 2500, 4.90, 4.90, 9.80),
    (30, 2600, 5.10, 5.10, 10.20),
    (31, 2700, 5.30, 5.30, 10.60),
    (32, 2800, 5.50, 5.50, 11.00),
    (33, 2900, 5.70, 5.70, 11.40),
    (34, 3000, 5.90, 5.90, 11.80),
    (35, 3100, 6.10, 6.10, 12.20),
    (36, 3200, 6.30, 6.30, 12.60),
    (37, 3300, 6.50, 6.50, 13.00),
    (38, 3400, 6.70, 6.70, 13.40),
    (39, 3500, 6.90, 6.90, 13.80),
    (40, 3600, 7.10, 7.10, 14.20),
    (41, 3700, 7.30, 7.30, 14.60),
    (42, 3800, 7.50, 7.50, 15.00),
    (43, 3900, 7.70, 7.70, 15.40),
    (44, 4000, 7.90, 7.90, 15.80),
    (45, 4100, 8.10, 8.10, 16.20),
    (46, 4200, 8.30, 8.30, 16.60),
    (47, 4300, 8.50, 8.50, 17.00),
    (48, 4400, 8.70, 8.70, 17.40),
    (49, 4500, 8.90, 8.90, 17.80),
    (50, 4600, 9.10, 9.10, 18.20),
    (51, 4700, 9.30, 9.30, 18.60),
    (52, 4800, 9.50, 9.50, 19.00),
    (53, 4900, 9.70, 9.70, 19.40),
    (54, 5000, 9.90, 9.90, 19.80),
    (55, 5100, 10.10, 10.10, 20.20),
    (56, 5200, 10.30, 10.30, 20.60),
    (57, 5300, 10.50, 10.50, 21.00),
    (58, 5400, 10.70, 10.70, 21.40),
    (59, 5500, 10.90, 10.90, 21.80),
    (60, 5600, 11.10, 11.10, 22.20),
    (61, 5700, 11.30, 11.30, 22.60),
    (62, 5800, 11.50, 11.50, 23.00),
    (63, 5900, 11.70, 11.70, 23.40),
    (64, 6000, 11.90, 11.90, 23.80),
    (65, None, 11.90, 11.90, 23.80),
]

EXPECTED_ROWS = 65
FIRST_CEILING = 30.0
LAST_CEILING = 6000.0


def cents(x):
    return int(round(x * 100))


def validate(rows):
    errs = []
    if len(rows) != EXPECTED_ROWS:
        errs.append(f"expected {EXPECTED_ROWS} rows, got {len(rows)}")

    for no, wage_to, er, ee, total in rows:
        if cents(er) + cents(ee) != cents(total):
            errs.append(f"row {no}: {er}+{ee} != {total}")

    ceilings = [wage_to for _, wage_to, *_ in rows if wage_to is not None]
    if ceilings:
        if cents(ceilings[0]) != cents(FIRST_CEILING):
            errs.append(f"bands start at {ceilings[0]}, expected {FIRST_CEILING}")
        if cents(ceilings[-1]) != cents(LAST_CEILING):
            errs.append(f"bands end at {ceilings[-1]}, expected {LAST_CEILING}")
        for prev, cur in zip(ceilings, ceilings[1:]):
            if cur <= prev:
                errs.append(f"band ordering: {prev} -> {cur} is not increasing")
    if rows[-1][1] is not None:
        errs.append("last row must be open-ended (None ceiling)")
    for no, wage_to, *_ in rows[:-1]:
        if wage_to is None:
            errs.append(f"row {no}: only the last row may be open-ended")

    return errs


def main(out_path):
    errs = validate(ROWS)
    print(f"EIS: {len(ROWS)} rows  {'OK' if not errs else 'FAIL'}")
    for e in errs[:10]:
        print(f"   ! {e}")
    if errs:
        return 1

    with open(out_path, "w", encoding="utf-8") as f:
        f.write("wage_to,employer,employee\n")
        for _no, wage_to, er, ee, _total in ROWS:
            ceiling = f"{wage_to:.2f}" if wage_to is not None else ""
            f.write(f"{ceiling},{er:.2f},{ee:.2f}\n")
    print(f"   -> {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
