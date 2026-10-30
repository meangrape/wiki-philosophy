-- Strict rule (parenthesized links skipped) vs parentheses rule, articles only.
-- Requires 02_topology.sql to have run for both rules.
\timing off
\pset footer off
-- "3,700,735 (51.1%)": a count with its share of a total.
CREATE OR REPLACE FUNCTION n_pct(n bigint, total bigint) RETURNS text LANGUAGE sql IMMUTABLE AS $$
    SELECT to_char(n, 'FM9,999,999,999') || ' (' || round(100.0 * n / nullif(total, 0), 1) || '%)'
$$;

\echo
\echo '== Outcome under each rule, articles: rows = strict rule, columns = parentheses rule'
WITH j AS (SELECT strict_type AS strict, paren_type AS paren FROM wiki_articles)
SELECT coalesce(strict, 'total') AS "strict ↓  paren →",
       count(*) FILTER (WHERE paren = 'philosophy') AS philosophy,
       count(*) FILTER (WHERE paren = 'cycle')      AS cycle,
       count(*) FILTER (WHERE paren = 'dead_end')   AS "dead end",
       count(*)                                     AS total
FROM j GROUP BY ROLLUP (strict)
ORDER BY strict IS NULL, array_position(ARRAY['philosophy','cycle','dead_end'], strict);

\echo
\echo '== Same, as percent of all articles'
WITH j AS (SELECT strict_type AS strict, paren_type AS paren FROM wiki_articles),
n AS (SELECT count(*) AS total FROM j)
SELECT coalesce(strict, 'total') AS "strict ↓  paren →",
       round(100.0 * count(*) FILTER (WHERE paren = 'philosophy') / n.total, 2) AS philosophy,
       round(100.0 * count(*) FILTER (WHERE paren = 'cycle')      / n.total, 2) AS cycle,
       round(100.0 * count(*) FILTER (WHERE paren = 'dead_end')   / n.total, 2) AS "dead end",
       round(100.0 * count(*)                                     / n.total, 2) AS total
FROM j CROSS JOIN n GROUP BY ROLLUP (strict), n.total
ORDER BY strict IS NULL, array_position(ARRAY['philosophy','cycle','dead_end'], strict);

\echo
\echo '== Articles reaching Philosophy under both rules: clicks compared'
SELECT n_pct(count(*), (SELECT count(*) FROM wiki_articles)) AS "articles (of all)",
       round(avg(strict_dist), 2) AS strict_avg_clicks,
       round(avg(paren_dist), 2)  AS paren_avg_clicks,
       n_pct(count(*) FILTER (WHERE paren_dist < strict_dist), count(*)) AS paren_shorter,
       n_pct(count(*) FILTER (WHERE paren_dist = strict_dist), count(*)) AS same,
       n_pct(count(*) FILTER (WHERE paren_dist > strict_dist), count(*)) AS paren_longer
FROM wiki_articles
WHERE strict_type = 'philosophy' AND paren_type = 'philosophy';

\echo
\echo '== How often the two rules pick a different first link'
SELECT count(*) AS articles,
       n_pct(count(*) FILTER (WHERE first_link_target_id IS DISTINCT FROM paren_link_target_id), count(*)) AS different_first_link
FROM wiki_articles;

\echo
\echo '== Cumulative share of articles within N clicks of Philosophy, both rules'
\echo '   (denominator: all articles, or only the articles that reach Philosophy under that rule)'
WITH s AS (SELECT strict_dist AS distance, count(*) AS c FROM wiki_articles WHERE strict_type = 'philosophy' GROUP BY 1),
p AS (SELECT paren_dist AS distance, count(*) AS c FROM wiki_articles WHERE paren_type = 'philosophy' GROUP BY 1),
n AS (SELECT (SELECT count(*) FROM wiki_articles) AS all_articles,
             (SELECT sum(c) FROM s) AS strict_reaching,
             (SELECT sum(c) FROM p) AS paren_reaching),
d AS (SELECT generate_series(0, 35) AS distance)
SELECT d.distance AS within_clicks,
       round(100.0 * sum(coalesce(s.c, 0)) OVER (ORDER BY d.distance) / n.all_articles, 2)    AS "strict, % of all",
       round(100.0 * sum(coalesce(s.c, 0)) OVER (ORDER BY d.distance) / n.strict_reaching, 2) AS "strict, % of reaching",
       round(100.0 * sum(coalesce(p.c, 0)) OVER (ORDER BY d.distance) / n.all_articles, 2)    AS "paren, % of all",
       round(100.0 * sum(coalesce(p.c, 0)) OVER (ORDER BY d.distance) / n.paren_reaching, 2)  AS "paren, % of reaching"
FROM d LEFT JOIN s USING (distance) LEFT JOIN p USING (distance) CROSS JOIN n
ORDER BY 1;

\echo
\echo '== Clicks needed to reach Philosophy, by share of articles: all articles vs. only those that reach it (blank = never)'
WITH s AS (SELECT strict_dist AS distance, count(*) AS c FROM wiki_articles WHERE strict_type = 'philosophy' GROUP BY 1),
p AS (SELECT paren_dist AS distance, count(*) AS c FROM wiki_articles WHERE paren_type = 'philosophy' GROUP BY 1),
n AS (SELECT (SELECT count(*) FROM wiki_articles) AS all_articles,
             (SELECT sum(c) FROM s) AS strict_reaching,
             (SELECT sum(c) FROM p) AS paren_reaching),
cs AS (SELECT distance, 100.0 * sum(c) OVER (ORDER BY distance) / n.all_articles AS pct_all,
                        100.0 * sum(c) OVER (ORDER BY distance) / n.strict_reaching AS pct_reaching FROM s CROSS JOIN n),
cp AS (SELECT distance, 100.0 * sum(c) OVER (ORDER BY distance) / n.all_articles AS pct_all,
                        100.0 * sum(c) OVER (ORDER BY distance) / n.paren_reaching AS pct_reaching FROM p CROSS JOIN n)
SELECT m.pct AS "% of articles",
       (SELECT min(distance) FROM cs WHERE pct_all      >= m.pct) AS "strict, all articles",
       (SELECT min(distance) FROM cs WHERE pct_reaching >= m.pct) AS "strict, those reaching",
       (SELECT min(distance) FROM cp WHERE pct_all      >= m.pct) AS "paren, all articles",
       (SELECT min(distance) FROM cp WHERE pct_reaching >= m.pct) AS "paren, those reaching"
FROM (VALUES (10),(25),(35),(50),(75),(90),(95),(99)) m(pct) ORDER BY 1;
