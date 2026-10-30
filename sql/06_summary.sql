-- Summary for every rule, with examples. Run from the repo root (uses \i).
--   psql -d wiki-phil -f sql/06_summary.sql
\timing off
\pset footer off
-- "3,700,735 (51.1%)": a count with its share of a total.
CREATE OR REPLACE FUNCTION n_pct(n bigint, total bigint) RETURNS text LANGUAGE sql IMMUTABLE AS $$
    SELECT to_char(n, 'FM9,999,999,999') || ' (' || round(100.0 * n / nullif(total, 0), 1) || '%)'
$$;
SELECT id AS philosophy_id FROM wiki_pages WHERE title = 'Philosophy' \gset
SELECT count(*) AS all_articles FROM wiki_articles \gset

CREATE TEMP TABLE by_rule AS
SELECT 'strict' AS rule, 1 AS ord, strict_type AS ttype, strict_dist AS dist FROM wiki_articles
UNION ALL SELECT 'parens_ok', 2, parens_ok_type, parens_ok_dist FROM wiki_articles
UNION ALL SELECT 'skip_parens',    3, skip_parens_type,    skip_parens_dist    FROM wiki_articles
UNION ALL SELECT 'skip_italics',    4, skip_italics_type,    skip_italics_dist    FROM wiki_articles
UNION ALL SELECT 'loose',    5, loose_type,    loose_dist    FROM wiki_articles;

\echo
\echo '== Rules'
\echo '- strict: parenthesized, italicized and template links skipped (Wikipedia''s strict rule)'
\echo '- parens_ok: italicized and template links skipped; parenthesized links count'
\echo '- skip_parens: only parenthesized links skipped'
\echo '- skip_italics: only italicized links skipped'
\echo '- loose: only template links skipped (Wikipedia''s loose rule)'
\echo '  "template" means inside any {{ }} template or {| |} table: infoboxes, hatnotes, navboxes alike.'

\echo
\echo '== Where articles end up (articles = pages in the dump that are not redirects)'
SELECT rule,
       n_pct(count(*) FILTER (WHERE ttype = 'philosophy'), :all_articles) AS philosophy,
       n_pct(count(*) FILTER (WHERE ttype = 'cycle'),      :all_articles) AS cycle,
       n_pct(count(*) FILTER (WHERE ttype = 'dead_end'),   :all_articles) AS "dead end"
FROM by_rule GROUP BY rule, ord ORDER BY ord;

\echo
\echo '== Clicks to Philosophy, over the articles that get there'
SELECT rule,
       n_pct(count(*), :all_articles)                          AS "articles (of all)",
       round(avg(dist), 2)                                     AS mean_clicks,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY dist)       AS median_clicks,
       mode() WITHIN GROUP (ORDER BY dist)                     AS most_common,
       max(dist)                                               AS max_clicks
FROM by_rule WHERE ttype = 'philosophy' GROUP BY rule, ord ORDER BY ord;

\echo
\echo '== Clicks needed to reach Philosophy (blank = that share of all articles never reaches it)'
WITH c AS (SELECT rule, dist, count(*) AS n FROM by_rule WHERE ttype = 'philosophy' GROUP BY 1, 2),
     cum AS (SELECT rule, dist, 100.0 * sum(n) OVER (PARTITION BY rule ORDER BY dist) / :all_articles AS pct FROM c)
SELECT m.pct AS "% of all articles",
       (SELECT min(dist) FROM cum WHERE rule = 'strict' AND pct >= m.pct) AS strict,
       (SELECT min(dist) FROM cum WHERE rule = 'parens_ok'  AND pct >= m.pct) AS parens_ok,
       (SELECT min(dist) FROM cum WHERE rule = 'skip_parens'     AND pct >= m.pct) AS skip_parens,
       (SELECT min(dist) FROM cum WHERE rule = 'skip_italics'     AND pct >= m.pct) AS skip_italics,
       (SELECT min(dist) FROM cum WHERE rule = 'loose'     AND pct >= m.pct) AS loose
FROM (VALUES (10),(25),(50),(75),(90),(95)) m(pct) ORDER BY 1;
DROP TABLE by_rule;

\set rule strict
\i sql/06_summary_rule.sql
\set rule parens_ok
\i sql/06_summary_rule.sql
\set rule skip_parens
\i sql/06_summary_rule.sql
\set rule skip_italics
\i sql/06_summary_rule.sql
\set rule loose
\i sql/06_summary_rule.sql
