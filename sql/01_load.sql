-- Load wiki_edges.csv into a normalized page graph, one next_<rule> column per rule.
-- Run from anywhere:  psql -d wiki-phil -v csv=/abs/path/wiki_edges.csv -f sql/01_load.sql
-- Server-side COPY: the postgres process must be able to read :csv.
\timing on
\set ON_ERROR_STOP on
SET client_min_messages = warning;   -- hide 'does not exist, skipping' notices
\if :{?csv}
\else
  \set csv '/Users/jayed/repos/wiki-philosophy/wiki_edges.csv'
\endif

-- Drop everything downstream, whatever rules a previous run used.
DO $$ DECLARE t text; BEGIN
  FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
            AND (tablename LIKE 'wiki_topology%' OR tablename LIKE 'cycle_nodes%'
                 OR tablename IN ('wiki_articles','wiki_pages','wiki_nodes','wiki_raw','redirect_final','staging_wiki','staging_raw'))
  LOOP EXECUTE format('DROP TABLE %I', t); END LOOP;
END $$;

-- 1. Staging mirrors the CSV exactly. UNLOGGED skips WAL regardless of wal_level.
CREATE UNLOGGED TABLE staging_raw (
    title               TEXT    NOT NULL,
    strict_target_title TEXT,   -- parenthesized, italicized and template links skipped
    parens_ok_target_title  TEXT,   -- italicized and template links skipped
    skip_parens_target_title     TEXT,   -- only parenthesized links skipped
    skip_italics_target_title     TEXT,   -- only italicized links skipped
    loose_target_title     TEXT,   -- only template links skipped (the loose rule)
    is_redirect         BOOLEAN NOT NULL
);
COPY staging_raw FROM :'csv' WITH (FORMAT csv, HEADER true);

-- A page moved while the dump was written appears twice (article + redirect).
-- One sorted pass keeps one row per title, preferring the article, then the
-- earlier row; cost is the same whether there are 17 duplicates or a million.
CREATE UNLOGGED TABLE staging_wiki AS
SELECT DISTINCT ON (title) *
FROM staging_raw
ORDER BY title, is_redirect, ctid;

SELECT (SELECT count(*) FROM staging_raw) AS csv_rows,
       (SELECT count(*) FROM staging_wiki) AS unique_titles,
       (SELECT count(*) FROM staging_raw) - (SELECT count(*) FROM staging_wiki) AS duplicate_rows_dropped;
DROP TABLE staging_raw;
CREATE UNIQUE INDEX staging_wiki_title_idx ON staging_wiki (title);  -- assertion
ANALYZE staging_wiki;

-- 2. Nodes: every dump page, plus every link target (under any rule) that is
--    not a dump page (red links, titles missing from this dump). Ids assigned once.
CREATE UNLOGGED TABLE wiki_nodes AS
SELECT row_number() OVER (ORDER BY title)::int AS id, title, in_dump, is_redirect
FROM (
    SELECT title, true AS in_dump, is_redirect FROM staging_wiki
    UNION ALL
    SELECT DISTINCT t.title, false, false
    FROM staging_wiki s,
         unnest(ARRAY[s.strict_target_title, s.parens_ok_target_title, s.skip_parens_target_title,
                      s.skip_italics_target_title, s.loose_target_title]) AS t(title)
    WHERE t.title IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM staging_wiki x WHERE x.title = t.title)
) n;
CREATE UNIQUE INDEX wiki_nodes_title_idx ON wiki_nodes (title);
ANALYZE wiki_nodes;

-- 3. Raw first-link target ids per rule.
CREATE UNLOGGED TABLE wiki_raw AS
SELECT n.id, n.title, n.in_dump, n.is_redirect,
       t1.id AS strict_target, t2.id AS parens_ok_target, t3.id AS skip_parens_target, t4.id AS skip_italics_target, t5.id AS loose_target
FROM wiki_nodes n
LEFT JOIN staging_wiki s ON s.title = n.title
LEFT JOIN wiki_nodes t1 ON t1.title = s.strict_target_title
LEFT JOIN wiki_nodes t2 ON t2.title = s.parens_ok_target_title
LEFT JOIN wiki_nodes t3 ON t3.title = s.skip_parens_target_title
LEFT JOIN wiki_nodes t4 ON t4.title = s.skip_italics_target_title
LEFT JOIN wiki_nodes t5 ON t5.title = s.loose_target_title;
ALTER TABLE wiki_raw ADD PRIMARY KEY (id);
ANALYZE wiki_raw;

