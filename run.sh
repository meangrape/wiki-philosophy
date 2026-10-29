#!/usr/bin/env bash
# Full pipeline: parse the dump, load Postgres, classify under both rules, report.
#
#   ./run.sh [dump.xml.bz2] [database]
#
# Defaults: the enwiki dump in this directory, database "wiki-phil".
# Output goes to the terminal and to run.log. Each stage stops the run on error.
set -euo pipefail
cd "$(dirname "$0")"

DUMP=${1:-enwiki-20261001-pages-articles-multistream.xml.bz2}
DB=${2:-wiki-phil}
CSV=$PWD/wiki_edges.csv
LOG=$PWD/run.log

stage() { printf '===== %s  %s\n' "$1" "$(date +%T)" | tee -a "$LOG"; }

: > "$LOG"
stage build
cargo build --release 2>&1 | tee -a "$LOG"

stage parser
./target/release/wiki-philosophy "$DUMP" 2>&1 | tee -a "$LOG"

stage load
psql -X -d "$DB" -v csv="$CSV" -f sql/01_load.sql 2>&1 | tee -a "$LOG"

for rule in strict paren; do
  stage "topology $rule"
  psql -X -d "$DB" -v rule=$rule -f sql/02_topology.sql 2>&1 | tee -a "$LOG"
done

for rule in strict paren; do
  stage "report $rule"
  psql -X -d "$DB" -v rule=$rule -f sql/03_report.sql 2>&1 | tee -a "$LOG"
done

stage compare
psql -X -d "$DB" -f sql/04_compare.sql 2>&1 | tee -a "$LOG"

for rule in strict paren; do
  stage "stats $rule"
  psql -X -d "$DB" -v rule=$rule -f sql/05_stats.sql 2>&1 | tee -a "$LOG"
done

stage done
