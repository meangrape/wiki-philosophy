# wiki-philosophy

Does clicking the first link of every Wikipedia article eventually lead to
[Philosophy](https://en.wikipedia.org/wiki/Philosophy)? This repository tests
the claim against a full English Wikipedia dump: a Rust parser extracts the
first link of every article into a CSV, and a set of PostgreSQL scripts turns
that into a graph, classifies where every chain ends, and reports the numbers.

## Pipeline

```
enwiki-<date>-pages-articles-multistream.xml.bz2   (27 GB)
        │  ./target/release/wiki-philosophy          ~5 min
        ▼
wiki_edges.csv   title, <rule>_target_title x5, is_redirect
        │  psql -f sql/01_load.sql                   ~6 min
        ▼
wiki_pages       one row per node, redirect chains collapsed into next_<rule>
        │  psql -v rule=<rule> -f sql/02_topology.sql   ~1.5 min per rule, 5 rules
        ▼
wiki_topology_<rule>   where every node's chain ends under each rule
        │  sql/03_report.sql, sql/04_compare.sql, sql/05_stats.sql
        ▼
reports
```

Everything downstream of the dump is rebuildable; the database is treated as
disposable (see Postgres settings below).

### Requirements

- Rust toolchain (edition 2024). Dependencies: `quick-xml`, `bzip2` with its
  pure-Rust backend, `rayon`, `crossbeam-channel`, `memmap2`, `memchr`.
- PostgreSQL 18. The scripts use `\if`, `\gset` and `psql` variables.
- The multistream dump, e.g.
  `enwiki-20261001-pages-articles-multistream.xml.bz2`. The multistream
  index file is not needed.

### Running

```sh
make                      # build, parse, load, classify all five rules, all reports; log in run.log
make parse                # just the CSV
make load                 # through the Postgres load
make topology             # all five rules classified
make articles             # articles-only results table the reports read
make stats                # short summary for all five rules, with example chains
make report compare stats-full
make pdf                  # philosophy.txt, .md, .pdf: summary, comparison, reports, full stats
make docs                 # regenerate the document only, from the database as it is
make DUMP=~/dumps/enwiki.xml.bz2 DB=wiki
```

Stages are tracked with stamp files in `.stamps/`, so editing a SQL file and
running `make` reruns only that stage and the ones after it. `make clean`
forgets the stamps; `make distclean` also removes the CSV and the Rust build.
The stages by hand:

```sh
cargo build --release
./target/release/wiki-philosophy [path/to/dump.xml.bz2]      # writes wiki_edges.csv

psql -d wiki-phil -v csv=/abs/path/wiki_edges.csv -f sql/01_load.sql
for r in strict parens_ok skip_parens skip_italics loose; do psql -d wiki-phil -v rule=$r -f sql/02_topology.sql; done
psql -d wiki-phil -f sql/02b_articles.sql
for r in strict parens_ok skip_parens skip_italics loose; do psql -d wiki-phil -v rule=$r -f sql/03_report.sql; done
psql -d wiki-phil -f sql/04_compare.sql
for r in strict parens_ok skip_parens skip_italics loose; do psql -d wiki-phil -v rule=$r -f sql/05_stats.sql; done
psql -d wiki-phil -f sql/06_summary.sql
```

`01_load.sql` uses a server-side `COPY`, so the Postgres server process must
be able to read the CSV. Do not edit a script while `psql` is executing it:
psql reads the file incrementally and will pick up the edit mid-run.

Parser environment variables:

| variable | effect |
|---|---|
| `OUTPUT_CSV=path` | write somewhere other than `./wiki_edges.csv` |
| `MAX_BATCHES=n` | stop after n batches of 8 streams (benchmarking) |
| `NULL_SAMPLE=path` | write title + first 300 chars of every page with no qualifying link, up to 3000 |

`./target/release/wiki-philosophy --first-link a.wikitext b.wikitext` prints
the link the scanner would pick for a wikitext file, under all five rules. Useful
for checking a single page against a manual walk.

## The link rules

"First link" follows the conventions of the
[Getting to Philosophy](https://en.wikipedia.org/wiki/Wikipedia:Getting_to_Philosophy)
game. A candidate link can sit in three contexts that a rule may exclude:
inside parentheses, inside italics, or inside a template or table. The
scanner records all three for every candidate and emits, in one pass, the
first link under each of five rules:

| rule | skips | note |
|---|---|---|
| `strict` | parenthesized, italicized, template | Wikipedia's strict rule |
| `parens_ok` | italicized, template | parenthesized links count; how most people play by hand |
| `skip_parens` | parenthesized | italics and templates count |
| `skip_italics` | italicized | parentheses and templates count |
| `loose` | template | Wikipedia's loose rule |

Every rule also skips links inside `<!-- -->`, `<ref>`, `<nowiki>`,
`<math>`, `<chem>`, `<gallery>`, `<pre>`, `<code>`, `<syntaxhighlight>`,
`<source>`, `<timeline>`, `<imagemap>`, `<score>`, `<hiero>`, `<mapframe>`,
`<maplink>`, and links into another namespace: `File:`, `Image:`,
`Category:`, `Template:`, `Wikipedia:`, `Help:`, `Portal:`, interwiki
prefixes such as `wikt:` or `commons:`, two-to-twelve-letter language codes
such as `fr:`, and anything starting with `:`. A colon alone does not
disqualify a target: "Dune: Part Two" is an article. Namespaced links are
skipped together with their caption, so a link inside
`[[File:x.jpg|thumb|see [[Foo]]]]` is not taken.

"Template" means inside any `{{ }}` template or `{| |}` table at any nesting
depth. Infoboxes, hatnotes and navboxes are all templates, and the scanner
cannot tell them apart without expanding them, so "non-infobox" in
Wikipedia's wording is implemented as "not inside any template". Under
`skip_parens` and `skip_italics` the first link is therefore very often an
infobox link.

The CSV carries one `<rule>_target_title` column per rule; the database
carries `next_<rule>` (redirects collapsed), `wiki_topology_<rule>`,
`cycle_nodes_<rule>`, and `<rule>_type`, `<rule>_dist`, `<rule>_terminal`
in `wiki_articles`. Rule names are turned into those column and table names
by `sql/rule_vars.sql`, which the per-rule scripts include.

Two scanner details that matter for the numbers:

- Parentheses are only counted at brace depth zero and reset at every line
  break. Inside templates they are unbalanced constantly (image file names,
  coordinates, footnotes), and one stray `(` would otherwise hide every later
  link on the page.
- Extension tags are skipped as units, not deleted from the text. A `<ref>`
  between two italic markers must not fuse them into one apostrophe run,
  which is also how MediaWiki parses it.

### Target normalization

Link targets are turned into the canonical page title form so they join
against `<title>` values: `#anchor` removed, HTML entities such as `&nbsp;`
decoded, whitespace collapsed to `_`, leading and trailing `_` trimmed, first
letter upper-cased (enwiki is `case="first-letter"`). A target still
containing `{ } < > [ ] |` is treated as no link.

### Redirects and namespaces

- Only namespace 0 pages are parsed, decided by the dump's `<ns>` element,
  not by the title.
- A redirect page's target is taken from the dump's `<redirect title=...>`
  element and written with `is_redirect = t`. Redirects into non-article
  namespaces are treated as no link.
- In the database, redirect chains are collapsed: `next_id` is the first
  non-redirect page reached by following up to 10 redirects, so a redirect
  never counts as a click. Redirect pages remain nodes but are excluded from
  every percentage. When the chain never reaches an article (a redirect
  loop, more than 10 redirects, or a redirect into another namespace),
  `next_id` is NULL and the page is a dead end of kind `redirect`.
- Link targets that are not pages in the dump (red links, or titles that
  moved during the dump) become nodes with `in_dump = f` and no out-link.
  That lets a dead end be attributed to a missing page rather than to an
  article with no link. The reports label dead ends by kind: `red` (the
  first link points at a page that is not in the dump), `redirect` (the
  first link is a redirect that never resolves) and `none` (the page has no
  qualifying first link).

## What the SQL does

**01_load.sql.** `COPY` the CSV; deduplicate titles with one `DISTINCT ON`
pass (a page moved while the dump is written appears twice, once as article
and once as redirect; the article row wins); assign node ids once; build
`wiki_pages` in a single `CREATE TABLE AS` with the five raw link targets and the five
redirect-collapsed `next_<rule>` columns. No `UPDATE` is run on the big table, so
nothing bloats and, under `wal_level = minimal`, nothing is WAL-logged.

**02_topology.sql.** Every node has out-degree at most one, so the graph is a
set of chains flowing into either a sink, a cycle, or Philosophy. Rather than
walk forward from every page with a path array, the script walks backward
from the terminals, which is a tree walk that touches each node once:

1. Backward BFS from Philosophy and from every sink (no link), labelling
   `philosophy` and `dead_end` with the distance in clicks. Philosophy's own
   chain may lead away from it, so the walk refuses to step back onto
   Philosophy.
2. Nodes still unlabelled all flow into cycles. Stripping nodes with no
   in-link to a fixpoint leaves exactly the cycle members; each cycle gets a
   canonical id (its smallest member) and its length.
3. Backward BFS from the cycle members labels the rest as `cycle`.

A primary key on `page_id` asserts every node is labelled exactly once. The
recursive terms disable merge and hash joins, because the planner cannot
estimate the working table and otherwise picks a plan that rescans the whole
index on every iteration.

**02b_articles.sql** (`make articles`): one row per article with the outcome
and distance under each of the five rules, so the reports below read a 7 million row
table without joining the 19 million row topology tables each time.

**03_report.sql**, per rule: terminal breakdown over articles, click
distribution, longest roads, where Philosophy itself leads, biggest dead ends
split into red links versus link-less articles, biggest cycles with their
trajectory.

**04_compare.sql**: every rule against the strict rule: where articles end
up, how often the first link differs, articles gained and lost to Philosophy,
clicks compared, two cross-tabs (strict versus parens_ok, strict versus loose), and
the cumulative share within N clicks and the milestone clicks for all five
rules, with two denominators: all articles, and only the articles that reach
Philosophy under that rule. The denominator matters: under the strict rule
roughly half of all articles never arrive.

**06_summary.sql** (`make stats`): all five rules on one page: where articles end
up, mean, median and modal clicks, milestones, Philosophy's own chain under
each rule, and random example chains of articles that end in a cycle or at a
dead end, printed in full. It includes `06_summary_rule.sql` once per rule.

`make pdf` captures the summary, the comparison, the per-rule reports and the full
stats into `philosophy.txt`, converts it with `tools/psql_to_md.py` into
`philosophy.md`, and typesets `philosophy.pdf` with pandoc and xelatex. The
document opens with where articles end up and example chains of articles
that never reach Philosophy.

**05_stats.sql** (`make stats-full`), per rule: cumulative shares and milestones ("50% of articles
within N clicks"), Philosophy's own loop length, articles exactly as far from
Philosophy as Philosophy is from itself, farthest chain heads, single-file
tails (long chains that own the far distances, such as the Eastern Orthodox
liturgics calendar pages, each linking first to the previous day), and the
shortest roads from unexpected places.

### Tables

| table | contents |
|---|---|
| `wiki_pages` | `id`, `title`, `in_dump`, `is_redirect`, `<rule>_target` and `next_<rule>` for each of the five rules |
| `wiki_topology_<rule>` | `page_id`, `terminal_type` (`philosophy`, `dead_end`, `cycle`), `terminal_id`, `distance` |
| `cycle_nodes_<rule>` | cycle members with `cycle_id` and `cycle_len` |
| `wiki_articles` | articles only: `title`, `next_<rule>`, `<rule>_target`, `<rule>_type`, `<rule>_dist`, `<rule>_terminal` for each rule |

## Results snapshot (dump of 2026-10-01)

Articles: 7,249,098. Redirects: 12,065,386. Red-link targets: 30,031. The
two Wikipedia rules disagree with each other far less than either disagrees
with the single-exclusion variants:

| rule | skips | reach Philosophy | in a cycle | dead end | mean clicks |
|---|---|---|---|---|---|
| strict | parens, italics, templates | 51.5% | 47.4% | 1.0% | 15.2 |
| parens_ok | italics, templates | 94.8% | 4.2% | 1.0% | 14.1 |
| skip_parens | parens only | 7.8% | 89.8% | 2.4% | 13.7 |
| skip_italics | italics only | 16.5% | 81.2% | 2.3% | 14.8 |
| loose | templates only | 94.8% | 4.3% | 0.8% | 14.0 |

- The loose rule and parens_ok give the same answer for
  93 percent of articles and the same headline: 94.8 percent reach
  Philosophy, half of Wikipedia within 15 clicks, 90 percent within 21.
- The strict rule loses because Philosophy itself does not loop back:
  Philosophy → Existence → Reality → Existence. A seven-page loop, Attitude
  (psychology) → Psychology → Mind → Thought → Cognition → Knowledge → Belief,
  then holds 3.1 million articles. Under parens_ok and loose, Philosophy
  returns to itself in 9 clicks through Ancient Greek; under skip_italics in
  16; under skip_parens it does not return (Philosophy → Existence → Reality
  → Existence, as under strict).
- Allowing template links (skip_parens, skip_italics) changes the first link of 59 percent of
  articles, because the first link on most pages is then an infobox or
  navbox link, and a single two-page loop, Provinces of Laos ↔ Xaisomboun
  province, swallows 2.1 to 2.8 million articles.
- The longest distance under strict, parens_ok and loose is 201 clicks, the saint
  Gelasius, via about 170 single-file pages of the Eastern Orthodox
  liturgical calendar, each linking first to the previous day.

Rerun the reports for current numbers.

## Parser design notes

The dump is a concatenation of independent bzip2 streams of 100 pages each.
The parser memory-maps the file, finds every stream header with a SIMD
substring search (`BZh<n>` followed by the block magic `1AY&SY`), hands
batches of 8 streams to a rayon pool, and each worker decompresses and parses
its batch independently with quick-xml. The writer thread reorders batches so
the CSV is in dump order. Decompression uses the pure-Rust bzip2 port, which
is faster than C libbz2 on Apple Silicon. On a 16-core M4 Max the full dump
parses at about 97 MB/s of compressed input, around 5 minutes.

## Postgres settings

The analysis cluster is tuned for one user and a rebuildable database:
`wal_level = minimal`, `fsync = off`, `synchronous_commit = off`,
`full_page_writes = off`, 32 GB `shared_buffers`, 2 GB `work_mem`,
`random_page_cost = 1.1`, `io_method = worker` with 8 workers. Do not reuse
these settings for data you cannot regenerate. `wal_level = minimal` requires
`max_wal_senders = 0`.

## Known limitations

- Italics detection is line-local and heuristic; MediaWiki's apostrophe
  parsing has more special cases.
- Hatnotes and infoboxes are templates and so are skipped, which matches the
  game's rules, but a link inside a non-template HTML element such as a
  `<div>` is still taken.
- Links generated by templates (for example `{{lang}}` or `{{ill}}`) are not
  seen at all, since templates are not expanded.
- Redirect resolution stops after 10 hops and does not follow redirects into
  other namespaces; a first link whose redirect never resolves is reported
  as a dead end of kind `redirect`, not as the page it would eventually
  reach.
- "Strange" and "unexpected" in the stats are proxies: single common-word
  titles and a keyword filter, not a notability measure.
