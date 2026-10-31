# Audit review findings — wiki-philosophy, working tree, 2026-10-30

Target: whole repository (working tree vs the empty tree, excluding generated philosophy.txt/md/pdf and Cargo.lock), 17 files, 1,912 lines.
Roster: 6 reviewers (rust, performance, general-purpose for SQL/README, python, devops, security), 4 SMEs on call; 42 agents in 4 phases. Raw findings 28; after cross-check and audit 27 kept (21 correctness, 5 performance, 1 resources); 1 low-stakes dispute resolved (discarded); 6 held verifications run after the workflow with operator approval: 5 confirmed, 1 confirmed with a falsified sub-claim.
Flat report with the verification addendum: .claude/reviews/worktree-2026-10-30.md

Headline: the parser skips every link whose title starts with a capitalized "Word:" (24,390 articles); the converter mislabels 8 of 12 sections for the four newer rules; `make docs` can silently rerun the whole pipeline; and `strip_leaves` races under `make -j`. Everything else is latent, rare, or a measured speedup.

<!-- Canonical cards fragment: audit-review, ref=worktree, 2026-10-30. Embedded verbatim in the findings presentation and the execution plan. -->

## Clusters (disjoint file sets; severity-descending)

| Cluster | Files | Cards | Agent |
|---|---|---|---|
| R  Rust parser | src/main.rs | 1, 8, 10, 11, 17, 18, 25, 27 | rust |
| P  Converter | tools/psql_to_md.py | 2, 9, 12, 20, 21 | python |
| M  Makefile | Makefile | 3, 4, 5 | devops |
| SA Topology/load SQL | sql/02_topology.sql, sql/01_load.sql | 13, 22, 23, 24 | performance |
| SB Report SQL + README | sql/03_report.sql, sql/06_summary_rule.sql, sql/rule_vars.sql, README.md | 7, 19, 15, 6 | general-purpose |
| SC Compare/stats SQL | sql/04_compare.sql, sql/06_summary.sql, sql/05_stats.sql | 16, 26, 14 | general-purpose |
| V  Coverage gaps (verify-only) | read-only | G1–G4 | per gap |

Clusters are larger than 2–3 where one file carries many findings; the disjoint-file rule wins over cluster size so every fix subagent can run in parallel. Finding 4 is assigned to M only (`.DELETE_ON_ERROR:` covers both the CSV and philosophy.txt; the parser-side temp-file write is optional and left to R if accepted there). Finding 7 is fixed at report level (SB) rather than in the load, so SA and SB stay disjoint.

