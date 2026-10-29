# Full pipeline: parse the dump, load Postgres, classify under both rules, report.
#
#   make                 everything (build, parse, load, topology, reports)
#   make parse           just the CSV
#   make load            through the Postgres load
#   make topology        both rules classified
#   make stats           short summary for both rules, with examples
#   make report compare stats-full
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

.PHONY: all build parse load topology report compare stats stats-full clean distclean

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

report: topology
	@for r in $(RULES); do \
	  printf '===== report %s  %s\n' "$$r" "$$(date +%T)" | tee -a $(LOG); \
	  $(PSQL) -v rule=$$r -f sql/03_report.sql 2>&1 | tee -a $(LOG); \
	done

compare: topology
	@printf '===== compare  %s\n' "$$(date +%T)" | tee -a $(LOG)
	$(PSQL) -f sql/04_compare.sql 2>&1 | tee -a $(LOG)

stats: topology
	@printf '===== stats  %s\n' "$$(date +%T)" | tee -a $(LOG)
	$(PSQL) -f sql/06_summary.sql 2>&1 | tee -a $(LOG)

stats-full: topology
	@for r in $(RULES); do \
	  printf '===== stats-full %s  %s\n' "$$r" "$$(date +%T)" | tee -a $(LOG); \
	  $(PSQL) -v rule=$$r -f sql/05_stats.sql 2>&1 | tee -a $(LOG); \
	done

$(ST):
	mkdir -p $@

clean:
	rm -rf $(ST)

distclean: clean
	rm -f $(CSV) $(LOG)
	cargo clean
