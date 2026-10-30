# Full pipeline: parse the dump, load Postgres, classify under both rules, report.
#
#   make                 everything (build, parse, load, topology, reports)
#   make parse           just the CSV
#   make load            through the Postgres load
#   make topology        both rules classified
#   make articles        articles-only results table that the reports read
#   make stats           short summary for both rules, with examples
#   make report compare stats-full
#   make pdf             philosophy.txt / .md / .pdf from the full stats (needs pandoc + xelatex)
#   make docs            regenerate the document from the database as it is, skipping load/topology
#   make clean           forget completed stages (keeps the CSV and the database)
#   make distclean       also delete the CSV and the Rust build
#
# Variables: DUMP, DB, PSQL. Example: make DUMP=~/dumps/enwiki.xml.bz2 DB=wiki
# Stage completion is tracked with stamp files in .stamps/; a stage reruns when
# its inputs (binary, CSV, SQL file, upstream stamp) are newer than its stamp.
# Every stage appends its output to run.log.

SHELL       := bash
.SHELLFLAGS := -eo pipefail -c

DUMP ?= enwiki-20261001-pages-articles-multistream.xml.bz2
DB   ?= wiki-phil
PSQL ?= psql -X -d $(DB)

BIN   := target/release/wiki-philosophy
CSV   := wiki_edges.csv
LOG   := run.log
ST    := .stamps
RULES := strict paren

.PHONY: all build parse load topology articles report compare stats stats-full pdf docs clean distclean

all: report compare stats

build: $(BIN)
$(BIN): src/main.rs Cargo.toml Cargo.lock
	@printf '===== build  %s\n' "$$(date +%T)" | tee -a $(LOG)
	cargo build --release 2>&1 | tee -a $(LOG)

parse: $(CSV)
$(CSV): $(BIN) $(DUMP)
	@printf '===== parse  %s\n' "$$(date +%T)" | tee -a $(LOG)
	OUTPUT_CSV=$@ $(BIN) $(DUMP) 2>&1 | tee -a $(LOG)

load: $(ST)/load
$(ST)/load: $(CSV) sql/01_load.sql | $(ST)
	@printf '===== load  %s\n' "$$(date +%T)" | tee -a $(LOG)
	$(PSQL) -v csv=$(abspath $(CSV)) -f sql/01_load.sql 2>&1 | tee -a $(LOG)
	touch $@

topology: $(RULES:%=$(ST)/topology-%)
$(ST)/topology-%: $(ST)/load sql/02_topology.sql
	@printf '===== topology %s  %s\n' "$*" "$$(date +%T)" | tee -a $(LOG)
	$(PSQL) -v rule=$* -f sql/02_topology.sql 2>&1 | tee -a $(LOG)
	touch $@

articles: $(ST)/articles
$(ST)/articles: $(RULES:%=$(ST)/topology-%) sql/02b_articles.sql
	@printf '===== articles  %s\n' "$$(date +%T)" | tee -a $(LOG)
	$(PSQL) -f sql/02b_articles.sql 2>&1 | tee -a $(LOG)
	touch $@

report: articles
	@for r in $(RULES); do \
	  printf '===== report %s  %s\n' "$$r" "$$(date +%T)" | tee -a $(LOG); \
	  $(PSQL) -v rule=$$r -f sql/03_report.sql 2>&1 | tee -a $(LOG); \
	done

compare: articles
	@printf '===== compare  %s\n' "$$(date +%T)" | tee -a $(LOG)
	$(PSQL) -f sql/04_compare.sql 2>&1 | tee -a $(LOG)

stats: articles
	@printf '===== stats  %s\n' "$$(date +%T)" | tee -a $(LOG)
	$(PSQL) -f sql/06_summary.sql 2>&1 | tee -a $(LOG)

stats-full: articles
	@for r in $(RULES); do \
	  printf '===== stats-full %s  %s\n' "$$r" "$$(date +%T)" | tee -a $(LOG); \
	  $(PSQL) -v rule=$$r -f sql/05_stats.sql 2>&1 | tee -a $(LOG); \
	done

pdf: philosophy.pdf
# Runs psql directly rather than recursing into make: a sub-make re-evaluates
# dependencies, so an edit to a SQL file mid-run would restart the load here.
philosophy.txt: $(ST)/articles sql/03_report.sql sql/04_compare.sql sql/05_stats.sql sql/06_summary.sql sql/06_summary_rule.sql
	@printf '===== docs  %s\n' "$$(date +%T)" | tee -a $(LOG)
	{ printf '===== stats  %s\n' "$$(date +%T)"; $(PSQL) -f sql/06_summary.sql; \
	  printf '===== compare  %s\n' "$$(date +%T)"; $(PSQL) -f sql/04_compare.sql; \
	  for r in $(RULES); do printf '===== report %s  %s\n' "$$r" "$$(date +%T)"; $(PSQL) -v rule=$$r -f sql/03_report.sql; done; \
	  for r in $(RULES); do printf '===== stats-full %s  %s\n' "$$r" "$$(date +%T)"; $(PSQL) -v rule=$$r -f sql/05_stats.sql; done; \
	} > $@ 2>&1
philosophy.md: philosophy.txt tools/psql_to_md.py
	python3 -I tools/psql_to_md.py $< > $@
philosophy.pdf: philosophy.md tools/pagebreaks.lua
	pandoc $< -o $@ --pdf-engine=xelatex --columns=70 --toc --toc-depth=3 \
	  --lua-filter=tools/pagebreaks.lua -V header-includes='\usepackage{needspace}' \
	  -V documentclass=extarticle -V fontsize=9pt -V mainfont="Arial" -V monofont="Menlo" \
	  -V geometry:margin=1.6cm -V colorlinks=true -V linkcolor=black

# Rebuild only the document: treat the load and topology stamps as current,
# whatever the SQL file timestamps say, and force the stats to rerun.
docs:
	mkdir -p $(ST) && touch $(ST)/load $(RULES:%=$(ST)/topology-%)
	rm -f philosophy.txt
	$(MAKE) pdf

$(ST):
	mkdir -p $@

clean:
	rm -rf $(ST)

distclean: clean
	rm -f $(CSV) $(LOG)
	cargo clean
