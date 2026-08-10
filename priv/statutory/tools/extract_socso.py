"""Extract the PERKESO Act 4 contribution table (including SKBBK) from the
official PDF text layer.

Category 1 = employment injury + invalidity + non-employment injury (SKBBK).
Category 2 = employment injury + non-employment injury (SKBBK).

The PDF's text layer is layout-scrambled: row numbers drift onto neighbouring
lines and interleave into the band descriptions. So nothing here keys off row
numbering or line position. Instead:

  * a rate row is any line carrying exactly 7 two-decimal amounts;
  * band bounds are the RM values *without* decimals, read after the amounts
    have been stripped out.

Everything is then cross-checked: component sums against printed totals, bands
tiling contiguously, and the expected row/band counts.
"""
import re
import sys

AMOUNT = re.compile(r"RM([\d,]+\.\d{2})")
# Row markers drift to arbitrary points inside the band text ("exceed RM1,200
# but 17. do not exceed RM1,300"), so drop them before reading bands. Once
# amounts are stripped, a bare "N." not preceded by RM is always a row marker.
ROW_MARKER = re.compile(r"(?<!RM)\b\d{1,2}\.(?=\s)")
BAND = re.compile(r"exceed RM([\d,]+) but do not exceed RM([\d,]+)")

EXPECTED_ROWS = 65
FIRST_CEILING = 30.0
LAST_CEILING = 6000.0


def num(tok):
    return float(tok.replace(",", ""))


def cents(x):
    return int(round(x * 100))


def parse(text):
    rows = []
    for line in text.split("\n"):
        vals = [num(v) for v in AMOUNT.findall(line)]
        if len(vals) == 7:
            rows.append(vals)

    stripped = re.sub(r"\s+", " ", ROW_MARKER.sub(" ", AMOUNT.sub(" ", text)))
    bands = [(num(a), num(b)) for a, b in BAND.findall(stripped)]
    return rows, bands


def validate(rows, bands):
    errs = []
    if len(rows) != EXPECTED_ROWS:
        errs.append(f"expected {EXPECTED_ROWS} rate rows, parsed {len(rows)}")
    if len(bands) != EXPECTED_ROWS - 2:
        errs.append(f"expected {EXPECTED_ROWS - 2} bands, parsed {len(bands)}")

    for i, v in enumerate(rows, start=1):
        c1_er, c1_inv, c1_nei, c1_tot, c2_er, c2_nei, c2_tot = v
        if cents(c1_er) + cents(c1_inv) + cents(c1_nei) != cents(c1_tot):
            errs.append(f"row {i}: cat1 {c1_er}+{c1_inv}+{c1_nei} != {c1_tot}")
        if cents(c2_er) + cents(c2_nei) != cents(c2_tot):
            errs.append(f"row {i}: cat2 {c2_er}+{c2_nei} != {c2_tot}")
        if cents(c1_nei) != cents(c2_nei):
            errs.append(f"row {i}: SKBBK differs between categories")

    if bands:
        if cents(bands[0][0]) != cents(FIRST_CEILING):
            errs.append(f"bands start at {bands[0][0]}, expected {FIRST_CEILING}")
        if cents(bands[-1][1]) != cents(LAST_CEILING):
            errs.append(f"bands end at {bands[-1][1]}, expected {LAST_CEILING}")
        for (_, hi), (lo, _) in zip(bands, bands[1:]):
            if cents(hi) != cents(lo):
                errs.append(f"band gap: {hi} -> {lo}")
                break
    return errs


def main(txt_path, out_path):
    rows, bands = parse(open(txt_path, encoding="utf-8").read())
    errs = validate(rows, bands)
    print(f"SOCSO: {len(rows)} rate rows, {len(bands)} bands  "
          f"{'OK' if not errs else 'FAIL'}")
    for e in errs[:10]:
        print(f"   ! {e}")
    if errs:
        return 1

    # Row 1 covers wages up to RM30; rows 2..64 take each band's upper bound;
    # row 65 is open-ended above RM6,000.
    ceilings = [FIRST_CEILING] + [hi for _, hi in bands]

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(
            "wage_to,cat1_employer,cat1_invalidity,cat1_skbbk,"
            "cat2_employer,cat2_skbbk\n"
        )
        for i, v in enumerate(rows):
            c1_er, c1_inv, c1_nei, _, c2_er, c2_nei, _ = v
            ceiling = f"{ceilings[i]:.2f}" if i < len(ceilings) else ""
            f.write(
                f"{ceiling},{c1_er:.2f},{c1_inv:.2f},{c1_nei:.2f},"
                f"{c2_er:.2f},{c2_nei:.2f}\n"
            )
    print(f"   -> {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2]))
