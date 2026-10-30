-- Summary for both rules, with examples. Run from the repo root (uses \i).
--   psql -d wiki-phil -f sql/06_summary.sql
\timing off
\pset footer off
-- "3,700,735 (51.1%)": a count with its share of a total.
CREATE OR REPLACE FUNCTION n_pct(n bigint, total bigint) RETURNS text LANGUAGE sql IMMUTABLE AS $$
    SELECT to_char(n, 'FM9,999,999,999') || ' (' || round(100.0 * n / nullif(total, 0), 1) || '%)'
$$;
SELECT id AS philosophy_id FROM wiki_pages WHERE title = 'Philosophy' \gset

\echo
\echo '== Where articles end up (articles = pages in the dump that are not redirects)'
WITH u AS (
    SELECT 'strict' AS rule, strict_type AS terminal_type FROM wiki_articles
    UNION ALL
    SELECT 'paren', paren_type FROM wiki_articles
),
n AS (SELECT count(*) AS total FROM wiki_articles)
SELECT terminal_type,
       n_pct(count(*) FILTER (WHERE rule = 'strict'), n.total) AS "strict rule",
       n_pct(count(*) FILTER (WHERE rule = 'paren'),  n.total) AS "parentheses rule"
FROM u CROSS JOIN n GROUP BY 1, n.total ORDER BY count(*) FILTER (WHERE rule = 'strict') DESC;

\echo
\echo '== Clicks to Philosophy, over the articles that get there'
WITH u AS (
    SELECT 'strict' AS rule, strict_dist AS distance FROM wiki_articles WHERE strict_type = 'philosophy'
    UNION ALL
    SELECT 'paren', paren_dist FROM wiki_articles WHERE paren_type = 'philosophy'
)
SELECT rule,
       n_pct(count(*), (SELECT count(*) FROM wiki_articles)) AS "articles (of all)",
       round(avg(distance), 2)                                   AS mean_clicks,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY distance)     AS median_clicks,
       mode() WITHIN GROUP (ORDER BY distance)                   AS most_common,
       max(distance)                                             AS max_clicks
FROM u GROUP BY rule ORDER BY rule DESC;

\echo
\echo '== Clicks needed to reach Philosophy (blank = that share of articles never reaches it)'
WITH n AS (SELECT count(*) AS total FROM wiki_articles),
s AS (SELECT strict_dist AS distance, count(*) AS c FROM wiki_articles WHERE strict_type = 'philosophy' GROUP BY 1),
p AS (SELECT paren_dist AS distance, count(*) AS c FROM wiki_articles WHERE paren_type = 'philosophy' GROUP BY 1),
cs AS (SELECT distance, 100.0 * sum(c) OVER (ORDER BY distance) / n.total AS pct FROM s CROSS JOIN n),
cp AS (SELECT distance, 100.0 * sum(c) OVER (ORDER BY distance) / n.total AS pct FROM p CROSS JOIN n)
SELECT m.pct AS "% of all articles",
       (SELECT min(distance) FROM cs WHERE pct >= m.pct) AS "strict clicks",
       (SELECT min(distance) FROM cp WHERE pct >= m.pct) AS "paren clicks"
FROM (VALUES (10),(25),(50),(75),(90),(95)) m(pct) ORDER BY 1;

\set rule strict
\set col next_id
\set tt strict_type
\set td strict_dist
\i sql/06_summary_rule.sql

\set rule paren
\set col next_paren_id
\set tt paren_type
\set td paren_dist
\i sql/06_summary_rule.sql
