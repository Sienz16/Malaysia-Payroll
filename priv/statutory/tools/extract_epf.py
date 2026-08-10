"""Extract EPF Third Schedule bands from the official KWSP PDF text layer.

Walks the document linearly, attributing each band row to the most recent
PART header, so page ordering and form-feed placement cannot mis-slice a part.

Refuses to emit anything it cannot validate: every row must parse as a number,
employer + employee must equal the printed total, and each part's bands must
tile 0.01..20000.00 with no gap, overlap, or duplicate.
"""
import re
import sys

# Split on "\n" only. str.splitlines() also breaks on \x0c (form feed), which
# pdftotext emits as a page separator, which would shift every line number.
HEADER = re.compile(r"^\s*PART\s+([A-F])\s*$")
ROW = re.compile(
    r"From\s+([\d,]+\.\d{2})\s+to\s+([\d,]+\.\d{2})\s+"
    r"(NIL|[\d,]+\.\d{2})\s+(NIL|[\d,]+\.\d{2})\s+(NIL|[\d,]+\.\d{2})"
)

BAND_PARTS = ("A", "C", "E")


def num(tok):
    return 0.0 if tok == "NIL" else float(tok.replace(",", ""))


def cents(x):
    return int(round(x * 100))


def parse(text):
    parts = {}
    current = None
    for line in text.split("\n"):
        head = HEADER.match(line.replace("\x0c", ""))
        if head:
            current = head.group(1)
            parts.setdefault(current, [])
            continue
        m = ROW.search(line)
        if m and current:
            lo, hi, er, ee, tot = (num(g) for g in m.groups())
            parts[current].append((lo, hi, er, ee, tot))
    return parts


def validate(rows):
    errs = []
    if not rows:
        return ["no rows parsed"]

    for lo, hi, er, ee, tot in rows:
        if cents(er) + cents(ee) != cents(tot):
            errs.append(f"band {lo}-{hi}: {er} + {ee} != {tot}")

    if cents(rows[0][0]) != 1:
        errs.append(f"first band starts at {rows[0][0]}, expected 0.01")
    if cents(rows[-1][1]) != 2_000_000:
        errs.append(f"last band ends at {rows[-1][1]}, expected 20000.00")

    for (_, phi, *_), (lo, hi, *_) in zip(rows, rows[1:]):
        if cents(lo) != cents(phi) + 1:
            errs.append(f"gap/overlap: {phi} -> {lo}")
        if cents(hi) <= cents(lo):
            errs.append(f"non-increasing band {lo}-{hi}")
    return errs


def main(txt_path, out_dir):
    parts = parse(open(txt_path, encoding="utf-8").read())
    failed = False

    for part in BAND_PARTS:
        rows = sorted(set(parts.get(part, [])))
        errs = validate(rows)
        print(f"Part {part}: {len(rows)} bands  {'OK' if not errs else 'FAIL'}")
        for e in errs[:10]:
            print(f"   ! {e}")
        if errs:
            failed = True
            continue
        path = f"{out_dir}/part_{part.lower()}.csv"
        with open(path, "w", encoding="utf-8") as f:
            f.write("wage_from,wage_to,employer,employee\n")
            for lo, hi, er, ee, _ in rows:
                f.write(f"{lo:.2f},{hi:.2f},{er:.2f},{ee:.2f}\n")
        print(f"   -> {path}")

    for part in ("B", "D"):
        if parts.get(part):
            print(f"Part {part}: expected deleted, got {len(parts[part])} rows")
            failed = True

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2]))
