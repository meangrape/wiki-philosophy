-- Articles-only results table: one row per article (in the dump, not a
-- redirect) with the outcome under every rule. Reports read this instead of
-- re-joining the 19 M row topology tables to wiki_pages.
\timing on
\set ON_ERROR_STOP on
SET client_min_messages = warning;

DROP TABLE IF EXISTS wiki_articles;
CREATE UNLOGGED TABLE wiki_articles AS
SELECT p.id AS page_id, p.title,
       p.next_strict, p.next_parens_ok, p.next_skip_parens, p.next_skip_italics, p.next_loose,
       p.strict_target, p.parens_ok_target, p.skip_parens_target, p.skip_italics_target, p.loose_target,
       ts.terminal_type AS strict_type, ts.distance AS strict_dist, ts.terminal_id AS strict_terminal,
       tp.terminal_type AS parens_ok_type,  tp.distance AS parens_ok_dist,  tp.terminal_id AS parens_ok_terminal,
       t1.terminal_type AS skip_parens_type,     t1.distance AS skip_parens_dist,     t1.terminal_id AS skip_parens_terminal,
       t2.terminal_type AS skip_italics_type,     t2.distance AS skip_italics_dist,     t2.terminal_id AS skip_italics_terminal,
       t3.terminal_type AS loose_type,     t3.distance AS loose_dist,     t3.terminal_id AS loose_terminal
FROM wiki_pages p
JOIN wiki_topology_strict ts ON ts.page_id = p.id
JOIN wiki_topology_parens_ok  tp ON tp.page_id = p.id
JOIN wiki_topology_skip_parens     t1 ON t1.page_id = p.id
JOIN wiki_topology_skip_italics     t2 ON t2.page_id = p.id
JOIN wiki_topology_loose     t3 ON t3.page_id = p.id
WHERE p.in_dump AND NOT p.is_redirect;

ALTER TABLE wiki_articles ADD PRIMARY KEY (page_id);
CREATE INDEX ON wiki_articles (strict_type, strict_dist);
CREATE INDEX ON wiki_articles (parens_ok_type, parens_ok_dist);
CREATE INDEX ON wiki_articles (skip_parens_type, skip_parens_dist);
CREATE INDEX ON wiki_articles (skip_italics_type, skip_italics_dist);
CREATE INDEX ON wiki_articles (loose_type, loose_dist);
ANALYZE wiki_articles;
SELECT count(*) AS articles FROM wiki_articles;
