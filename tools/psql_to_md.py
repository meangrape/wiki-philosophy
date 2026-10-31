#!/usr/bin/env python3
"""Convert saved psql output (make stats / make stats-full) to Markdown.

    tools/psql_to_md.py philosophy.txt > philosophy.md

Section markers from the SQL scripts become headings, aligned psql tables
become Markdown tables, and psql noise (SELECT n, CREATE INDEX, timing
lines) is dropped. Underscores in titles are shown as spaces.

Heading levels: stage (# Summary, # Report: strict rule ...), rule within
a stage (## I. Rule: strict ...), and leaf (### A. Where articles end up).
Rules are numbered I., II. and leaves A., B., restarting under each stage
or rule. A leaf heading's trailing parenthetical becomes a note line
under the heading (a "note" div, typeset small and italic by
tools/pagebreaks.lua).
"""
import re
import sys

NOISE = re.compile(r"^(Timing is (on|off)\.|SELECT \d+|CREATE INDEX|CREATE FUNCTION|DROP TABLE|INSERT \d+ \d+|ANALYZE|SET|RESET|Time: .*)$")
RULES = {"strict": "parenthesized, italicized and template links are skipped",
         "parens_ok": "italicized and template links are skipped",
         "skip_parens": "only parenthesized links are skipped",
         "skip_italics": "only italicized links are skipped",
         "loose": "only template links are skipped"}
STAGES = {"stats": "Summary", "compare": "Every rule against strict",
          "report": "Report", "stats-full": "Full statistics"}
TITLE = "Wiki-philosophy: first-link statistics"
NUMERIC = re.compile(r"^-?[\d,]+(\.\d+)?%?( ?\(\d+(\.\d+)?%\))?$")


INTEGER = re.compile(r"^-?\d{4,}$")
DECIMAL = re.compile(r"^(-?\d{4,})(\.\d+)$")


def group_digits(text):
    """3736376 -> 3,736,376; 1234.56 -> 1,234.56; anything else unchanged."""
    m = DECIMAL.match(text)
    if m:
        return f"{int(m.group(1)):,}{m.group(2)}"
    if INTEGER.match(text):
        return f"{int(text):,}"
    return text


MD_SPECIAL = re.compile(r"([\\`*_{}\[\]()#+!$<>~^|&@-])")
LIST_NUMBER = re.compile(r"^(\d+)([.)])(?=\s|$)")
FOOTNOTE_DEF = re.compile(r"^\[\^\w+\]: ")


def md_escape(text):
    """Backslash-escape Markdown/pandoc punctuation so data renders literally.

    Covers emphasis, inline math, raw HTML/LaTeX, links, code, lists, tables,
    citations and sub/superscript; a leading "1." is escaped so it is not
    read as an ordered list. Apply only to data, never to emitted markup.
    """
    return LIST_NUMBER.sub(r"\1\\\2", MD_SPECIAL.sub(r"\\\1", text))


def cell_text(text):
    """psql cell -> display text (digits grouped, _ as space, -> as arrow)."""
    return group_digits(text.strip()).replace("_", " ").replace(" -> ", " → ")