Verification commands (Cargo.toml → `cargo build --release`, `cargo test`; psql scripts run per rule with `psql -X -d wiki-phil -v rule=<rule> -f <file>`; converter `python3 -I tools/psql_to_md.py philosophy.txt`; PDF via the Makefile's pandoc line). Tee long runs to /tmp. Subagents never commit; use gsed on macOS.

---

## Cluster R — src/main.rs (agent: rust)

### Card 1 — is_namespaced treats every "Word:" prefix as a namespace
- Category: correctness · Severity rank 1 (major) · **verified** (test + 24,390 affected titles)
- Location: src/main.rs:105-116 (`fn is_namespaced`), call sites :203 and :305
- Evidence: `let p = prefix.trim().to_ascii_lowercase()` then `p.bytes().all(|c| c.is_ascii_lowercase() || c == b'-')` is always true after lowercasing, so any 2–12 letter prefix passes. Temporary test `assert!(!is_namespaced("Dune: Part Two"))` failed. 24,390 in-dump titles match `^[A-Z][a-z-]{1,11}:_` (e.g. Pendragon:_The_Merchant_of_Death, Dominion:_Hinterlands, Aliens:_Harvest); 33,069 match the looser `^[A-Za-z-]{2,12}:`.
- Failure scenario: an article whose first link is `[[Aliens: Harvest]]` has that link skipped and takes the next one (wrong first link), or none (false dead end). A `<redirect title="Dominion: Hinterlands">` is dropped, so the redirect looks like a dead end (feeds card 7).
- Proposed fix: run the language-code heuristic on the un-lowercased prefix: `let raw = prefix.trim(); let p = raw.to_ascii_lowercase(); NON_ARTICLE_PREFIXES.contains(&p.as_str()) || ((2..=12).contains(&raw.len()) && raw.bytes().all(|c| c.is_ascii_lowercase() || c == b'-'))`. Add a `#[cfg(test)] mod tests` with the six cases (Dune: Part Two, Halo: Reach, Alien: Covenant → false; fr:Paris, File:X.jpg, wikt:word → true).
- Verify: `cargo test`; `./target/release/wiki-philosophy --first-link` on a scratch page whose first link is `[[Dune: Part Two]]`.

### Card 8 — link target scan never checks its terminator
- Category: correctness · Severity rank 8 · unverified (source reading)
- Location: src/main.rs:195-199
- Evidence: `while j < n && !matches!(b[j], b'|' | b']' | b'[' | b'\n') { j += 1 }` then `target = &text[start..j]` regardless of what stopped the scan. `[[Foo\n`, `[[Foo]` and `[[Foo[[Bar]]` all yield "Foo".
- Failure scenario: broken or unclosed brackets on a page become a first link to a page that was never linked.
- Proposed fix: after the loop require `j < n && (b[j] == b'|' || (b[j] == b']' && j + 1 < n && b[j + 1] == b']'))`; otherwise treat `[[` as literal text (`i += 2; continue`). Captions may span lines, so only the target must be same-line. Add tests for the three malformed forms.
- Verify: `cargo test`; `--first-link` on a scratch page containing `[[Foo\n` before a real link.

### Card 10 — unclosed skip tag swallows the rest of the page
- Category: correctness · Severity rank 10 · unverified
- Location: src/main.rs:99 (`Some(s.len())` at the end of `markup_skip_len`)
- Evidence: for `<ref>`, `<nowiki>`, `<math>` … with no closing tag the function returns `Some(s.len())`, discarding every later link. MediaWiki runs an unclosed tag to end-of-text only for includeonly/noinclude/onlyinclude; other unclosed openers render as literal text. Line 74 (unterminated comment runs to the end) is correct and stays.
- Failure scenario: a page with a stray `<ref>` and no `</ref>` is recorded with the wrong first link or no link (false dead end).
- Proposed fix: replace the final `Some(s.len())` with `None` so the `<` is treated as plain text and scanning continues. Add a test: `text <ref>unclosed [[A]] then [[B]]` → first link under strict is A (literal text; MediaWiki would also show it).
- Verify: `cargo test`.

### Card 11 — decode and parse errors are silent and exit 0
- Category: correctness · Severity rank 11 · unverified
- Location: src/main.rs:355-358 (`Err(e) => { eprintln!(...); break; }`), :457-459 (bzip2 error then parse anyway), Done summary, `main` return
- Evidence: an XML error drops the rest of the batch; a bzip2 error parses a truncated buffer; nothing is counted; `main` returns `Ok(())`.
- Failure scenario: a damaged dump produces a CSV missing thousands of pages, the Makefile stamps it as complete, and the missing pages surface downstream only as unresolved targets.
- Proposed fix: add `static XML_ERRORS`/`BZ_ERRORS: AtomicU64`, increment at both sites, print them in the Done summary, and return `Err("N batches had errors")` (non-zero exit) when either is non-zero so make stops and `.DELETE_ON_ERROR` (card 4) removes the CSV.
- Verify: `cargo build --release`; feed a truncated copy of a few streams (`head -c` of the dump into the scratchpad) and confirm non-zero exit and the counts.

### Card 17 — entity decoding is a chained replace
- Category: correctness · Severity rank 17 (downgraded, rare) · partially refuted (`&amp;nbsp;` case was wrong)
- Location: src/main.rs:127-131
- Evidence: `.replace("&amp;", "&")` runs before `.replace("&quot;", "\"")`, so `&amp;quot;` decodes twice to `"`; `&ndash;`, `&#x27;`, other numeric and named references are not decoded at all.
- Failure scenario: a target written with `&ndash;` never matches its canonical title → red link.
- Proposed fix: a single left-to-right `decode_entities(&str) -> String`: on `&`, look for `;` within ~10 bytes; map `amp quot apos nbsp ndash mdash` and `&#NNN;` / `&#xHH;` via `char::from_u32`; otherwise copy the `&` literally. Tests for `&amp;quot;` → `&quot;` and `&ndash;`.
- Verify: `cargo test`.

### Card 18 — mixed space/underscore runs are not collapsed
- Category: correctness · Severity rank 18 (rare) · unverified
- Location: src/main.rs:135-136
- Evidence: `split_whitespace().join("_")` leaves `Foo__Bar` and `Foo _Bar` unchanged, which never match the canonical `Foo_Bar`.
- Proposed fix: `no_anchor.split(|c: char| c.is_whitespace() || c == '_').filter(|s| !s.is_empty()).collect::<Vec<_>>().join("_")`. Test the two forms.
- Verify: `cargo test`.

### Card 25 — scanner finds every stream header before sending the first batch
- Category: performance · Severity rank 4 of 5 · measured in run.log (4.6 s of 158.7 s, workers idle)
- Location: src/main.rs:433-449 (`let starts = stream_starts(data)` then the chunk loop), :369-377
- Evidence: `stream_starts` scans the whole 27 GB mapping before the loop; `memmem::find_iter` is already incremental.
- Proposed fix: iterate `find_iter` directly in the scanner thread, pushing starts into a Vec and sending batch k as soon as start index (k+1)·STREAMS_PER_BATCH is known; send the final partial batch with `end = data.len()` after the iterator ends; print the stream count at the end. ~3% saving, less with a cold cache. Optional.
- Verify: `cargo build --release`; `MAX_BATCHES=50` timing before/after.

### Card 27 — a single-stream or wrong-format input preallocates ~190 GB
- Category: resources · Severity rank 1 of 1 · unverified (operational, not adversarial)
- Location: src/main.rs:441-444, 456-457; Makefile:15 example path
- Evidence: a non-multistream bz2 yields `starts=[0]` → one batch spanning the file → `Vec::with_capacity(slice.len() * 8)` then unbounded `read_to_end`.
- Failure scenario: `make DUMP=~/dumps/enwiki.xml.bz2` with the single-stream dump aborts with an allocation failure after mapping 27 GB.
- Proposed fix: after scanning, fail fast if `starts.len() < data.len() / (16 << 20)` with "not a multistream dump (N streams in M bytes)"; cap the preallocation at `min(slice.len() * 8, 256 << 20)`.
- Verify: `cargo build --release`; run on a small single-stream `.bz2` of a few KB created with `bzip2` in the scratchpad and confirm the error message.

---

## Cluster P — tools/psql_to_md.py (agent: python)

### Card 2 — stage regex only accepts the old rule names
- Category: correctness · Severity rank 2 (major) · **verified** against philosophy.md
- Location: tools/psql_to_md.py:74
- Evidence: `(?:\s+(strict|paren))?` fails for parens_ok, skip_parens, skip_italics and loose, so 8 of 12 H2 headings render as raw marker text with timestamps (philosophy.md:426, 553, 664, 776, 1073, 1294, 1469, 1689) and those sections get duplicate `### Rule:` headings because `stage_rule` stays None.
- Proposed fix: `r"=====\s+(\S+)(?:\s+([a-z_]+))?\s+(\d\d:\d\d:\d\d)"`. Fix together with card 9 (the `RULES[rule]` lookup at :85 would otherwise raise KeyError).
- Verify: `python3 -I tools/psql_to_md.py philosophy.txt > /tmp/p.md && grep -c '^## ' /tmp/p.md` (expect 12) and `grep -c '^=====' /tmp/p.md` (expect 0).

### Card 9 — RULES dict is stale
- Category: correctness · Severity rank 9 · verified against rule_vars.sql
- Location: tools/psql_to_md.py:14
- Evidence: strict described as "parenthesized links are skipped" (rule_vars.sql:14 says parenthesized, italicized and template links are skipped); dead 'paren' key; no entries for the four other rules; `RULES[rule]` unguarded at :85.
- Proposed fix: `RULES = {"strict": "parenthesized, italicized and template links are skipped", "parens_ok": "italicized and template links are skipped", "skip_parens": "only parenthesized links are skipped", "skip_italics": "only italicized links are skipped", "loose": "only template links are skipped"}` and `RULES.get(rule, "")` at both lookups.
- Verify: as card 2; headings show the right description per rule.

### Card 12 — STAGES label for compare is wrong
- Category: correctness · Severity rank 12 · verified (philosophy.md:174)
- Location: tools/psql_to_md.py:15
- Evidence: "Strict rule versus parentheses rule"; 04_compare.sql compares all five rules against strict.
- Proposed fix: `"compare": "Every rule against strict"`.
- Verify: as card 2.

### Card 20 — `####` line without "rule = <word>" crashes the converter
- Category: correctness · Severity rank 20 (latent) · unverified
- Location: tools/psql_to_md.py:89-90
- Evidence: `re.search(r"rule = (\w+)", line).group(1)` with no None guard.
- Proposed fix: `m = re.search(...); rule = m.group(1) if m else None`; when None, emit `### ` + the line stripped of `#`.
- Verify: pipe `printf '===== stats 00:00:00\n#### note\n'` through the converter; no traceback.

### Card 21 — Markdown metacharacters in titles pass through unescaped
- Category: correctness · Severity rank 21 (latent) · **verified** by pandoc repro
- Location: tools/psql_to_md.py:34-42 (`tex_safe`, `cell`), :118, :131
- Evidence: only `\` and `|` are escaped. Repro: `C*-algebra → *NSYNC` → `C\emph{-algebra → }NSYNC`; `$1 coin$` → inline math; `<Foo>` dropped as raw HTML (title lost); `[link](x)` → hyperlink; leading `- ` becomes a nested list; backticks → `\texttt`. PDF builds with exit 0, so the corruption is silent. No such title is in the current philosophy.md.
- Proposed fix: replace `tex_safe` with `md_escape(text)` = `re.sub(r'([\\`*_{}\[\]()#+!$<>~^|-])', r'\\\1', text)` applied to every data string (cells, bullet items, `**key**: value` values, free-text lines) but never to converter-generated markup (`**red**`, `[^deadend]`, headings). Keep the `_` → space mapping before escaping so titles still read naturally. Pandoc renders backslash-escaped punctuation literally.
- Verify: rerun the scratchpad sample `/private/tmp/claude-501/-Users-jayed-repos-wiki-philosophy/b1b8f8b3-d21a-47af-869b-8cf6dbe5c682/scratchpad/meta.txt` through the converter and `pandoc -t latex`; every metacharacter must appear escaped; then `make philosophy.pdf` equivalent on the real philosophy.txt and compare page count.

---

## Cluster M — Makefile (agent: devops)

### Card 3 — `make docs` still walks back to the dump
- Category: correctness · Severity rank 3 (major) · **verified** (`make -n -W src/main.rs pdf` plans cargo build, the parser, and 01_load; missing dump fails docs/stats with "No rule to make target")
- Location: Makefile:105-108 (`docs:`), :44-46 (`$(CSV): $(BIN) $(DUMP)`), :88 (philosophy.txt prerequisites)
- Evidence: docs touches the load/topology stamps and recurses to `pdf`, whose chain is philosophy.pdf → .md → .txt → `$(ST)/articles` → topology stamps → `$(ST)/load` → `$(CSV)` → `$(BIN)` (src/main.rs, Cargo.toml, Cargo.lock) and `$(DUMP)`. An edited src/main.rs or a renamed dump reruns the multi-hour parse and the DROP-and-reload, or fails outright.
- Proposed fix: (a) `ARTICLES_DEP ?= $(ST)/articles` and `philosophy.txt: $(ARTICLES_DEP) sql/...`; `docs:` becomes `rm -f philosophy.txt && $(MAKE) pdf ARTICLES_DEP=` (no stamp touching). (b) `$(CSV): $(BIN) $(wildcard $(DUMP))` so a missing dump is only an error when the CSV must actually be rebuilt (the parser then reports the missing file).
- Verify: `make -n -W src/main.rs docs` shows only the docs recipes; `make -n DUMP=/nonexistent.bz2 docs` and `stats` succeed when the CSV exists.

### Card 4 — a failed parse or stats run leaves a fresh, truncated output
- Category: correctness · Severity rank 4 (major) · confirmed by second-pass audit (panic = "abort" in .cargo/config.toml)
- Location: Makefile (no `.DELETE_ON_ERROR:`), :46 (parser writes to the final `$@`), :88-94 (`{ … } > $@ 2>&1`)
- Evidence: an aborted parser or a failed psql leaves `wiki_edges.csv` / `philosophy.txt` with a new mtime; the next `make` treats them as current and COPYs the truncated CSV.
- Proposed fix: add `.DELETE_ON_ERROR:` near the top. Optionally write `$@.tmp` and `mv` for the two recipes.
- Verify: `make -n` unchanged; simulate with `make philosophy.txt PSQL=false` and confirm no philosophy.txt remains.

### Card 5 — psql errors in report/stats exit 0 and land in the PDF
- Category: correctness · Severity rank 5 · confirmed (this is how the earlier "Incomplete \if" LaTeX failure reached the PDF)
- Location: Makefile:25 (`PSQL ?= psql -X -d $(DB)`)
- Evidence: no `-v ON_ERROR_STOP=1`; 03/04/05/06 scripts do not set it; stderr is merged into philosophy.txt.
- Proposed fix: `PSQL ?= psql -X -v ON_ERROR_STOP=1 -d $(DB)`. Check the scripts still complete: `\gset` on a zero-row result is an error under ON_ERROR_STOP, so card 14's `coalesce` is required and 05_stats's `has_loop` detection must return exactly one row.
- Verify: run `psql -X -v ON_ERROR_STOP=1 -d wiki-phil -v rule=strict -f sql/05_stats.sql` and the other report scripts; all exit 0.

---

## Cluster SA — sql/02_topology.sql, sql/01_load.sql (agent: performance)

### Card 13 — concurrent CREATE OR REPLACE FUNCTION under `make -j`
- Category: correctness · Severity rank 13 · **verified** (scratch DB: 368/1000 and 365/1000 calls failed with "tuple concurrently updated", 4 with a pg_proc unique-index violation)
- Location: sql/02_topology.sql:58-68; Makefile:53-57 (no serialization of topology-% stamps)
- Evidence: each of the five rule runs recreates `strip_leaves`; in parallel they race on the same pg_proc row.
- Proposed fix: move the `CREATE OR REPLACE FUNCTION strip_leaves` (and card 22's frontier version) to sql/01_load.sql, which runs once; 02_topology.sql only calls it. No Makefile change needed.
- Verify: `grep -n strip_leaves sql/*.sql`; run two rules concurrently: `for r in strict loose; do psql -X -v ON_ERROR_STOP=1 -d wiki-phil -v rule=$r -f sql/02_topology.sql & done; wait`.

### Card 22 — strip_leaves is O(rounds × N)
- Category: performance · Severity rank 1 of 5 (major) · **verified**: current 55.7–62.5 s vs frontier 28.9–35.2 s on the 17.1M-row skip_parens set, 189 rounds, identical surviving set (53,512 rows)
- Location: sql/02_topology.sql:58-69
- Evidence: every round is a full-table `DELETE … WHERE NOT EXISTS` inside one transaction; dead tuples accumulate. Benchmark scripts: scratchpad f1.sql, f1b.sql, f1c.sql.
- Proposed fix: frontier strip. Round 1: `DELETE … RETURNING next_id` into a temp frontier table (ids whose in-degree may have dropped). Round k: `DELETE FROM cyc c WHERE c.id IN (SELECT id FROM frontier WHERE r = k-1) AND NOT EXISTS (SELECT 1 FROM cyc d WHERE d.next_id = c.id) RETURNING next_id` into frontier round k. Index `(id)` built after round 1 (round 1 is 14.9 s of the ~30 s; building the id index after it is the next saving). Keep the `(next_id)` index. ~1.8×, saves ~25 s per template-allowing rule.
- Verify: time `SELECT strip_leaves(...)` for skip_parens before/after; `SELECT count(*) FROM cycle_nodes_skip_parens` must stay 53,512.

### Card 23 — PK maintained during the BFS INSERTs
- Category: performance · Severity rank 2 of 5 · **verified**: parens_ok pass-1 INSERT 58.5 s with PK vs 35.3 s + 1.7 s ADD PRIMARY KEY (36% saving, spread < 2%); pass 2a anti-join is a Parallel Hash Anti Join at 1.4 s with or without the index
- Location: sql/02_topology.sql:16 (`page_id INTEGER PRIMARY KEY`)
- Proposed fix: create `:topo` without the PK; after pass 2c add `ALTER TABLE :topo ADD PRIMARY KEY (page_id);` which still asserts visited-once. Make sure the SET enable_hashjoin=off is reset before pass 2a as the script already does.
- Verify: time the three INSERTs for one rule before/after; the ADD PRIMARY KEY must succeed (no duplicates).

### Card 24 — DISTINCT ON sorts 19.3M wide rows to drop 17 duplicates
- Category: performance · Severity rank 3 of 5 · measured 37.6 s in run.log (largest load statement); saving unmeasured
- Location: sql/01_load.sql:35-38
- Proposed fix: find losers with a narrow aggregate and delete them: `DELETE FROM staging_raw r USING (SELECT title, (array_agg(ctid ORDER BY is_redirect, ctid))[1] AS keep FROM staging_raw GROUP BY title HAVING count(*) > 1) d WHERE r.title = d.title AND r.ctid <> d.keep;` then use staging_raw directly (or rename it). Hash aggregate on (title, ctid, is_redirect) only. Time it; keep the DISTINCT ON if the aggregate spills or is not faster.
- Verify: `\timing` on the replaced statement vs 37.6 s; `SELECT count(*) FROM staging_wiki` unchanged (19.3M − 17).

---

## Cluster SB — sql/03_report.sql, sql/06_summary_rule.sql, sql/rule_vars.sql, README.md (agent: general-purpose)

### Card 7 — articles behind an unresolvable redirect are labelled "none"
- Category: correctness · Severity rank 7 · confirmed by cross-check
- Location: sql/01_load.sql:81-103 (final_id NULL when the chain ends on a redirect, > 10 hops, or the target was dropped at src/main.rs:304-306), sql/02_topology.sql:37 (`:col IS NULL` → the article is its own sink), sql/03_report.sql:51 and :60 (`CASE WHEN s.in_dump THEN 'none' ELSE 'red'`)
- Evidence: the article has a first link (its `<rule>_target` is set) but `next_<rule>` is NULL, so it is reported as "page has no qualifying first link". Card 1 adds more redirects to this group.
- Proposed fix (report level, keeps SA disjoint): add `:'rule'||'_target' AS tgt` to sql/rule_vars.sql; in both 03_report.sql queries use `CASE WHEN NOT s.in_dump THEN 'red' WHEN s.:tgt IS NOT NULL THEN 'redirect' ELSE 'none' END`; update the heading text and the dead-end examples/footnote in 06_summary_rule.sql; document the third kind ("redirect: the first link is a redirect that never resolves — a loop, more than 10 hops, or a redirect into another namespace") in README's dead-end/limitations text.
- Verify: `psql -X -d wiki-phil -v rule=strict -f sql/03_report.sql` shows the three kinds; counts sum to the previous dead-end total.

### Card 19 — click bucket label off by one at 30
- Category: correctness · Severity rank 19 · confirmed (philosophy.txt:366-367)
- Location: sql/03_report.sql:23-24
- Evidence: `distance <= 30` gives 30 its own row, then 31–39 are labelled '30-39'.
- Proposed fix: `WHEN t.distance < 30` (30 joins '30-39'), or label the bucket from 31. Update the heading "buckets of 1 up to 30" accordingly.
- Verify: run 03_report.sql for one rule; the row after '29' is '30-39'.

### Card 15 — "(loops without Philosophy)" also labels dead ends and cut-off chains
- Category: correctness · Severity rank 15 (latent) · confirmed
- Location: sql/06_summary_rule.sql:15
- Evidence: the label is applied whenever `bool_or(next_id = :philosophy_id)` is false, which includes a NULL next_id (dead end) and a chain stopped at pos < 50.
- Proposed fix: compute the last row's state: `WHEN bool_or(next_id = :philosophy_id) THEN ' -> Philosophy' WHEN (SELECT next_id FROM chain ORDER BY pos DESC LIMIT 1) IS NULL THEN ' -> (dead end)' WHEN max(pos) >= 50 THEN ' -> ...' ELSE ' -> (back to <title of the revisited node>)'`, matching the cycle-example style already used below it.
- Verify: `psql -X -d wiki-phil -v rule=strict -f sql/06_summary.sql` chain line reads "(back to Existence)".

### Card 6 — README claim about Philosophy's loop is wrong for two rules
- Category: correctness · Severity rank 6 · confirmed against philosophy.txt:112 and :1583
- Location: README.md:255-256
- Evidence: "Under every other rule Philosophy returns to itself in 9 clicks through Ancient Greek." Under skip_parens Philosophy → Existence → Reality (never returns); under skip_italics it returns in 16 clicks. Only parens_ok and loose take 9.
- Proposed fix: "Under parens_ok and loose, Philosophy returns to itself in 9 clicks through Ancient Greek; under skip_italics in 16; under skip_parens it does not return (Philosophy → Existence → Reality → Existence, as under strict)."
- Verify: compare with `grep -n -A1 'Philosophy.s own chain\|== Where Philosophy' philosophy.txt`.

---

## Cluster SC — sql/04_compare.sql, sql/06_summary.sql, sql/05_stats.sql (agent: general-purpose)

### Card 16 — cumulative-share spine is not crossed with rules
- Category: correctness · Severity rank 16 (latent; reachable on MAX_BATCHES subsets) · confirmed
- Location: sql/04_compare.sql:83-94
- Evidence: `d AS (SELECT generate_series(0,35) AS dist)` then `FROM d LEFT JOIN c USING (dist)`; a rule with no article at some distance gets a NULL cell instead of carrying its running total; `coalesce(c.n, 0)` only covers rows where rule is NULL.
- Proposed fix: `d AS (SELECT r.rule, r.ord, g.dist FROM (SELECT DISTINCT rule, ord FROM c) r CROSS JOIN generate_series(0, 35) AS g(dist))`, `FROM d LEFT JOIN c USING (rule, ord, dist)`, window `PARTITION BY d.rule ORDER BY d.dist`.
- Verify: output identical on the full dump (`diff` the section before/after).

### Card 26 — 36M-row TEMP by_rule, never analyzed
- Category: performance · Severity rank 5 of 5 · unquantified (\timing off in the docs stage)
- Location: sql/04_compare.sql:10-15, sql/06_summary.sql:12-17; self-joins at 04_compare.sql:44 and :57
- Evidence: autovacuum skips temp tables, so the self-joins are planned blind; temp_buffers at the 8 MB default.
- Proposed fix: minimum: `ANALYZE by_rule;` after each CREATE TEMP TABLE (cheap). Better: rewrite the "gained/lost" and "clicks compared" queries as FILTER aggregates directly over wiki_articles (its columns are already denormalized), and drop by_rule where no longer referenced.
- Verify: `\timing on` around 04_compare.sql before/after; same numbers.

### Card 14 — `crowded_max` can be NULL and break three queries
- Category: correctness · Severity rank 14 (downgraded in scope) · confirmed
- Location: sql/05_stats.sql:67 (`SELECT max(distance) … \gset`), consumers at :70, :78, ~:90
- Evidence: when no distance has 10+ reaching articles, `\gset` leaves `:crowded_max` unset and the three queries fail with syntax errors; with card 5's ON_ERROR_STOP the whole script would stop.
- Proposed fix: `SELECT coalesce(max(distance), -1) AS crowded_max FROM (…) d \gset`.
- Verify: `psql -X -v ON_ERROR_STOP=1 -d wiki-phil -v rule=strict -f sql/05_stats.sql` exits 0; also with `MAX_BATCHES`-sized data if available.

---

## Cluster V — Coverage gaps (verify-only; subagents edit nothing)

### G1 — Parser pipeline concurrency (agent: rust)
Surface: src/main.rs scanner/worker/writer threads. Inspect: BTreeMap reorder buffer correctness and growth when a batch is slow; behavior when a worker panics under `panic = "abort"` or a channel closes early (hang vs partial CSV vs non-zero exit); `AtomicU64` orderings; channel bound of 64. Report clean-or-findings with file:line.

### G2 — Topology algorithm correctness (agent: general-purpose)
Surface: sql/02_topology.sql pass 2b (cycle canonical id = min member, cycle_len) and pass 2c (BFS from cycle members excluding members and Philosophy); sql/01_load.sql DISTINCT ON tie-break (`is_redirect, ctid`: article wins, then earlier row). Check with live queries: every cycle member's cycle_len equals the member count of its cycle_id; every non-member row's terminal_id is a cycle member; the 17 duplicate titles resolved to the article row.

### G3 — Planner/tuning scope (agent: performance)
Surface: the `SET enable_mergejoin/hashjoin = off` scope in 02_topology.sql (which later statements still run under it), ANALYZE placement between stages (wiki_pages, :topo, :cyc, wiki_articles), recursive working-set growth. Use EXPLAIN on the live database; report plan regressions, not style.

### G4 — Makefile portability (agent: devops)
Surface: Makefile under Xcode's GNU make 3.81 vs Homebrew make 4.x (`$(abspath)`, order-only prerequisites, `.SHELLFLAGS`), `date +%T` and `printf` on Darwin vs GNU, pandoc/xelatex/font availability checks (Arial Unicode MS, Menlo). Report what breaks where.
