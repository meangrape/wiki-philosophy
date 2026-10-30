-- Load wiki_edges.csv into a normalized page graph.
-- Run from anywhere:  psql -d wiki-phil -v csv=/abs/path/wiki_edges.csv -f sql/01_load.sql
-- Server-side COPY: the postgres process must be able to read :csv.
\timing on
\set ON_ERROR_STOP on
SET client_min_messages = warning;   -- hide 'does not exist, skipping' notices
\if :{?csv}
\else
  \set csv '/Users/jayed/repos/wiki-philosophy/wiki_edges.csv'
\endif

DROP TABLE IF EXISTS wiki_topology, wiki_topology_paren, cycle_nodes, cycle_nodes_paren,
                     wiki_pages, wiki_nodes, staging_wiki, staging_raw;

-- 1. Staging mirrors the CSV exactly. UNLOGGED skips WAL regardless of wal_level.
CREATE UNLOGGED TABLE staging_raw (
    title              TEXT    NOT NULL,
    target_title       TEXT,            -- strict rule: parenthesized links skipped; NULL = none found
    paren_target_title TEXT,            -- parentheses rule: parenthesized links count
    is_redirect        BOOLEAN NOT NULL
);
COPY staging_raw FROM :'csv' WITH (FORMAT csv, HEADER true);

-- A page moved while the dump was written appears twice (article + redirect).
-- One sorted pass keeps one row per title, preferring the article, then the
-- earlier row; cost is the same whether there are 17 duplicates or a million.
CREATE UNLOGGED TABLE staging_wiki AS
SELECT DISTINCT ON (title) title, target_title, paren_target_title, is_redirect
FROM staging_raw
ORDER BY title, is_redirect, ctid;

SELECT (SELECT count(*) FROM staging_raw) AS csv_rows,
       (SELECT count(*) FROM staging_wiki) AS unique_titles,
       (SELECT count(*) FROM staging_raw) - (SELECT count(*) FROM staging_wiki) AS duplicate_rows_dropped;
DROP TABLE staging_raw;
CREATE UNIQUE INDEX staging_wiki_title_idx ON staging_wiki (title);  -- assertion
ANALYZE staging_wiki;

-- 2. Nodes: every dump page, plus every link target (either rule) that is not
--    a dump page (red links, titles missing from this dump). Ids assigned once.
CREATE UNLOGGED TABLE wiki_nodes AS
SELECT row_number() OVER (ORDER BY title)::int AS id, title, in_dump, is_redirect
FROM (
    SELECT title, true AS in_dump, is_redirect FROM staging_wiki
    UNION ALL
    SELECT DISTINCT t.title, false, false
    FROM (SELECT target_title AS title FROM staging_wiki
          UNION ALL
          SELECT paren_target_title FROM staging_wiki) t
    WHERE t.title IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM staging_wiki s WHERE s.title = t.title)
) n;
CREATE UNIQUE INDEX wiki_nodes_title_idx ON wiki_nodes (title);
ANALYZE wiki_nodes;

-- 3. Final table: raw first links under both rules, and next_id / next_paren_id
--    with redirect chains collapsed (up to 10 hops; a chain still ending on a
--    redirect becomes a dead end).
CREATE TABLE wiki_pages AS
WITH RECURSIVE raw AS (
    SELECT n.id, n.title, n.in_dump, n.is_redirect,
           ts.id AS first_link_target_id,
           tp.id AS paren_link_target_id
    FROM wiki_nodes n
    LEFT JOIN staging_wiki s ON s.title = n.title
    LEFT JOIN wiki_nodes ts ON ts.title = s.target_title
    LEFT JOIN wiki_nodes tp ON tp.title = s.paren_target_title
),
hop_s AS (
    SELECT r.id, r.first_link_target_id AS next_id, 0 AS hops FROM raw r
    UNION ALL
    SELECT h.id, r.first_link_target_id, h.hops + 1
    FROM hop_s h JOIN raw r ON r.id = h.next_id
    WHERE r.is_redirect AND h.hops < 10
),
hop_p AS (
    SELECT r.id, r.paren_link_target_id AS next_id, 0 AS hops FROM raw r
    UNION ALL
    SELECT h.id, r.paren_link_target_id, h.hops + 1
    FROM hop_p h JOIN raw r ON r.id = h.next_id
    WHERE r.is_redirect AND h.hops < 10
),
res_s AS (
    SELECT DISTINCT ON (h.id) h.id,
           CASE WHEN t.is_redirect THEN NULL ELSE h.next_id END AS next_id,
           h.hops
    FROM hop_s h LEFT JOIN raw t ON t.id = h.next_id
    ORDER BY h.id, h.hops DESC
),
res_p AS (
    SELECT DISTINCT ON (h.id) h.id,
           CASE WHEN t.is_redirect THEN NULL ELSE h.next_id END AS next_id,
           h.hops
    FROM hop_p h LEFT JOIN raw t ON t.id = h.next_id
    ORDER BY h.id, h.hops DESC
)
SELECT r.id, r.title, r.in_dump, r.is_redirect,
       r.first_link_target_id, r.paren_link_target_id,
       s.next_id, s.hops AS redirect_hops,
       p.next_id AS next_paren_id
FROM raw r
JOIN res_s s USING (id)
JOIN res_p p USING (id);

ALTER TABLE wiki_pages ADD PRIMARY KEY (id);
CREATE UNIQUE INDEX wiki_pages_title_idx      ON wiki_pages (title);
CREATE INDEX        wiki_pages_next_idx       ON wiki_pages (next_id);
CREATE INDEX        wiki_pages_next_paren_idx ON wiki_pages (next_paren_id);
ANALYZE wiki_pages;

DROP TABLE wiki_nodes, staging_wiki;

SELECT count(*)                                              AS nodes,
       count(*) FILTER (WHERE in_dump)                       AS dump_pages,
       count(*) FILTER (WHERE in_dump AND NOT is_redirect)   AS articles,
       count(*) FILTER (WHERE is_redirect)                   AS redirects,
       count(*) FILTER (WHERE NOT in_dump)                   AS red_links,
       count(*) FILTER (WHERE in_dump AND NOT is_redirect AND next_id IS NULL)       AS articles_without_link,
       count(*) FILTER (WHERE in_dump AND NOT is_redirect AND next_paren_id IS NULL) AS articles_without_paren_link,
       count(*) FILTER (WHERE in_dump AND NOT is_redirect
                          AND first_link_target_id IS DISTINCT FROM paren_link_target_id) AS articles_where_rules_differ
FROM wiki_pages;
