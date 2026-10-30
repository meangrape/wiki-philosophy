-- Classify every node by where its first-link chain ends, under one rule.
--   psql -d wiki-phil -v rule=strict -f sql/02_topology.sql   (default)
--   psql -d wiki-phil -v rule=paren  -f sql/02_topology.sql
-- Out-degree <= 1 (a functional graph): each node ends at Philosophy, at a
-- sink (no link), or in a cycle. Backward BFS from the terminals is a tree
-- walk, so no path arrays are needed and every node is visited once.
\timing on
\set ON_ERROR_STOP on
SET client_min_messages = warning;   -- hide 'does not exist, skipping' notices
\if :{?rule}
\else
  \set rule strict
\endif
SELECT :'rule' = 'paren' AS is_paren \gset
\if :is_paren
  \set col  next_paren_id
  \set topo wiki_topology_paren
  \set cyc  cycle_nodes_paren
\else
  \set col  next_id
  \set topo wiki_topology
  \set cyc  cycle_nodes
\endif
\echo rule=:rule  column=:col  tables=:topo :cyc

SELECT id AS philosophy_id FROM wiki_pages WHERE title = 'Philosophy' \gset

DROP TABLE IF EXISTS :topo, :cyc;
CREATE UNLOGGED TABLE :topo (
    page_id       INTEGER PRIMARY KEY,   -- PK doubles as the "visited once" assertion
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

-- Pass 2a: the rest end in cycles. Unclassified nodes only point at
-- unclassified nodes, so stripping in-degree-0 nodes to a fixpoint leaves
-- exactly the cycle members.
CREATE UNLOGGED TABLE :cyc AS
SELECT p.id, p.:col AS next_id
FROM wiki_pages p
WHERE NOT EXISTS (SELECT 1 FROM :topo t WHERE t.page_id = p.id);
CREATE INDEX ON :cyc (next_id);

CREATE OR REPLACE FUNCTION strip_leaves(tbl regclass) RETURNS int LANGUAGE plpgsql AS $$
DECLARE n bigint; rounds int := 0;
BEGIN
  LOOP
    EXECUTE format('DELETE FROM %s c WHERE NOT EXISTS (SELECT 1 FROM %s d WHERE d.next_id = c.id)', tbl, tbl);
    GET DIAGNOSTICS n = ROW_COUNT;
    rounds := rounds + 1;
    EXIT WHEN n = 0;
  END LOOP;
  RETURN rounds;
END $$;
SELECT strip_leaves(:'cyc') AS leaf_stripping_rounds;

-- Pass 2b: canonical id and length per cycle, by walking each cycle once around.
ALTER TABLE :cyc ADD COLUMN cycle_id INTEGER, ADD COLUMN cycle_len INTEGER;
CREATE INDEX ON :cyc (id);
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
SET enable_mergejoin = off;
SET enable_hashjoin  = off;
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
RESET enable_hashjoin;

CREATE INDEX ON :topo (terminal_type, terminal_id);
ANALYZE :topo; ANALYZE :cyc;

-- Assertion: every node classified exactly once.
SELECT :'rule' AS rule,
       (SELECT count(*) FROM wiki_pages) AS nodes,
       (SELECT count(*) FROM :topo) AS classified,
       (SELECT count(*) FROM :cyc) AS cycle_members,
       (SELECT count(DISTINCT cycle_id) FROM :cyc) AS cycles;
