# Full pipeline: parse the dump, load Postgres, classify under all five rules, report.
#
#   make                 everything (build, parse, load, topology, reports)
#   make parse           just the CSV
#   make load            through the Postgres load
#   make topology        all five rules classified
#   make articles        articles-only results table that the reports read
#   make stats           short summary for all five rules, with examples
#   make report compare stats-full
#   make pdf             philosophy.txt / .md / .pdf from the full stats (needs pandoc + xelatex)
#   make docs            regenerate the document from the database as it is: reruns only the
#                        report queries, pandoc and xelatex, never build/parse/load/topology
#   make clean           forget completed stages (keeps the CSV and the database)
#   make distclean       also delete the CSV and the Rust build
#
# Variables: DUMP, DB, PSQL, ARTICLES_DEP. Example: make DUMP=~/dumps/enwiki.xml.bz2 DB=wiki
# Stage completion is tracked with stamp files in .stamps/; a stage reruns when
# its inputs (binary, CSV, SQL file, upstream stamp) are newer than its stamp.
# A missing DUMP is an error only when the CSV itself has to be rebuilt.
# psql runs with ON_ERROR_STOP, so a failing SQL statement fails the stage.
# A recipe that fails deletes its partial target (.DELETE_ON_ERROR).
# Every stage appends its output to run.log.
# GNU make 3.81 (Xcode's /usr/bin/make) ignores .SHELLFLAGS, so recipes that pipe
# into tee, loop, or chain psql calls start with `set -eo pipefail;` themselves;
# a failure then fails the stage under any make. .SHELLFLAGS covers make >= 3.82.

SHELL       := bash
.SHELLFLAGS := -eo pipefail -c
.DELETE_ON_ERROR:

DUMP ?= enwiki-20261001-pages-articles-multistream.xml.bz2
DB   ?= wiki-phil
PSQL ?= psql -X -v ON_ERROR_STOP=1 -d $(DB)
# Upstream prerequisite of philosophy.txt; `make docs` empties it so the
# document is built from the database as it is, without walking the pipeline.
ARTICLES_DEP ?= $(ST)/articles

BIN   := target/release/wiki-philosophy
CSV   := wiki_edges.csv
LOG   := run.log
ST    := .stamps
RULES := strict parens_ok skip_parens skip_italics loose

.PHONY: all build parse load topology articles report compare stats stats-full pdf docs clean distclean

all: report compare stats

build: $(BIN)
$(BIN): src/main.rs Cargo.toml Cargo.lock
	@printf '===== build  %s\n' "$$(date +%T)" | tee -a $(LOG)
	set -eo pipefail; cargo build --release 2>&1 | tee -a $(LOG)

parse: $(CSV)
$(CSV): $(BIN) $(wildcard $(DUMP))
	@printf '===== parse  %s\n' "$$(date +%T)" | tee -a $(LOG)
	set -eo pipefail; OUTPUT_CSV=$@ $(BIN) $(DUMP) 2>&1 | tee -a $(LOG)

load: $(ST)/load
$(ST)/load: $(CSV) sql/01_load.sql | $(ST)
	@printf '===== load  %s\n' "$$(date +%T)" | tee -a $(LOG)
	set -eo pipefail; $(PSQL) -v csv=$(abspath $(CSV)) -f sql/01_load.sql 2>&1 | tee -a $(LOG)
	touch $@

topology: $(RULES:%=$(ST)/topology-%)
$(ST)/topology-%: $(ST)/load sql/02_topology.sql sql/rule_vars.sql
	@printf '===== topology %s  %s\n' "$*" "$$(date +%T)" | tee -a $(LOG)
	set -eo pipefail; $(PSQL) -v rule=$* -f sql/02_topology.sql 2>&1 | tee -a $(LOG)
	touch $@

articles: $(ST)/articles
$(ST)/articles: $(RULES:%=$(ST)/topology-%) sql/02b_articles.sql
	@printf '===== articles  %s\n' "$$(date +%T)" | tee -a $(LOG)
	set -eo pipefail; $(PSQL) -f sql/02b_articles.sql 2>&1 | tee -a $(LOG)
	touch $@

report: articles
	@set -eo pipefail; for r in $(RULES); do \
	  printf '===== report %s  %s\n' "$$r" "$$(date +%T)" | tee -a $(LOG); \
	  $(PSQL) -v rule=$$r -f sql/03_report.sql 2>&1 | tee -a $(LOG); \
	done

compare: articles
	@printf '===== compare  %s\n' "$$(date +%T)" | tee -a $(LOG)
	set -eo pipefail; $(PSQL) -f sql/04_compare.sql 2>&1 | tee -a $(LOG)

stats: articles
	@printf '===== stats  %s\n' "$$(date +%T)" | tee -a $(LOG)
	set -eo pipefail; $(PSQL) -f sql/06_summary.sql 2>&1 | tee -a $(LOG)

stats-full: articles
	@set -eo pipefail; for r in $(RULES); do \
	  printf '===== stats-full %s  %s\n' "$$r" "$$(date +%T)" | tee -a $(LOG); \
	  $(PSQL) -v rule=$$r -f sql/05_stats.sql 2>&1 | tee -a $(LOG); \
	done

pdf: philosophy.pdf
# Runs psql directly rather than recursing into make: a sub-make re-evaluates
# dependencies, so an edit to a SQL file mid-run would restart the load here.
philosophy.txt: $(ARTICLES_DEP) sql/03_report.sql sql/04_compare.sql sql/05_stats.sql sql/06_summary.sql sql/06_summary_rule.sql sql/rule_vars.sql
	@printf '===== docs  %s\n' "$$(date +%T)" | tee -a $(LOG)
	set -e; { printf '===== stats  %s\n' "$$(date +%T)"; $(PSQL) -f sql/06_summary.sql; \
	  printf '===== compare  %s\n' "$$(date +%T)"; $(PSQL) -f sql/04_compare.sql; \
	  for r in $(RULES); do printf '===== report %s  %s\n' "$$r" "$$(date +%T)"; $(PSQL) -v rule=$$r -f sql/03_report.sql; done; \
	  for r in $(RULES); do printf '===== stats-full %s  %s\n' "$$r" "$$(date +%T)"; $(PSQL) -v rule=$$r -f sql/05_stats.sql; done; \
	} > $@ 2>&1
philosophy.md: philosophy.txt tools/psql_to_md.py
	python3 -I tools/psql_to_md.py $< > $@
philosophy.pdf: philosophy.md tools/pagebreaks.lua
	pandoc $< -o $@ --pdf-engine=xelatex --columns=70 --toc --toc-depth=3 \
	  --lua-filter=tools/pagebreaks.lua -V header-includes='\usepackage{needspace}' \
	  -V documentclass=extarticle -V fontsize=9pt -V mainfont="Arial Unicode MS" -V monofont="Menlo" \
	  -V geometry:margin=1.6cm -V colorlinks=true -V linkcolor=black

# Rebuild only the document from the database as it is: the sub-make drops
# philosophy.txt's upstream prerequisite (ARTICLES_DEP=), so the binary, dump,
# CSV, load, topology and articles stages are never considered and no stamp is
# touched. Removing philosophy.txt forces the report queries to rerun.
docs:
	rm -f philosophy.txt
	$(MAKE) pdf ARTICLES_DEP=

$(ST):
	mkdir -p $@

clean:
	rm -rf $(ST)

distclean: clean
	rm -f $(CSV) $(LOG)
	cargo clean
