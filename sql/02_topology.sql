-- Classify every node by where its first-link chain ends, under one rule.
--   psql -d wiki-phil -v rule=strict|parens_ok|skip_parens|skip_italics|loose -f sql/02_topology.sql   (default strict)
-- Out-degree <= 1 (a functional graph): each node ends at Philosophy, at a
-- sink (no link), or in a cycle. Backward BFS from the terminals is a tree
-- walk, so no path arrays are needed and every node is visited once.
\timing on
\set ON_ERROR_STOP on
SET client_min_messages = warning;   -- hide 'does not exist, skipping' notices
\i sql/rule_vars.sql
\echo rule=:rule  column=:col  tables=:topo :cyc

SELECT id AS philosophy_id FROM wiki_pages WHERE title = 'Philosophy' \gset

DROP TABLE IF EXISTS :topo, :cyc;
-- No primary key during the BFS inserts (maintaining it costs ~36% of pass 1);
-- it is added after pass 2c, where it doubles as the "visited once" assertion.
CREATE UNLOGGED TABLE :topo (
    page_id       INTEGER NOT NULL,
    terminal_type TEXT    NOT NULL,      -- 'philosophy' | 'dead_end' | 'cycle'
    terminal_id   INTEGER NOT NULL,      -- Philosophy, the sink, or the cycle's canonical (min id) node
    distance      INTEGER NOT NULL       -- clicks to the terminal; 0 = is the terminal
);

-- The planner cannot estimate the recursive working table and picks a merge
-- join that re-scans the whole index every iteration. A nested loop probing
-- the index per working row is linear in the number of nodes.
SET enable_mergejoin = off;
SET enable_hashjoin  = off;

-- Pass 1: Philosophy and every sink. Philosophy may sit on or feed a cycle,
-- so the walk refuses to step back onto it; sinks cannot be on a cycle.
INSERT INTO :topo
WITH RECURSIVE back AS (
    SELECT id AS page_id,
           CASE WHEN id = :philosophy_id THEN 'philosophy' ELSE 'dead_end' END AS terminal_type,
           id AS terminal_id,
           0  AS distance
    FROM wiki_pages
    WHERE id = :philosophy_id OR :col IS NULL
    UNION ALL
    SELECT p.id, b.terminal_type, b.terminal_id, b.distance + 1
    FROM back b
    JOIN wiki_pages p ON p.:col = b.page_id
    WHERE p.id <> :philosophy_id
)
SELECT page_id, terminal_type, terminal_id, distance FROM back;

RESET enable_mergejoin;
RESET enable_hashjoin;
ANALYZE :topo;   -- without stats (and no PK yet) pass 2a picks a serial hash anti-join, ~6x slower

-- Pass 2a: the rest end in cycles. Unclassified nodes only point at
-- unclassified nodes, so stripping in-degree-0 nodes to a fixpoint leaves
-- exactly the cycle members. strip_leaves is defined once, in sql/01_load.sql,
-- and also builds the (id) index on :cyc used by pass 2b.
CREATE UNLOGGED TABLE :cyc AS
SELECT p.id, p.:col AS next_id
FROM wiki_pages p
WHERE NOT EXISTS (SELECT 1 FROM :topo t WHERE t.page_id = p.id);
CREATE INDEX ON :cyc (next_id);

SELECT strip_leaves(:'cyc') AS leaf_stripping_rounds;

-- Pass 2b: canonical id and length per cycle, by walking each cycle once around.
ALTER TABLE :cyc ADD COLUMN cycle_id INTEGER, ADD COLUMN cycle_len INTEGER;
ANALYZE :cyc;
WITH RECURSIVE walk AS (
    SELECT id AS start_id, next_id AS cur, 1 AS len FROM :cyc
    UNION ALL
    SELECT w.start_id, c.next_id, w.len + 1
    FROM walk w JOIN :cyc c ON c.id = w.cur
    WHERE w.cur <> w.start_id
),
summary AS (
    SELECT start_id, min(cur) AS cycle_id, max(len) AS cycle_len FROM walk GROUP BY start_id
)
UPDATE :cyc c SET cycle_id = s.cycle_id, cycle_len = s.cycle_len
FROM summary s WHERE s.start_id = c.id;

-- Pass 2c: backward BFS from the cycle members, never stepping onto a member
-- nor onto Philosophy, which is already classified and may itself be a tail
-- of another cycle (strict rule: Philosophy -> Existence -> Reality -> Existence).
-- Only merge join is disabled here: the main join stays a nested loop on the
-- next_<rule> index, and the membership test hashes the small :cyc table
-- (Hash Anti Join) instead of probing it once per walked row.
SET enable_mergejoin = off;
INSERT INTO :topo
WITH RECURSIVE back AS (
    SELECT id AS page_id, 'cycle'::text AS terminal_type, cycle_id AS terminal_id, 0 AS distance
    FROM :cyc
    UNION ALL
    SELECT p.id, b.terminal_type, b.terminal_id, b.distance + 1
    FROM back b
    JOIN wiki_pages p ON p.:col = b.page_id
    WHERE p.id <> :philosophy_id
      AND NOT EXISTS (SELECT 1 FROM :cyc c WHERE c.id = p.id)
)
SELECT page_id, terminal_type, terminal_id, distance FROM back;
RESET enable_mergejoin;

ALTER TABLE :topo ADD PRIMARY KEY (page_id);   -- assertion: every node visited once
CREATE INDEX ON :topo (terminal_type, terminal_id);
ANALYZE :topo; ANALYZE :cyc;

-- Assertion: every node classified exactly once.
SELECT :'rule' AS rule,
       (SELECT count(*) FROM wiki_pages) AS nodes,
       (SELECT count(*) FROM :topo) AS classified,
       (SELECT count(*) FROM :cyc) AS cycle_members,
       (SELECT count(DISTINCT cycle_id) FROM :cyc) AS cycles;
