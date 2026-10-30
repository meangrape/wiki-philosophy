-- Included by the per-rule scripts: turns :rule (default strict) into the
-- column and table names for that rule.
\if :{?rule}
\else
  \set rule strict
\endif
SELECT 'next_' || :'rule'          AS col,
       'wiki_topology_' || :'rule' AS topo,
       'cycle_nodes_' || :'rule'   AS cyc,
       :'rule' || '_type'          AS tt,
       :'rule' || '_dist'          AS td,
       :'rule' || '_terminal'      AS tterm,
       CASE :'rule'
         WHEN 'strict' THEN 'parenthesized, italicized and template links skipped'
         WHEN 'parens_ok'  THEN 'italicized and template links skipped; parenthesized links count'
         WHEN 'skip_parens'     THEN 'only parenthesized links skipped'
         WHEN 'skip_italics'     THEN 'only italicized links skipped'
         WHEN 'loose'     THEN 'only template links skipped (the loose rule)'
       END AS rule_desc \gset
