-- Reports for one rule:  psql -d wiki-phil -v rule=strict|paren -f sql/03_report.sql
-- "Articles" = pages in the dump that are not redirects; red-link targets and
-- redirects are graph nodes but are excluded from percentages.
\timing off
\pset footer off
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

\echo
\echo '################  rule =' :rule '################'
\echo
\echo '== Where do articles end up?'
SELECT t.terminal_type,
       count(*)                                           AS articles,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS pct,
       round(avg(t.distance), 2)                          AS avg_clicks,
       max(t.distance)                                    AS max_clicks
FROM :topo t JOIN wiki_pages p ON p.id = t.page_id
WHERE p.in_dump AND NOT p.is_redirect
GROUP BY 1 ORDER BY 2 DESC;

\echo
\echo '== Clicks-to-Philosophy distribution (buckets of 1 up to 30, then 10)'
SELECT CASE WHEN t.distance <= 30 THEN t.distance::text
            ELSE (t.distance / 10 * 10)::text || '-' || (t.distance / 10 * 10 + 9)::text END AS clicks,
       min(t.distance) AS sort_key, count(*) AS articles
FROM :topo t JOIN wiki_pages p ON p.id = t.page_id
WHERE t.terminal_type = 'philosophy' AND p.in_dump AND NOT p.is_redirect
GROUP BY 1 ORDER BY 2;

\echo
\echo '== Longest roads to Philosophy'
SELECT p.title, t.distance AS clicks
FROM :topo t JOIN wiki_pages p ON p.id = t.page_id
WHERE t.terminal_type = 'philosophy' AND p.in_dump AND NOT p.is_redirect
ORDER BY t.distance DESC, p.title LIMIT 10;

\echo
\echo '== Where Philosophy itself leads (chain until a node repeats)'
WITH RECURSIVE chain AS (
    SELECT p.id, p.:col AS next_id, 0 AS pos, ARRAY[p.id] AS seen FROM wiki_pages p WHERE p.title = 'Philosophy'
    UNION ALL
    SELECT p.id, p.:col, c.pos + 1, c.seen || p.id
    FROM chain c JOIN wiki_pages p ON p.id = c.next_id
    WHERE NOT p.id = ANY(c.seen) AND c.pos < 50
)
SELECT string_agg(w.title, ' -> ' ORDER BY c.pos) AS chain
FROM chain c JOIN wiki_pages w ON w.id = c.id;

\echo
\echo '== Biggest dead ends: in_dump=f is a red link, in_dump=t is an article with no qualifying first link'
SELECT s.title AS sink, s.in_dump, count(*) AS articles_ending_here
FROM :topo t
JOIN wiki_pages p ON p.id = t.page_id
JOIN wiki_pages s ON s.id = t.terminal_id
WHERE t.terminal_type = 'dead_end' AND p.in_dump AND NOT p.is_redirect
GROUP BY 1, 2 ORDER BY 3 DESC LIMIT 15;

\echo
\echo '== Dead-end causes, by sink kind'
SELECT s.in_dump AS sink_is_article, count(DISTINCT s.id) AS sinks, count(*) AS articles_trapped
FROM :topo t
JOIN wiki_pages p ON p.id = t.page_id
JOIN wiki_pages s ON s.id = t.terminal_id
WHERE t.terminal_type = 'dead_end' AND p.in_dump AND NOT p.is_redirect
GROUP BY 1;

\echo
\echo '== Biggest cycles'
WITH RECURSIVE ring AS (
    SELECT c.cycle_id, c.id, c.next_id, 0 AS pos
    FROM :cyc c WHERE c.id = c.cycle_id
    UNION ALL
    SELECT r.cycle_id, c.id, c.next_id, r.pos + 1
    FROM ring r JOIN :cyc c ON c.id = r.next_id
    WHERE c.id <> r.cycle_id AND r.pos < 12
),
trapped AS (
    SELECT t.terminal_id AS cycle_id, count(*) AS articles
    FROM :topo t JOIN wiki_pages p ON p.id = t.page_id
    WHERE t.terminal_type = 'cycle' AND p.in_dump AND NOT p.is_redirect
    GROUP BY 1
)
SELECT tr.articles, c.cycle_len,
       (SELECT string_agg(w.title, ' -> ' ORDER BY r.pos)
          FROM ring r JOIN wiki_pages w ON w.id = r.id WHERE r.cycle_id = tr.cycle_id)
       || CASE WHEN c.cycle_len > 13 THEN ' -> ...' ELSE '' END AS loop
FROM trapped tr JOIN :cyc c ON c.id = tr.cycle_id
ORDER BY tr.articles DESC LIMIT 10;
