-- Distance statistics for one rule:  psql -d wiki-phil -v rule=strict|parens_ok|skip_parens|skip_italics|loose -f sql/05_stats.sql
-- Articles only (in the dump, not redirects).
\timing off
\pset footer off
\i sql/rule_vars.sql
SELECT id AS philosophy_id FROM wiki_pages WHERE title = 'Philosophy' \gset

\echo
\echo '################  rule =' :rule '(' :rule_desc ')################'

-- Articles that reach Philosophy, with distance, reused below.
CREATE TEMP TABLE reach AS
SELECT page_id, :td AS distance, title FROM wiki_articles WHERE :tt = 'philosophy';
CREATE INDEX ON reach (distance);
SELECT count(*) AS all_articles FROM wiki_articles \gset
SELECT count(*) AS reaching FROM reach \gset

\echo
\echo '== Cumulative share of articles within N clicks of Philosophy'
SELECT distance AS within_clicks,
       count(*) AS at_this_distance,
       sum(count(*)) OVER (ORDER BY distance) AS cumulative,
       round(100.0 * sum(count(*)) OVER (ORDER BY distance) / :all_articles, 2) AS pct_of_all_articles,
       round(100.0 * sum(count(*)) OVER (ORDER BY distance) / :reaching, 2)     AS pct_of_those_reaching
FROM reach GROUP BY distance ORDER BY distance LIMIT 35;

\echo
\echo '== Clicks needed to reach Philosophy, by share of articles (blank = never)'
WITH cum AS (
    SELECT distance,
           100.0 * sum(count(*)) OVER (ORDER BY distance) / :all_articles AS pct_all,
           100.0 * sum(count(*)) OVER (ORDER BY distance) / :reaching     AS pct_reaching
    FROM reach GROUP BY distance
)
SELECT m.pct AS "% of articles",
       (SELECT min(distance) FROM cum WHERE pct_all      >= m.pct) AS "clicks, all articles",
       (SELECT min(distance) FROM cum WHERE pct_reaching >= m.pct) AS "clicks, those reaching"
FROM (VALUES (10),(25),(35),(50),(75),(90),(95),(99)) m(pct) ORDER BY 1;

WITH RECURSIVE chain AS (
    SELECT p.id, p.:col AS next_id, 1 AS pos FROM wiki_pages p WHERE p.id = :philosophy_id
    UNION ALL
    SELECT p.id, p.:col, c.pos + 1 FROM chain c JOIN wiki_pages p ON p.id = c.next_id
    WHERE p.id <> :philosophy_id AND c.pos < 100
)
SELECT coalesce(max(pos) FILTER (WHERE next_id = :philosophy_id), -1) AS loop_clicks,
       coalesce(max(pos) FILTER (WHERE next_id = :philosophy_id), -1) > 0 AS has_loop
FROM chain \gset

\if :has_loop
\echo
\echo '== Philosophy returns to itself in' :loop_clicks 'clicks under this rule. Articles exactly that far from Philosophy (single common-word titles, random 40)'
SELECT title, distance FROM reach
WHERE distance = :loop_clicks AND title ~ '^[A-Z][a-z]{2,10}$'
ORDER BY random() LIMIT 40;
\endif

\echo
\echo '== Farthest chain heads (no other article links into them)'
SELECT r.title, r.distance
FROM reach r
WHERE NOT EXISTS (SELECT 1 FROM wiki_pages q WHERE q.:col = r.page_id AND q.in_dump AND NOT q.is_redirect)
ORDER BY r.distance DESC, r.title LIMIT 10;

\echo
\echo '== Farthest chain heads outside the single-file tail (distances still shared by 10+ articles)'
SELECT max(distance) AS crowded_max FROM (SELECT distance FROM reach GROUP BY distance HAVING count(*) >= 10) d \gset
SELECT r.title, r.distance
FROM reach r
WHERE r.distance <= :crowded_max
  AND NOT EXISTS (SELECT 1 FROM wiki_pages q WHERE q.:col = r.page_id AND q.in_dump AND NOT q.is_redirect)
ORDER BY r.distance DESC, r.title LIMIT 10;

\echo
\echo '== Single-file tails: chains that own the far distances, and where they rejoin the crowd'
WITH RECURSIVE heads AS (
    SELECT r.page_id, r.title, r.distance FROM reach r
    WHERE r.distance > :crowded_max
      AND NOT EXISTS (SELECT 1 FROM wiki_pages q WHERE q.:col = r.page_id AND q.in_dump AND NOT q.is_redirect)
),
walk AS (
    SELECT h.page_id AS head_id, h.title AS head, h.distance AS head_distance,
           h.page_id AS cur_id, p.:col AS next_id, 1 AS steps
    FROM heads h JOIN wiki_pages p ON p.id = h.page_id
    UNION ALL
    SELECT w.head_id, w.head, w.head_distance, p.id, p.:col, w.steps + 1
    FROM walk w
    JOIN wiki_pages p ON p.id = w.next_id
    JOIN :topo t ON t.page_id = p.id
    WHERE t.distance > :crowded_max
),
tail AS (
    SELECT DISTINCT ON (head_id) head_id, head, head_distance, steps AS chain_pages, next_id AS junction_id
    FROM walk ORDER BY head_id, steps DESC
)
SELECT tl.head, tl.head_distance,
       tl.chain_pages                                           AS pages_in_single_file,
       (SELECT w.title FROM walk x JOIN wiki_pages w ON w.id = x.cur_id
         WHERE x.head_id = tl.head_id AND x.steps = tl.chain_pages / 2) AS midpoint_page,
       j.title                                                  AS rejoins_crowd_at,
       jt.distance                                              AS crowd_distance
FROM tail tl
JOIN wiki_pages j ON j.id = tl.junction_id
JOIN :topo jt ON jt.page_id = j.id
ORDER BY tl.head_distance DESC LIMIT 10;

\echo
\echo '== Counts at 1, 2, 3 clicks'
SELECT distance, count(*) FROM reach WHERE distance BETWEEN 1 AND 3 GROUP BY 1 ORDER BY 1;

\echo
\echo '== One click: first link is Philosophy, common-word titles that are not obviously philosophical (random 30)'
SELECT title FROM reach
WHERE distance = 1
  AND title ~ '^[A-Z][a-z]+(_[a-z]+)*$'
  AND title !~* '(philosoph|ethic|logic|metaphys|epistem|ontolog|aesthetic|ism$|ist$|theor|idealis|realis|school|thought|concept|doctrine|rational|empiric|skeptic|dialectic)'
ORDER BY random() LIMIT 30;

\echo
\echo '== Two clicks, single common-word titles with their path (random 30)'
SELECT r.title || ' -> ' || n.title || ' -> Philosophy' AS path
FROM reach r
JOIN wiki_pages p ON p.id = r.page_id
JOIN wiki_pages n ON n.id = p.:col
WHERE r.distance = 2 AND r.title ~ '^[A-Z][a-z]{2,12}$'
  AND r.title !~* '(philosoph|ethic|logic|metaphys|epistem|ontolog|aesthetic|ism$|ist$|theor)'
ORDER BY random() LIMIT 30;

DROP TABLE reach;
