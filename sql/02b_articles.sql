-- Articles-only results table: one row per article (in the dump, not a
-- redirect) with the outcome under both rules. Every report reads from this
-- instead of re-joining the 19 M row topology tables to wiki_pages.
\timing on
\set ON_ERROR_STOP on
SET client_min_messages = warning;

DROP TABLE IF EXISTS wiki_articles;
CREATE UNLOGGED TABLE wiki_articles AS
SELECT p.id AS page_id, p.title, p.next_id, p.next_paren_id,
       p.first_link_target_id, p.paren_link_target_id,
       s.terminal_type AS strict_type, s.distance AS strict_dist, s.terminal_id AS strict_terminal,
       q.terminal_type AS paren_type,  q.distance AS paren_dist,  q.terminal_id AS paren_terminal
FROM wiki_pages p
JOIN wiki_topology       s ON s.page_id = p.id
JOIN wiki_topology_paren q ON q.page_id = p.id
WHERE p.in_dump AND NOT p.is_redirect;

ALTER TABLE wiki_articles ADD PRIMARY KEY (page_id);
CREATE INDEX ON wiki_articles (strict_type, strict_dist);
CREATE INDEX ON wiki_articles (paren_type, paren_dist);
ANALYZE wiki_articles;
SELECT count(*) AS articles FROM wiki_articles;
