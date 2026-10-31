# Triage ledger — audit-review worktree 2026-10-30

| Card | Cluster | Disposition | Notes |
|---|---|---|---|
| 1 | R | Fix | done in worktree, 10 tests pass
| 8 | R | Fix | done in worktree, 10 tests pass
| 10 | R | Fix | done in worktree, 10 tests pass
| 11 | R | Fix | done in worktree, 10 tests pass
| 17 | R | Fix | done in worktree, 10 tests pass
| 18 | R | Fix | done in worktree, 10 tests pass
| 25 | R | Fix | done in worktree, 10 tests pass
| 27 | R | Fix | done in worktree, 10 tests pass
| 2 | P | Fix | done, 4 checks pass, PDF 40pp
| 9 | P | Fix | done, 4 checks pass, PDF 40pp
| 12 | P | Fix | done, 4 checks pass, PDF 40pp
| 20 | P | Fix | done, 4 checks pass, PDF 40pp
| 21 | P | Fix | done, 4 checks pass, PDF 40pp
| 3 | M | Fix | done, dry runs + psql pass
| 4 | M | Fix | done, dry runs + psql pass
| 5 | M | Fix | done, dry runs + psql pass
| 13 | SA | Fix | done: strip_leaves defined once in 01_load.sql
| 22 | SA | Fix | done: two-table frontier strip, skip_parens 51.4→26.7 s, survivors identical
| 23 | SA | Fix | done: PK after pass 2c; ANALYZE after pass 1 needed (2a 8.4→1.4 s)
| 24 | SA | Not applied | measured: aggregate+DELETE 99–103 s vs DISTINCT ON 37–38 s; DISTINCT ON kept, numbers recorded in a comment
| 7 | SB | Fix | done, strict report+summary verified
| 19 | SB | Fix | done, strict report+summary verified
| 15 | SB | Fix | done, strict report+summary verified
| 6 | SB | Fix | done, strict report+summary verified
| 16 | SC | Fix | done, outputs identical, compare 62→42 s
| 26 | SC | Fix | done, outputs identical, compare 62→42 s
| 14 | SC | Fix | done, outputs identical, compare 62→42 s
| G1 | V | Verified | 3 findings: pending unbounded (467,476); CSV at final path survives abort (417); no completeness check after join (524). bzip2 silent error = card 11. Atomics, memory, joins clean.
| G2 | V | Verified | all 5 checks hold (cycle canon, pass 2c walk 1000/1000, 19,405,021 rows each, dead ends, tie-break by construction)
| G3 | V | Verified | regression: pass 2c enable_hashjoin=off costs 17% (02_topology:92,106); unused 101 MB cycle_nodes next_id index; ANALYZE placement, spill, other indexes clean
| G4 | V | Verified inline | FINDING: Xcode make 3.81 (/usr/bin/make) ignores .SHELLFLAGS, pipefail lost, tee masks failures; gmake 4.4.1 OK. Tools/fonts present; plans identical.
| 28 | M | Fix | done: set -eo pipefail in piped recipes, verified under both makes |
| 29 | R | Fix | done: BATCH_WINDOW=128 credit channel |
| 30 | R | Fix | done: .tmp + rename, batches_sent assertion |
| 31 | SA | Fix | done: pass 2c mergejoin off only; loose 2c 3.1→1.6 s |
| 32 | SA | Index kept | frontier rounds use (next_id) index: 52.9 s with vs 62.5 s without |

## Wrap-up (2026-10-30)

Branch audit-triage/worktree in .worktrees/audit-triage-worktree, from main 5391779. Commits, one per cluster, operator-signed:
- 40b7125 fix(docs): converter handles all five rules and escapes Markdown in titles (P: cards 2, 9, 12, 20, 21)
- 18c73f3 fix(report): third dead-end kind "redirect", bucket label, chain label (SB: 7, 19, 15, 6)
- ead2ed8 perf(compare): single-pass rule comparisons, analyzed temp table (SC: 16, 26, 14)
- 61aca27 fix(parser): correct link selection edge cases and fail loudly on bad input (R: 1, 8, 10, 11, 17, 18, 25, 27, 29, 30)
- f6c3a9f fix(make): docs never walks the pipeline; failures fail the stage (M: 3, 4, 5, 28)
- 0baa226 perf(topology): frontier leaf stripping, PK after the BFS, no per-rule function race (SA: 13, 22, 23, 31; 24 measured and not applied; 32 index kept)
- pending: docs(report): regenerate after the audit fixes (philosophy.txt/md/pdf)

Barrier: cargo test 10/10, cargo build --release clean; `make docs` under Xcode make 3.81 exit 0 in 1:43, 0 psql errors, 12 headings, 0 raw markers, PDF rebuilt. Loose topology rebuilt live with identical counts (19,405,021 classified; cycle 1,003,159 / dead_end 264,783 / philosophy 18,137,079), 60 s -> 38 s.

Gap verification: G1 three findings -> cards 29, 30 fixed, bzip2 silent error = card 11. G2 all five topology checks hold. G3 -> cards 31 fixed, 32 index kept with evidence; ANALYZE placement and spill clean. G4 -> card 28 fixed; tools and fonts present; both makes plan identically.

Not applied: card 24 (DISTINCT ON dedup; replacement measured 2.7x slower, numbers recorded in 01_load.sql). Card 32 (drop next_id index; frontier rounds use it, kept). Ignored: none.

Still to do on main: the strict, parens_ok, skip_parens and skip_italics topologies in wiki-phil were built by the old scripts; a full `make` (parse with the fixed parser, load, topology) is needed for the 24,390 "Word:" titles to take effect in the numbers. The README results snapshot will then need refreshing.

PR: https://github.com/meangrape/wiki-philosophy/pull/1 (audit-triage/worktree -> main, 7 commits, head 1085ad8). Regenerated outputs committed as 1085ad8 docs(report). Raw philosophy.txt artifact: https://claude.ai/artifact/KSArgbJmdDsRAtMT7eyo95
