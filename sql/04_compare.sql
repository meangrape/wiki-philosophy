-- Every rule against the strict rule, articles only. Requires 02b_articles.sql.
\timing off
\pset footer off
-- "3,700,735 (51.1%)": a count with its share of a total.
CREATE OR REPLACE FUNCTION n_pct(n bigint, total bigint) RETURNS text LANGUAGE sql IMMUTABLE AS $$
    SELECT to_char(n, 'FM9,999,999,999') || ' (' || round(100.0 * n / nullif(total, 0), 1) || '%)'
$$;

-- One row per (rule, article) for the per-rule aggregate queries below.
-- Temp tables are never autovacuumed, so ANALYZE by hand or the planner works blind.
CREATE TEMP TABLE by_rule AS
SELECT 'strict' AS rule, 1 AS ord, strict_type AS ttype, strict_dist AS dist FROM wiki_articles
UNION ALL SELECT 'parens_ok',    2, parens_ok_type,    parens_ok_dist    FROM wiki_articles
UNION ALL SELECT 'skip_parens',  3, skip_parens_type,  skip_parens_dist  FROM wiki_articles
UNION ALL SELECT 'skip_italics', 4, skip_italics_type, skip_italics_dist FROM wiki_articles
UNION ALL SELECT 'loose',        5, loose_type,        loose_dist        FROM wiki_articles;
ANALYZE by_rule;
SELECT count(*) AS all_articles FROM wiki_articles \gset

\echo
\echo '== Rules'
\echo '- strict: parenthesized, italicized and template links skipped (Wikipedia''s strict rule)'
\echo '- parens_ok: italicized and template links skipped; parenthesized links count'
\echo '- skip_parens: only parenthesized links skipped'
\echo '- skip_italics: only italicized links skipped'
\echo '- loose: only template links skipped (Wikipedia''s loose rule)'
\echo '  "template" means inside any {{ }} template or {| |} table: infoboxes, hatnotes, navboxes alike.'

\echo
\echo '== Where articles end up, by rule'
SELECT rule,
       n_pct(count(*) FILTER (WHERE ttype = 'philosophy'), :all_articles) AS philosophy,
       n_pct(count(*) FILTER (WHERE ttype = 'cycle'),      :all_articles) AS cycle,
       n_pct(count(*) FILTER (WHERE ttype = 'dead_end'),   :all_articles) AS "dead end",
       round(avg(dist) FILTER (WHERE ttype = 'philosophy'), 2)            AS "mean clicks (reaching)",
       max(dist) FILTER (WHERE ttype = 'philosophy')                      AS "max clicks"
FROM by_rule GROUP BY rule, ord ORDER BY ord;

\echo
\echo '== Each rule against strict: how often the first link differs, and how outcomes move'
-- One pass over wiki_articles: each article unnests into one row per non-strict rule.
SELECT r.rule,
       n_pct(count(*) FILTER (WHERE r.target IS DISTINCT FROM a.strict_target), :all_articles) AS "different first link",
       n_pct(count(*) FILTER (WHERE a.strict_type = 'philosophy' AND r.ttype = 'philosophy'), :all_articles) AS "philosophy under both",
       n_pct(count(*) FILTER (WHERE a.strict_type <> 'philosophy' AND r.ttype = 'philosophy'), :all_articles) AS "gained philosophy",
       n_pct(count(*) FILTER (WHERE a.strict_type = 'philosophy' AND r.ttype <> 'philosophy'), :all_articles) AS "lost philosophy"
FROM wiki_articles a
CROSS JOIN LATERAL (VALUES ('parens_ok',    2, a.parens_ok_type,    a.parens_ok_dist,    a.parens_ok_target),
                           ('skip_parens',  3, a.skip_parens_type,  a.skip_parens_dist,  a.skip_parens_target),
                           ('skip_italics', 4, a.skip_italics_type, a.skip_italics_dist, a.skip_italics_target),
                           ('loose',        5, a.loose_type,        a.loose_dist,        a.loose_target)) r(rule, ord, ttype, dist, target)
GROUP BY r.rule, r.ord ORDER BY r.ord;

\echo
\echo '== Articles reaching Philosophy under both strict and the rule: clicks compared'
SELECT r.rule,
       n_pct(count(*), :all_articles)                       AS "articles (of all)",
       round(avg(a.strict_dist), 2)                         AS "strict avg clicks",
       round(avg(r.dist), 2)                                AS "rule avg clicks",
       n_pct(count(*) FILTER (WHERE r.dist < a.strict_dist), count(*)) AS shorter,
       n_pct(count(*) FILTER (WHERE r.dist = a.strict_dist), count(*)) AS same,
       n_pct(count(*) FILTER (WHERE r.dist > a.strict_dist), count(*)) AS longer
FROM wiki_articles a
CROSS JOIN LATERAL (VALUES ('parens_ok',    2, a.parens_ok_type,    a.parens_ok_dist,    a.parens_ok_target),
                           ('skip_parens',  3, a.skip_parens_type,  a.skip_parens_dist,  a.skip_parens_target),
                           ('skip_italics', 4, a.skip_italics_type, a.skip_italics_dist, a.skip_italics_target),
                           ('loose',        5, a.loose_type,        a.loose_dist,        a.loose_target)) r(rule, ord, ttype, dist, target)
WHERE a.strict_type = 'philosophy' AND r.ttype = 'philosophy'
GROUP BY r.rule, r.ord ORDER BY r.ord;