-- 4. Where each redirect finally lands (up to 10 hops; a chain still ending
--    on a redirect resolves to NULL, i.e. a dead end). A redirect's target is
--    the same under every rule, so one map serves all of them.
CREATE UNLOGGED TABLE redirect_final AS
WITH RECURSIVE hop AS (
    SELECT r.id, r.strict_target AS cur, 0 AS hops FROM wiki_raw r WHERE r.is_redirect
    UNION ALL
    SELECT h.id, r.strict_target, h.hops + 1
    FROM hop h JOIN wiki_raw r ON r.id = h.cur
    WHERE r.is_redirect AND h.hops < 10
),
last AS (SELECT DISTINCT ON (id) id, cur, hops FROM hop ORDER BY id, hops DESC)
SELECT l.id, CASE WHEN f.is_redirect THEN NULL ELSE l.cur END AS final_id, l.hops
FROM last l LEFT JOIN wiki_raw f ON f.id = l.cur;
ALTER TABLE redirect_final ADD PRIMARY KEY (id);
ANALYZE redirect_final;

-- 5. Final table: raw targets and redirect-collapsed next_<rule> per rule.
CREATE TABLE wiki_pages AS
SELECT r.id, r.title, r.in_dump, r.is_redirect,
       r.strict_target, r.parens_ok_target, r.skip_parens_target, r.skip_italics_target, r.loose_target,
       CASE WHEN f1.id IS NOT NULL THEN f1.final_id ELSE r.strict_target END AS next_strict,
       CASE WHEN f2.id IS NOT NULL THEN f2.final_id ELSE r.parens_ok_target  END AS next_parens_ok,
       CASE WHEN f3.id IS NOT NULL THEN f3.final_id ELSE r.skip_parens_target     END AS next_skip_parens,
       CASE WHEN f4.id IS NOT NULL THEN f4.final_id ELSE r.skip_italics_target     END AS next_skip_italics,
       CASE WHEN f5.id IS NOT NULL THEN f5.final_id ELSE r.loose_target     END AS next_loose
FROM wiki_raw r
LEFT JOIN redirect_final f1 ON f1.id = r.strict_target
LEFT JOIN redirect_final f2 ON f2.id = r.parens_ok_target
LEFT JOIN redirect_final f3 ON f3.id = r.skip_parens_target
LEFT JOIN redirect_final f4 ON f4.id = r.skip_italics_target
LEFT JOIN redirect_final f5 ON f5.id = r.loose_target;

ALTER TABLE wiki_pages ADD PRIMARY KEY (id);
CREATE UNIQUE INDEX wiki_pages_title_idx ON wiki_pages (title);
CREATE INDEX wiki_pages_next_strict_idx ON wiki_pages (next_strict);
CREATE INDEX wiki_pages_next_paren_idx  ON wiki_pages (next_parens_ok);
CREATE INDEX wiki_pages_next_r1_idx     ON wiki_pages (next_skip_parens);
CREATE INDEX wiki_pages_next_r2_idx     ON wiki_pages (next_skip_italics);
CREATE INDEX wiki_pages_next_r3_idx     ON wiki_pages (next_loose);
ANALYZE wiki_pages;

DROP TABLE wiki_raw, redirect_final, wiki_nodes, staging_wiki;

SELECT count(*)                                            AS nodes,
       count(*) FILTER (WHERE in_dump)                     AS dump_pages,
       count(*) FILTER (WHERE in_dump AND NOT is_redirect) AS articles,
       count(*) FILTER (WHERE is_redirect)                 AS redirects,
       count(*) FILTER (WHERE NOT in_dump)                 AS red_links
FROM wiki_pages;
SELECT 'articles without a link' AS measure,
       count(*) FILTER (WHERE next_strict IS NULL) AS strict,
       count(*) FILTER (WHERE next_parens_ok  IS NULL) AS parens_ok,
       count(*) FILTER (WHERE next_skip_parens     IS NULL) AS skip_parens,
       count(*) FILTER (WHERE next_skip_italics     IS NULL) AS skip_italics,
       count(*) FILTER (WHERE next_loose     IS NULL) AS loose
FROM wiki_pages WHERE in_dump AND NOT is_redirect;