ROMAN = [(10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]


def roman(n):
    out = ""
    for value, digits in ROMAN:
        while n >= value:
            out += digits
            n -= value
    return out


def alpha(n):
    """1 -> A, 26 -> Z, 27 -> AA."""
    out = ""
    while n:
        n, r = divmod(n - 1, 26)
        out = chr(65 + r) + out
    return out


def split_note(text):
    """'Heading (note)' -> ('Heading', '(note)'); untouched when the text does
    not end with a balanced parenthetical preceded by a space. A footnote
    reference inside the parenthetical travels with the note."""
    if not text.endswith(")"):
        return text, None
    depth = 0
    for i in range(len(text) - 1, -1, -1):
        c = text[i]
        if c == ")":
            depth += 1
        elif c == "(":
            depth -= 1
            if depth == 0:
                if i > 0 and text[i - 1] == " ":
                    return text[:i - 1].rstrip(), text[i:]
                return text, None
    return text, None


def emit_table(header, rows, out):
    cols = [c.strip() for c in header.split("|")]
    body = [[cell_text(c) for c in r.split("|")] for r in rows]
    if len(cols) == 1:
        # chains, title lists: one bullet per row reads better than a table
        out.extend(f"- {md_escape(r[0])}" for r in body if r[0])
        if not body:
            out.append("*(none)*")
        out.append("")
        return
    body = [r + [""] * (len(cols) - len(r)) for r in body]
    numeric = [all(NUMERIC.match(r[i].replace(" ", "")) for r in body if r[i]) and any(r[i] for r in body)
               for i in range(len(cols))]
    out.append("| " + " | ".join(md_escape(c.replace("_", " ")) for c in cols) + " |")
    out.append("|" + "|".join("---:" if n else "---" for n in numeric) + "|")
    for r in body:
        out.append("| " + " | ".join(md_escape(c) for c in r) + " |")
    if not body:
        out.append("| " + " | ".join("" for _ in cols) + " |")
    out.append("")


def convert(lines):
    out = []
    i, n = 0, len(lines)
    title_done = False
    stage_rule = None
    rule_no = leaf_no = 0
    while i < n:
        line = lines[i].rstrip("\n")
        if line.startswith("====="):
            m = re.match(r"=====\s+(\S+)(?:\s+([a-z_]+))?\s+(\d\d:\d\d:\d\d)", line)
            stage = m.group(1) if m else line.strip("= ")
            rule = m.group(2) if m else None
            if not title_done:
                out.extend(["---", f'title: "{TITLE}"', "---", ""])
                title_done = True
            label = STAGES.get(stage, stage)
            stage_rule = rule
            rule_no = leaf_no = 0
            out.append(f"# {label}" + (f": {rule} rule ({RULES.get(rule, '')})" if rule else ""))
            out.append("")
            i += 1
            continue
        if line.startswith("####"):
            m = re.search(r"rule = (\w+)", line)
            rule = m.group(1) if m else None
            if rule == stage_rule:   # stage heading already names the rule
                i += 1
                continue
            rule_no += 1
            leaf_no = 0
            if rule is None:
                out.append(f"## {roman(rule_no)}. " + line.strip("# "))
            else:
                out.append(f"## {roman(rule_no)}. Rule: {rule}" + (f" ({RULES[rule]})" if rule in RULES else ""))
            out.append("")
            i += 1
            continue
        if line.startswith("== "):
            leaf_no += 1
            text, note = split_note(line[3:].strip())
            out.append(f"### {alpha(leaf_no)}. {text}")
            out.append("")
            if note:
                out.extend(["::: note", f"*{note}*", ":::", ""])
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
            out.append(f"**{m.group(1).replace('_', ' ')}**: {md_escape(m.group(2))}")
            out.append("")
            i += 1
            continue
        if re.match(r"^(psql:|ERROR:|DETAIL:|HINT:|LINE \d+:)", line.strip()):
            # psql diagnostics: show verbatim in a code block, never as markup
            out.append("```")
            while i < n and lines[i].strip() != "":
                out.append(lines[i].rstrip("\n"))
                i += 1
            out.append("```")
            out.append("")
            continue
        # free text is \echo prose from the SQL: keep its footnote definitions
        # and "- " list markers as markup, escape everything else
        text = line.strip()
        if FOOTNOTE_DEF.match(text):
            out.append(text)
        elif text.startswith("- "):
            out.append("- " + md_escape(text[2:]))
        else:
            out.append(md_escape(text))
        out.append("")
        i += 1
    return "\n".join(out).rstrip() + "\n"


if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else "/dev/stdin"
    with open(src, encoding="utf-8") as f:
        sys.stdout.write(convert(f.readlines()))
