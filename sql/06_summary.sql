-- Summary for both rules, with examples. Run from the repo root (uses \i).
--   psql -d wiki-phil -f sql/06_summary.sql
\timing off
\pset footer off
SELECT id AS philosophy_id FROM wiki_pages WHERE title = 'Philosophy' \gset

\echo
\echo '== Where articles end up (articles = pages in the dump that are not redirects)'
WITH a AS (SELECT id FROM wiki_pages WHERE in_dump AND NOT is_redirect),
u AS (
    SELECT 'strict' AS rule, t.terminal_type, t.distance FROM wiki_topology t JOIN a ON a.id = t.page_id
    UNION ALL
    SELECT 'paren', t.terminal_type, t.distance FROM wiki_topology_paren t JOIN a ON a.id = t.page_id
),
n AS (SELECT count(*) AS total FROM a)
SELECT terminal_type,
       count(*) FILTER (WHERE rule = 'strict')                                  AS strict_articles,
       round(100.0 * count(*) FILTER (WHERE rule = 'strict') / n.total, 2)     AS strict_pct,
       count(*) FILTER (WHERE rule = 'paren')                                   AS paren_articles,
       round(100.0 * count(*) FILTER (WHERE rule = 'paren') / n.total, 2)      AS paren_pct
FROM u CROSS JOIN n GROUP BY 1, n.total ORDER BY 2 DESC;

\echo
\echo '== Clicks to Philosophy, over the articles that get there'
WITH a AS (SELECT id FROM wiki_pages WHERE in_dump AND NOT is_redirect),
u AS (
    SELECT 'strict' AS rule, t.distance FROM wiki_topology t JOIN a ON a.id = t.page_id WHERE t.terminal_type = 'philosophy'
    UNION ALL
    SELECT 'paren', t.distance FROM wiki_topology_paren t JOIN a ON a.id = t.page_id WHERE t.terminal_type = 'philosophy'
)
SELECT rule, count(*) AS articles,
       round(avg(distance), 2)                                   AS mean_clicks,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY distance)     AS median_clicks,
       mode() WITHIN GROUP (ORDER BY distance)                   AS most_common,
       max(distance)                                             AS max_clicks
FROM u GROUP BY rule ORDER BY rule DESC;

\echo
\echo '== Clicks needed to cover a share of ALL articles (blank = never reached)'
WITH a AS (SELECT id FROM wiki_pages WHERE in_dump AND NOT is_redirect),
n AS (SELECT count(*) AS total FROM a),
s AS (SELECT t.distance, count(*) AS c FROM wiki_topology t JOIN a ON a.id = t.page_id WHERE t.terminal_type = 'philosophy' GROUP BY 1),
p AS (SELECT t.distance, count(*) AS c FROM wiki_topology_paren t JOIN a ON a.id = t.page_id WHERE t.terminal_type = 'philosophy' GROUP BY 1),
cs AS (SELECT distance, 100.0 * sum(c) OVER (ORDER BY distance) / n.total AS pct FROM s CROSS JOIN n),
cp AS (SELECT distance, 100.0 * sum(c) OVER (ORDER BY distance) / n.total AS pct FROM p CROSS JOIN n)
SELECT m.pct AS share_of_all_articles,
       (SELECT min(distance) FROM cs WHERE pct >= m.pct) AS strict_clicks,
       (SELECT min(distance) FROM cp WHERE pct >= m.pct) AS paren_clicks
FROM (VALUES (10),(25),(50),(75),(90),(95)) m(pct) ORDER BY 1;

\set rule strict
\set col next_id
\set topo wiki_topology
\i sql/06_summary_rule.sql

\set rule paren
\set col next_paren_id
\set topo wiki_topology_paren
\i sql/06_summary_rule.sql