\echo
\echo '== Outcome under strict (rows) vs parens_ok (columns), percent of all articles'
SELECT coalesce(strict_type, 'total') AS "strict ↓  parens_ok →",
       round(100.0 * count(*) FILTER (WHERE parens_ok_type = 'philosophy') / :all_articles, 2) AS philosophy,
       round(100.0 * count(*) FILTER (WHERE parens_ok_type = 'cycle')      / :all_articles, 2) AS cycle,
       round(100.0 * count(*) FILTER (WHERE parens_ok_type = 'dead_end')   / :all_articles, 2) AS "dead end",
       round(100.0 * count(*)                                          / :all_articles, 2) AS total
FROM wiki_articles GROUP BY ROLLUP (strict_type)
ORDER BY strict_type IS NULL, array_position(ARRAY['philosophy','cycle','dead_end'], strict_type);

\echo
\echo '== Outcome under strict (rows) vs loose (columns), percent of all articles'
SELECT coalesce(strict_type, 'total') AS "strict ↓  loose →",
       round(100.0 * count(*) FILTER (WHERE loose_type = 'philosophy') / :all_articles, 2) AS philosophy,
       round(100.0 * count(*) FILTER (WHERE loose_type = 'cycle')      / :all_articles, 2) AS cycle,
       round(100.0 * count(*) FILTER (WHERE loose_type = 'dead_end')   / :all_articles, 2) AS "dead end",
       round(100.0 * count(*)                                       / :all_articles, 2) AS total
FROM wiki_articles GROUP BY ROLLUP (strict_type)
ORDER BY strict_type IS NULL, array_position(ARRAY['philosophy','cycle','dead_end'], strict_type);

\echo
\echo '== Cumulative share of ALL articles within N clicks of Philosophy, by rule'
WITH c AS (SELECT rule, ord, dist, count(*) AS n FROM by_rule WHERE ttype = 'philosophy' GROUP BY 1, 2, 3),
     -- Every rule crossed with every distance, so a rule with no article at some
     -- distance still carries its running total through that row.
     d AS (SELECT r.rule, r.ord, g.dist
           FROM (SELECT DISTINCT rule, ord FROM c) r CROSS JOIN generate_series(0, 35) AS g(dist)),
     cum AS (SELECT d.rule, d.ord, d.dist,
                    100.0 * sum(coalesce(c.n, 0)) OVER (PARTITION BY d.rule ORDER BY d.dist) / :all_articles AS pct
             FROM d LEFT JOIN c USING (rule, ord, dist))
SELECT dist AS within_clicks,
       round(max(pct) FILTER (WHERE rule = 'strict'), 2) AS strict,
       round(max(pct) FILTER (WHERE rule = 'parens_ok'), 2)  AS parens_ok,
       round(max(pct) FILTER (WHERE rule = 'skip_parens'), 2)     AS skip_parens,
       round(max(pct) FILTER (WHERE rule = 'skip_italics'), 2)     AS skip_italics,
       round(max(pct) FILTER (WHERE rule = 'loose'), 2)     AS loose
FROM cum GROUP BY dist ORDER BY dist;

\echo
\echo '== Clicks needed to reach Philosophy, by share of ALL articles (blank = never)'
WITH c AS (SELECT rule, dist, count(*) AS n FROM by_rule WHERE ttype = 'philosophy' GROUP BY 1, 2),
     cum AS (SELECT rule, dist, 100.0 * sum(n) OVER (PARTITION BY rule ORDER BY dist) / :all_articles AS pct FROM c)
SELECT m.pct AS "% of all articles",
       (SELECT min(dist) FROM cum WHERE rule = 'strict' AND pct >= m.pct) AS strict,
       (SELECT min(dist) FROM cum WHERE rule = 'parens_ok'  AND pct >= m.pct) AS parens_ok,
       (SELECT min(dist) FROM cum WHERE rule = 'skip_parens'     AND pct >= m.pct) AS skip_parens,
       (SELECT min(dist) FROM cum WHERE rule = 'skip_italics'     AND pct >= m.pct) AS skip_italics,
       (SELECT min(dist) FROM cum WHERE rule = 'loose'     AND pct >= m.pct) AS loose
FROM (VALUES (10),(25),(50),(75),(90),(95),(99)) m(pct) ORDER BY 1;

\echo
\echo '== Clicks needed to reach Philosophy, by share of the articles that REACH it under the rule'
WITH c AS (SELECT rule, dist, count(*) AS n FROM by_rule WHERE ttype = 'philosophy' GROUP BY 1, 2),
     cum AS (SELECT rule, dist, 100.0 * sum(n) OVER (PARTITION BY rule ORDER BY dist) / sum(n) OVER (PARTITION BY rule) AS pct FROM c)
SELECT m.pct AS "% of those reaching",
       (SELECT min(dist) FROM cum WHERE rule = 'strict' AND pct >= m.pct) AS strict,
       (SELECT min(dist) FROM cum WHERE rule = 'parens_ok'  AND pct >= m.pct) AS parens_ok,
       (SELECT min(dist) FROM cum WHERE rule = 'skip_parens'     AND pct >= m.pct) AS skip_parens,
       (SELECT min(dist) FROM cum WHERE rule = 'skip_italics'     AND pct >= m.pct) AS skip_italics,
       (SELECT min(dist) FROM cum WHERE rule = 'loose'     AND pct >= m.pct) AS loose
FROM (VALUES (10),(25),(50),(75),(90),(95),(99)) m(pct) ORDER BY 1;
DROP TABLE by_rule;
