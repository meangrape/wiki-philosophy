-- Included by 06_summary.sql once per rule; expects :rule and :philosophy_id.
\echo
\i sql/rule_vars.sql
\echo '################  rule =' :rule '(' :rule_desc ')################'
\echo
\echo '== Where Philosophy itself leads'
WITH RECURSIVE chain AS (
    SELECT p.id, p.:col AS next_id, 0 AS pos, ARRAY[p.id] AS seen FROM wiki_pages p WHERE p.id = :philosophy_id
    UNION ALL
    SELECT p.id, p.:col, c.pos + 1, c.seen || p.id
    FROM chain c JOIN wiki_pages p ON p.id = c.next_id
    WHERE NOT p.id = ANY(c.seen) AND c.pos < 50
)
SELECT string_agg(w.title, ' -> ' ORDER BY c.pos)
       || CASE WHEN (SELECT bool_or(next_id = :philosophy_id) FROM chain) THEN ' -> Philosophy' ELSE ' -> (loops without Philosophy)' END AS chain
FROM chain c JOIN wiki_pages w ON w.id = c.id;

\echo
\echo '== Examples: articles that end in a cycle (random, short chains, common-word titles)'
WITH RECURSIVE ex AS (
    SELECT page_id FROM wiki_articles
    WHERE :tt = 'cycle' AND :td BETWEEN 1 AND 5 AND title ~ '^[A-Z][a-z]{3,12}$'
    ORDER BY random() LIMIT 6
),
walk AS (
    SELECT e.page_id AS start_id, e.page_id AS cur, 0 AS pos, ARRAY[e.page_id] AS seen FROM ex e
    UNION ALL
    SELECT w.start_id, p.:col, w.pos + 1, w.seen || p.:col
    FROM walk w JOIN wiki_pages p ON p.id = w.cur
    WHERE p.:col IS NOT NULL AND NOT p.:col = ANY(w.seen) AND w.pos < 25
),
last AS (
    SELECT DISTINCT ON (w.start_id) w.start_id, p.:col AS back_to
    FROM walk w JOIN wiki_pages p ON p.id = w.cur ORDER BY w.start_id, w.pos DESC
)
SELECT string_agg(t.title, ' -> ' ORDER BY w.pos) || ' -> (back to ' || b.title || ')' AS chain
FROM walk w
JOIN wiki_pages t ON t.id = w.cur
JOIN last l ON l.start_id = w.start_id
JOIN wiki_pages b ON b.id = l.back_to
GROUP BY w.start_id, b.title;

\echo
SELECT :'rule' = 'strict' AS first_pass \gset
\if :first_pass
\echo '== Examples: articles that hit a dead end (random, common-word titles; kinds: red, none[^deadend])'
\echo '[^deadend]: A dead end is a page whose chain stops. **red**: the first link points at a page that does not exist, shown as a red link on Wikipedia. **none**: the page exists but has no qualifying first link, typically a disambiguation page whose links are italicized, or a page whose lead is nothing but templates.'
\else
\echo '== Examples: articles that hit a dead end (random, common-word titles; kinds: red, none)'
\endif
WITH RECURSIVE ex AS (
    SELECT page_id FROM wiki_articles
    WHERE :tt = 'dead_end' AND :td BETWEEN 1 AND 5 AND title ~ '^[A-Z][a-z]{3,12}$'
    ORDER BY random() LIMIT 6
),
walk AS (
    SELECT e.page_id AS start_id, e.page_id AS cur, 0 AS pos FROM ex e
    UNION ALL
    SELECT w.start_id, p.:col, w.pos + 1
    FROM walk w JOIN wiki_pages p ON p.id = w.cur
    WHERE p.:col IS NOT NULL AND w.pos < 25
),
last AS (SELECT DISTINCT ON (start_id) start_id, cur AS sink_id FROM walk ORDER BY start_id, pos DESC)
SELECT string_agg(t.title, ' -> ' ORDER BY w.pos)
       || CASE WHEN s.in_dump THEN ' -> (dead end: none)' ELSE ' -> (dead end: red)' END AS chain
FROM walk w
JOIN wiki_pages t ON t.id = w.cur
JOIN last l ON l.start_id = w.start_id
JOIN wiki_pages s ON s.id = l.sink_id
GROUP BY w.start_id, s.in_dump;
