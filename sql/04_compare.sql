-- Strict rule (parenthesized links skipped) vs parentheses rule, articles only.
-- Requires 02_topology.sql to have run for both rules.
\timing off
\pset footer off

\echo
\echo '== Outcome under each rule (rows: strict, columns: paren)'
SELECT s.terminal_type AS strict_rule, p.terminal_type AS paren_rule,
       count(*) AS articles,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS pct
FROM wiki_topology s
JOIN wiki_topology_paren p USING (page_id)
JOIN wiki_pages w ON w.id = s.page_id
WHERE w.in_dump AND NOT w.is_redirect
GROUP BY 1, 2 ORDER BY 3 DESC;

\echo
\echo '== Articles reaching Philosophy under both rules: clicks compared'
SELECT count(*) AS articles,
       round(avg(s.distance), 2) AS strict_avg_clicks,
       round(avg(p.distance), 2) AS paren_avg_clicks,
       count(*) FILTER (WHERE p.distance < s.distance) AS paren_shorter,
       count(*) FILTER (WHERE p.distance = s.distance) AS same,
       count(*) FILTER (WHERE p.distance > s.distance) AS paren_longer
FROM wiki_topology s
JOIN wiki_topology_paren p USING (page_id)
JOIN wiki_pages w ON w.id = s.page_id
WHERE w.in_dump AND NOT w.is_redirect
  AND s.terminal_type = 'philosophy' AND p.terminal_type = 'philosophy';

\echo
\echo '== How often the two rules pick a different first link'
SELECT count(*) AS articles,
       count(*) FILTER (WHERE first_link_target_id IS DISTINCT FROM paren_link_target_id) AS different_first_link,
       round(100.0 * count(*) FILTER (WHERE first_link_target_id IS DISTINCT FROM paren_link_target_id) / count(*), 2) AS pct
FROM wiki_pages WHERE in_dump AND NOT is_redirect;

\echo
\echo '== Share of articles within N clicks of Philosophy, both rules side by side'
\echo '   (pct_all = share of every article; pct_reaching = share of the articles that reach Philosophy under that rule)'
WITH a AS (SELECT id FROM wiki_pages WHERE in_dump AND NOT is_redirect),
s AS (SELECT t.distance, count(*) AS c FROM wiki_topology t JOIN a ON a.id = t.page_id
      WHERE t.terminal_type = 'philosophy' GROUP BY 1),
p AS (SELECT t.distance, count(*) AS c FROM wiki_topology_paren t JOIN a ON a.id = t.page_id
      WHERE t.terminal_type = 'philosophy' GROUP BY 1),
n AS (SELECT (SELECT count(*) FROM a) AS all_articles,
             (SELECT sum(c) FROM s) AS strict_reaching,
             (SELECT sum(c) FROM p) AS paren_reaching),
d AS (SELECT generate_series(0, 35) AS distance)
SELECT d.distance AS within_clicks,
       round(100.0 * sum(coalesce(s.c, 0)) OVER (ORDER BY d.distance) / n.all_articles, 2)    AS strict_pct_all,
       round(100.0 * sum(coalesce(s.c, 0)) OVER (ORDER BY d.distance) / n.strict_reaching, 2) AS strict_pct_reaching,
       round(100.0 * sum(coalesce(p.c, 0)) OVER (ORDER BY d.distance) / n.all_articles, 2)    AS paren_pct_all,
       round(100.0 * sum(coalesce(p.c, 0)) OVER (ORDER BY d.distance) / n.paren_reaching, 2)  AS paren_pct_reaching
FROM d LEFT JOIN s USING (distance) LEFT JOIN p USING (distance) CROSS JOIN n
ORDER BY 1;

\echo
\echo '== Milestones side by side: clicks needed to cover a share of articles'
WITH a AS (SELECT id FROM wiki_pages WHERE in_dump AND NOT is_redirect),
s AS (SELECT t.distance, count(*) AS c FROM wiki_topology t JOIN a ON a.id = t.page_id
      WHERE t.terminal_type = 'philosophy' GROUP BY 1),
p AS (SELECT t.distance, count(*) AS c FROM wiki_topology_paren t JOIN a ON a.id = t.page_id
      WHERE t.terminal_type = 'philosophy' GROUP BY 1),
n AS (SELECT (SELECT count(*) FROM a) AS all_articles,
             (SELECT sum(c) FROM s) AS strict_reaching,
             (SELECT sum(c) FROM p) AS paren_reaching),
cs AS (SELECT distance, 100.0 * sum(c) OVER (ORDER BY distance) / n.all_articles AS pct_all,
                        100.0 * sum(c) OVER (ORDER BY distance) / n.strict_reaching AS pct_reaching FROM s CROSS JOIN n),
cp AS (SELECT distance, 100.0 * sum(c) OVER (ORDER BY distance) / n.all_articles AS pct_all,
                        100.0 * sum(c) OVER (ORDER BY distance) / n.paren_reaching AS pct_reaching FROM p CROSS JOIN n)
SELECT m.pct AS share_pct,
       (SELECT min(distance) FROM cs WHERE pct_all      >= m.pct) AS strict_all_articles,
       (SELECT min(distance) FROM cs WHERE pct_reaching >= m.pct) AS strict_those_reaching,
       (SELECT min(distance) FROM cp WHERE pct_all      >= m.pct) AS paren_all_articles,
       (SELECT min(distance) FROM cp WHERE pct_reaching >= m.pct) AS paren_those_reaching
FROM (VALUES (10),(25),(35),(50),(75),(90),(95),(99)) m(pct) ORDER BY 1;
