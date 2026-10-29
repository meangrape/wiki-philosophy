#!/usr/bin/env python3
"""Convert saved psql output (make stats / make stats-full) to Markdown.

    tools/psql_to_md.py philosophy.txt > philosophy.md

Section markers from the SQL scripts become headings, aligned psql tables
become Markdown tables, and psql noise (SELECT n, CREATE INDEX, timing
lines) is dropped. Underscores in titles are shown as spaces.
"""
import re
import sys

NOISE = re.compile(r"^(Timing is (on|off)\.|SELECT \d+|CREATE INDEX|DROP TABLE|INSERT \d+ \d+|ANALYZE|SET|RESET|Time: .*)$")
NUMERIC = re.compile(r"^-?[\d,]+(\.\d+)?%?$")


def cell(text):
    text = text.strip().replace("_", " ").replace(" -> ", " → ")
    return text.replace("|", "\\|")


def emit_table(header, rows, out):
    cols = [c.strip() for c in header.split("|")]
    body = [[cell(c) for c in r.split("|")] for r in rows]
    body = [r + [""] * (len(cols) - len(r)) for r in body]
    numeric = [all(NUMERIC.match(r[i].replace(" ", "")) for r in body if r[i]) and any(r[i] for r in body)
               for i in range(len(cols))]
    out.append("| " + " | ".join(c.replace("_", " ") for c in cols) + " |")
    out.append("|" + "|".join("---:" if n else "---" for n in numeric) + "|")
    for r in body:
        out.append("| " + " | ".join(r) + " |")
    if not body:
        out.append("| " + " | ".join("" for _ in cols) + " |")
    out.append("")


def convert(lines):
    out = []
    i, n = 0, len(lines)
    title_done = False
    while i < n:
        line = lines[i].rstrip("\n")
        if line.startswith("====="):
            if not title_done:
                m = re.match(r"=====\s+(\S+)(?:\s+(\S+))?\s+(\d\d:\d\d:\d\d)", line)
                out.append("# Wiki-philosophy: first-link statistics")
                out.append("")
                out.append(f"Output of `make {m.group(1) if m else 'stats'}`, run at {m.group(3) if m else ''}.")
                out.append("")
                title_done = True
            i += 1
            continue
        if line.startswith("####"):
            rule = re.search(r"rule = (\w+)", line).group(1)
            desc = {"strict": "parenthesized links are skipped",
                    "paren": "parenthesized links count"}.get(rule, "")
            out.append(f"## Rule: {rule}" + (f" ({desc})" if desc else ""))
            out.append("")
            i += 1
            continue
        if line.startswith("== "):
            out.append("### " + line[3:].strip())
            out.append("")
            i += 1
            continue
        if NOISE.match(line.strip()) or line.strip() == "":
            i += 1
            continue
        # psql table: header line, then a dashes/plus separator line
        if i + 1 < n and re.match(r"^-+(\+-+)*$", lines[i + 1].strip()):
            header = line
            rows = []
            i += 2
            while i < n and lines[i].strip() != "" and not re.match(r"^\(\d+ rows?\)$", lines[i].strip()):
                rows.append(lines[i].rstrip("\n"))
                i += 1
            emit_table(header, rows, out)
            continue
        m = re.match(r"^(\w+) = (.+)$", line.strip())
        if m:
            out.append(f"**{m.group(1).replace('_', ' ')}**: {m.group(2)}")
            out.append("")
            i += 1
            continue
        out.append(line.strip())
        out.append("")
        i += 1
    return "\n".join(out).rstrip() + "\n"


if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else "/dev/stdin"
    with open(src, encoding="utf-8") as f:
        sys.stdout.write(convert(f.readlines()))
