---
title: "Wiki-philosophy: first-link statistics"
---

# Summary

### A. Rules

- strict: parenthesized, italicized and template links skipped \(Wikipedia's strict rule\)

- parens\_ok: italicized and template links skipped; parenthesized links count

- skip\_parens: only parenthesized links skipped

- skip\_italics: only italicized links skipped

- loose: only template links skipped \(Wikipedia's loose rule\)

"template" means inside any \{\{ \}\} template or \{\| \|\} table: infoboxes, hatnotes, navboxes alike.

### B. Where articles end up

::: note
*(articles = pages in the dump that are not redirects)*
:::

| rule | philosophy | cycle | dead end |
|---|---:|---:|---:|
| strict | 3,736,703 \(51.5%\) | 3,438,431 \(47.4%\) | 73,964 \(1.0%\) |
| parens ok | 6,873,610 \(94.8%\) | 306,074 \(4.2%\) | 69,414 \(1.0%\) |
| skip parens | 567,977 \(7.8%\) | 6,502,846 \(89.7%\) | 178,275 \(2.5%\) |
| skip italics | 1,190,490 \(16.4%\) | 5,884,261 \(81.2%\) | 174,347 \(2.4%\) |
| loose | 6,875,315 \(94.8%\) | 314,361 \(4.3%\) | 59,422 \(0.8%\) |

### C. Clicks to Philosophy, over the articles that get there

| rule | articles \(of all\) | mean clicks | median clicks | most common | max clicks |
|---|---:|---:|---:|---:|---:|
| strict | 3,736,703 \(51.5%\) | 15.17 | 16 | 16 | 201 |
| parens ok | 6,873,610 \(94.8%\) | 14.13 | 15 | 16 | 201 |
| skip parens | 567,977 \(7.8%\) | 13.67 | 13 | 7 | 45 |
| skip italics | 1,190,490 \(16.4%\) | 14.77 | 14 | 7 | 55 |
| loose | 6,875,315 \(94.8%\) | 14.04 | 14 | 16 | 201 |

### D. Clicks needed to reach Philosophy

::: note
*(blank = that share of all articles never reaches it)*
:::

| % of all articles | strict | parens ok | skip parens | skip italics | loose |
|---:|---:|---:|---|---:|---:|
| 10 | 10 | 9 |  | 17 | 8 |
| 25 | 16 | 11 |  |  | 11 |
| 50 | 25 | 15 |  |  | 15 |
| 75 |  | 17 |  |  | 17 |
| 90 |  | 21 |  |  | 21 |
| 95 |  |  |  |  |  |

## I. Rule: strict (parenthesized, italicized and template links are skipped)

### A. Where Philosophy itself leads

- Philosophy → Existence → Reality → \(back to Existence\)

### B. Examples: articles that end in a cycle

::: note
*(random, short chains, common-word titles)*
:::

- Blastodesmia → Monotypic taxon → Biology → Scientific study → Knowledge → Belief → Attitude \(psychology\) → Psychology → Mind → Thought → Cognition → \(back to Knowledge\)
- Rheumatology → Inflammation → Pathogen → Biology → Scientific study → Knowledge → Belief → Attitude \(psychology\) → Psychology → Mind → Thought → Cognition → \(back to Knowledge\)
- Risleya → Monotypic taxon → Biology → Scientific study → Knowledge → Belief → Attitude \(psychology\) → Psychology → Mind → Thought → Cognition → \(back to Knowledge\)
- Rispah → The Invisible \(band\) → Dave Okumu → \(back to The Invisible \(band\)\)
- Unlabeled → Graph coloring → Graph theory → Mathematics → Number theory → \(back to Mathematics\)
- Verongimorpha → Class \(taxonomy\) → Taxonomy \(biology\) → Biology → Scientific study → Knowledge → Belief → Attitude \(psychology\) → Psychology → Mind → Thought → Cognition → \(back to Knowledge\)

### C. Examples: articles that hit a dead end

::: note
*(random, common-word titles; kinds: red, redirect, none[^deadend])*
:::

[^deadend]: A dead end is a page whose chain stops. **red**: the first link points at a page that does not exist, shown as a red link on Wikipedia. **redirect**: the first link is a redirect that never resolves to an article: a redirect loop, a chain of more than 10 redirects, or a redirect into another namespace. **none**: the page exists but has no qualifying first link, typically a disambiguation page whose links are italicized, or a page whose lead is nothing but templates.

- Auchencairn → Rerrick → \(dead end: red\)
- Korkmazlar → Erman Okay → \(dead end: red\)
- Maler → Eva Maler → Blank pages → \(dead end: red\)
- Patla → Patla, Kasaragod → Kasaragod district → Western Ghats → Coastal South West India → Geo\-cultural region → \(dead end: red\)
- Stollmann → Jörg Stollmann → Santozeum → \(dead end: red\)
- Uyar → Anıl Uyar → \(dead end: red\)

## II. Rule: parens_ok (italicized and template links are skipped)

### A. Where Philosophy itself leads

- Philosophy → Ancient Greek → Greek language → Indo\-European languages → Language family → Language → Communication → Information → Abstract and concrete → Philosophy

### B. Examples: articles that end in a cycle

::: note
*(random, short chains, common-word titles)*
:::

- Ballingeary → Shehy Mountains → Irish language → An Caighdeán Oifigiúil → \(back to Irish language\)
- Cloughduv → County Cork → Counties of Ireland → Norman Irish → Normans → Norman language → Guernésiais → \(back to Norman language\)
- Foynes → County Limerick → Counties of Ireland → Norman Irish → Normans → Norman language → Guernésiais → \(back to Norman language\)
- Gallegos → Galicia \(Spain\) → Autonomous communities of Spain → Political divisions of Spain → \(back to Autonomous communities of Spain\)
- Garis → Howard R. Garis → Uncle Wiggily → \(back to Howard R. Garis\)
- Vanessa → Vanessa \(Millais\) → John Everett Millais → Pre\-Raphaelite Brotherhood → William Holman Hunt → \(back to Pre\-Raphaelite Brotherhood\)

### C. Examples: articles that hit a dead end

::: note
*(random, common-word titles; kinds: red, redirect, none)*
:::

- Anavryti → Anavryti, Aetolia\-Acarnania → \(dead end: red\)
- Eido → Eido \(moth\) → \(dead end: red\)
- Keyuan → Boxia → \(dead end: red\)
- Krasne → Krasne, Saskatchewan → \(dead end: red\)
- Manthimba → Kings M. Phiri → \(dead end: red\)
- Salmah → Classical Indonesian cinema → \(dead end: red\)

## III. Rule: skip_parens (only parenthesized links are skipped)

### A. Where Philosophy itself leads

- Philosophy → Existence → Reality → \(back to Existence\)

### B. Examples: articles that end in a cycle

::: note
*(random, short chains, common-word titles)*
:::

- Astrovirtel → Space Telescope European Coordinating Facility → Hubble Space Telescope → STS\-125 → Space Transportation System → NASA → NASA insignia → \(back to NASA\)
- Bugthorpe → 2011 United Kingdom census → United Kingdom → UK \(disambiguation\) → \(back to United Kingdom\)
- Crunoecia → Caddisfly → William Kirby \(entomologist\) → William Forsell Kirby → \(back to William Kirby \(entomologist\)\)
- Nanhuang → Town \(China\) → Administrative divisions of China → China → Taiwan → \(back to Taiwan\)
- Parsigecko → Monotypic taxon → Biology → Scientific study → Knowledge → Belief → Attitude \(psychology\) → Psychology → Mind → Thought → Cognition → \(back to Knowledge\)
- Shen → Shen \(Chinese folk religion\) → Chinese language → China → Taiwan → \(back to Taiwan\)

### C. Examples: articles that hit a dead end

::: note
*(random, common-word titles; kinds: red, redirect, none)*
:::

- Carceliathrix → Carceliathrix crassipalpis → \(dead end: red\)
- Daphnopsis → Daphnopsis racemosa → \(dead end: red\)
- Grillenburg → Grillenburg \(Tharandt\) → \(dead end: red\)
- Isoperlinae → T. H. Frison → \(dead end: red\)
- Kumarimulla → Pugoda → \(dead end: red\)
- Migoli → Bois Roussel → Vatout → \(dead end: red\)

## IV. Rule: skip_italics (only italicized links are skipped)

### A. Where Philosophy itself leads

- Philosophy → Ancient Greek → Athena Parthenos → Chryselephantine sculpture → Gold → Chemical element → Chemical species → Chemical nomenclature → Systematic name → Substance \(chemistry\) → Chemistry → Outline of chemistry → Outline \(list\) → List → Information → Abstract and concrete → Philosophy

### B. Examples: articles that end in a cycle

::: note
*(random, short chains, common-word titles)*
:::

- Caraunus → Chartres → Prefectures in France → France → Liberté, égalité, fraternité → French language → Lingua franca → \(back to French language\)
- Dirman → Iran → God in Islam → Islam → Kaaba → Saudi Arabia → KSA \(disambiguation\) → \(back to Saudi Arabia\)
- Djebabra → Provinces of Algeria → Algeria → Standard Algerian Amazigh → \(back to Algeria\)
- Moba → Moba, Democratic Republic of the Congo → Democratic Republic of the Congo → Republic of the Congo → \(back to Democratic Republic of the Congo\)
- Nheengatu → Brazil → Coat of arms of Brazil → Federal Senate \(Brazil\) → 57th Legislature of the National Congress → Brazilian National Congress → \(back to 57th Legislature of the National Congress\)
- Vlasanica → List of populated places in Serbia → Serbia → Bože pravde → \(back to Serbia\)

### C. Examples: articles that hit a dead end

::: note
*(random, common-word titles; kinds: red, redirect, none)*
:::

- Diapominae → Carl H. Eigenmann → Oberderdingen → \(dead end: none\)
- Grandmesnil → Grandmesnil family → \(dead end: red\)
- Nesioneta → A. F. Millidge → Arachnology → Ancient roman → \(dead end: red\)
- Parapellucens → Jeremy Daniel Holloway → \(dead end: none\)
- Pugieu → Chazey\-Bons → Communauté de communes Bugey Sud → \(dead end: red\)
- Wooley → Bob Wooley → Keith Gardner \(politician\) → \(dead end: red\)

## V. Rule: loose (only template links are skipped)

### A. Where Philosophy itself leads

- Philosophy → Ancient Greek → Greek language → Indo\-European languages → Language family → Language → Communication → Information → Abstract and concrete → Philosophy

### B. Examples: articles that end in a cycle

::: note
*(random, short chains, common-word titles)*
:::

- Fanetizole → Immune system → Biological system → Biological network → Graph theory → Mathematics → Number theory → \(back to Mathematics\)
- Hyatt → Multinational corporation → Corporation → Entity → Existence → Reality → \(back to Existence\)
- Kittenpants → Online magazine → Magazine → Periodical literature → Publication → Publishing → \(back to Publishing\)
- Newtongrange → Mining → Natural resource → Resource → Non\-renewable resource → \(back to Natural resource\)
- Space → Three\-dimensional space → Geometry → Mathematics → Number theory → \(back to Mathematics\)
- Suances → Cantabria → Autonomous communities of Spain → Political divisions of Spain → \(back to Autonomous communities of Spain\)

### C. Examples: articles that hit a dead end

::: note
*(random, common-word titles; kinds: red, redirect, none)*
:::

- Cojo → Cojocaru And → \(dead end: red\)
- Kantza → Kantza, Attica → \(dead end: red\)
- Lousa → Lousa \(Castelo Branco\) → \(dead end: red\)
- Madec → Jean\-François Madec → \(dead end: red\)
- Niniche → Niniche \(play\) → \(dead end: red\)
- Tinkham → Ernest Robert Tinkham → \(dead end: red\)

# Every rule against strict

### A. Rules

- strict: parenthesized, italicized and template links skipped \(Wikipedia's strict rule\)

- parens\_ok: italicized and template links skipped; parenthesized links count

- skip\_parens: only parenthesized links skipped

- skip\_italics: only italicized links skipped

- loose: only template links skipped \(Wikipedia's loose rule\)

"template" means inside any \{\{ \}\} template or \{\| \|\} table: infoboxes, hatnotes, navboxes alike.

### B. Where articles end up, by rule

| rule | philosophy | cycle | dead end | mean clicks \(reaching\) | max clicks |
|---|---:|---:|---:|---:|---:|
| strict | 3,736,703 \(51.5%\) | 3,438,431 \(47.4%\) | 73,964 \(1.0%\) | 15.17 | 201 |
| parens ok | 6,873,610 \(94.8%\) | 306,074 \(4.2%\) | 69,414 \(1.0%\) | 14.13 | 201 |
| skip parens | 567,977 \(7.8%\) | 6,502,846 \(89.7%\) | 178,275 \(2.5%\) | 13.67 | 45 |
| skip italics | 1,190,490 \(16.4%\) | 5,884,261 \(81.2%\) | 174,347 \(2.4%\) | 14.77 | 55 |
| loose | 6,875,315 \(94.8%\) | 314,361 \(4.3%\) | 59,422 \(0.8%\) | 14.04 | 201 |

### C. Each rule against strict: how often the first link differs, and how outcomes move

| rule | different first link | philosophy under both | gained philosophy | lost philosophy |
|---|---:|---:|---:|---:|
| parens ok | 345,844 \(4.8%\) | 3,701,064 \(51.1%\) | 3,172,546 \(43.8%\) | 35,639 \(0.5%\) |
| skip parens | 4,264,440 \(58.8%\) | 384,046 \(5.3%\) | 183,931 \(2.5%\) | 3,352,657 \(46.2%\) |
| skip italics | 4,305,034 \(59.4%\) | 625,414 \(8.6%\) | 565,076 \(7.8%\) | 3,111,289 \(42.9%\) |
| loose | 482,707 \(6.7%\) | 3,689,272 \(50.9%\) | 3,186,043 \(44.0%\) | 47,431 \(0.7%\) |

### D. Articles reaching Philosophy under both strict and the rule: clicks compared

| rule | articles \(of all\) | strict avg clicks | rule avg clicks | shorter | same | longer |
|---|---:|---:|---:|---:|---:|---:|
| parens ok | 3,701,064 \(51.1%\) | 15.16 | 14.70 | 493,255 \(13.3%\) | 2,912,785 \(78.7%\) | 295,024 \(8.0%\) |
| skip parens | 384,046 \(5.3%\) | 13.29 | 13.49 | 126,757 \(33.0%\) | 91,600 \(23.9%\) | 165,689 \(43.1%\) |
| skip italics | 625,414 \(8.6%\) | 14.33 | 14.86 | 239,881 \(38.4%\) | 93,194 \(14.9%\) | 292,339 \(46.7%\) |
| loose | 3,689,272 \(50.9%\) | 15.16 | 14.56 | 582,229 \(15.8%\) | 2,788,440 \(75.6%\) | 318,603 \(8.6%\) |

### E. Outcome under strict (rows) vs parens_ok (columns), percent of all articles

| strict ↓  parens ok → | philosophy | cycle | dead end | total |
|---|---:|---:|---:|---:|
| philosophy | 51.06 | 0.48 | 0.01 | 51.55 |
| cycle | 43.68 | 3.74 | 0.01 | 47.43 |
| dead end | 0.09 | 0.00 | 0.93 | 1.02 |
| total | 94.82 | 4.22 | 0.96 | 100.00 |

### F. Outcome under strict (rows) vs loose (columns), percent of all articles

| strict ↓  loose → | philosophy | cycle | dead end | total |
|---|---:|---:|---:|---:|
| philosophy | 50.89 | 0.63 | 0.02 | 51.55 |
| cycle | 43.72 | 3.69 | 0.03 | 47.43 |
| dead end | 0.23 | 0.01 | 0.77 | 1.02 |
| total | 94.84 | 4.34 | 0.82 | 100.00 |

### G. Cumulative share of ALL articles within N clicks of Philosophy, by rule

| within clicks | strict | parens ok | skip parens | skip italics | loose |
|---:|---:|---:|---:|---:|---:|
| 0 | 0.00 | 0.00 | 0.00 | 0.00 | 0.00 |
| 1 | 0.03 | 0.03 | 0.02 | 0.02 | 0.03 |
| 2 | 0.08 | 0.07 | 0.06 | 0.06 | 0.07 |
| 3 | 0.13 | 0.12 | 0.12 | 0.11 | 0.12 |
| 4 | 0.24 | 0.23 | 0.16 | 0.16 | 0.23 |
| 5 | 0.48 | 0.47 | 0.24 | 0.25 | 0.48 |
| 6 | 1.68 | 1.92 | 0.64 | 0.84 | 1.90 |
| 7 | 4.06 | 5.66 | 1.64 | 2.02 | 5.69 |
| 8 | 6.20 | 9.82 | 2.42 | 3.14 | 10.01 |
| 9 | 7.98 | 15.41 | 2.96 | 4.22 | 15.62 |
| 10 | 10.29 | 21.53 | 3.31 | 5.25 | 21.81 |
| 11 | 12.65 | 27.62 | 3.58 | 6.02 | 27.95 |
| 12 | 14.80 | 33.56 | 3.84 | 7.09 | 33.92 |
| 13 | 18.43 | 41.30 | 4.00 | 7.82 | 41.65 |
| 14 | 21.12 | 47.21 | 4.20 | 8.35 | 47.64 |
| 15 | 23.91 | 54.72 | 4.42 | 8.79 | 55.40 |
| 16 | 30.67 | 66.04 | 4.59 | 9.44 | 66.87 |
| 17 | 35.69 | 75.42 | 5.01 | 10.17 | 76.29 |
| 18 | 40.14 | 82.34 | 5.24 | 11.14 | 83.18 |
| 19 | 43.11 | 86.63 | 5.99 | 12.31 | 87.36 |
| 20 | 45.02 | 89.20 | 6.69 | 13.22 | 89.89 |
| 21 | 46.22 | 91.08 | 6.96 | 13.86 | 91.75 |
| 22 | 47.54 | 92.96 | 7.43 | 14.66 | 93.59 |
| 23 | 49.03 | 93.72 | 7.62 | 15.16 | 94.28 |
| 24 | 49.94 | 94.29 | 7.73 | 15.57 | 94.57 |
| 25 | 50.55 | 94.61 | 7.79 | 15.87 | 94.71 |
| 26 | 50.91 | 94.73 | 7.81 | 16.06 | 94.78 |
| 27 | 51.15 | 94.77 | 7.82 | 16.16 | 94.81 |
| 28 | 51.32 | 94.81 | 7.83 | 16.25 | 94.83 |
| 29 | 51.48 | 94.82 | 7.83 | 16.31 | 94.84 |
| 30 | 51.53 | 94.82 | 7.83 | 16.36 | 94.84 |
| 31 | 51.54 | 94.82 | 7.83 | 16.38 | 94.84 |
| 32 | 51.54 | 94.82 | 7.83 | 16.39 | 94.84 |
| 33 | 51.54 | 94.82 | 7.83 | 16.40 | 94.84 |
| 34 | 51.54 | 94.82 | 7.83 | 16.41 | 94.84 |
| 35 | 51.54 | 94.82 | 7.83 | 16.42 | 94.84 |

### H. Clicks needed to reach Philosophy, by share of ALL articles

::: note
*(blank = never)*
:::

| % of all articles | strict | parens ok | skip parens | skip italics | loose |
|---:|---:|---:|---|---:|---:|
| 10 | 10 | 9 |  | 17 | 8 |
| 25 | 16 | 11 |  |  | 11 |
| 50 | 25 | 15 |  |  | 15 |
| 75 |  | 17 |  |  | 17 |
| 90 |  | 21 |  |  | 21 |
| 95 |  |  |  |  |  |
| 99 |  |  |  |  |  |

### I. Clicks needed to reach Philosophy, by share of the articles that REACH it under the rule

| % of those reaching | strict | parens ok | skip parens | skip italics | loose |
|---:|---:|---:|---:|---:|---:|
| 10 | 8 | 8 | 7 | 7 | 8 |
| 25 | 12 | 11 | 8 | 9 | 11 |
| 50 | 16 | 15 | 13 | 14 | 14 |
| 75 | 18 | 17 | 19 | 20 | 17 |
| 90 | 22 | 19 | 22 | 23 | 19 |
| 95 | 23 | 21 | 23 | 25 | 21 |
| 99 | 27 | 24 | 25 | 29 | 23 |

# Report: strict rule (parenthesized, italicized and template links are skipped)

### A. Where do articles end up?

| terminal type | articles | pct | avg clicks | max clicks |
|---|---:|---:|---:|---:|
| philosophy | 3,736,703 | 51.55 | 15.17 | 201 |
| cycle | 3,438,431 | 47.43 | 10.36 | 32 |
| dead end | 73,964 | 1.02 | 0.63 | 8 |

### B. Clicks-to-Philosophy distribution

::: note
*(buckets of 1 up to 29, then 10)*
:::

| clicks | sort key | articles |
|---|---:|---:|
| 0 | 0 | 1 |
| 1 | 1 | 2,266 |
| 2 | 2 | 3,356 |
| 3 | 3 | 3,578 |
| 4 | 4 | 8,167 |
| 5 | 5 | 17,600 |
| 6 | 6 | 87,121 |
| 7 | 7 | 171,924 |
| 8 | 8 | 155,738 |
| 9 | 9 | 128,409 |
| 10 | 10 | 167,531 |
| 11 | 11 | 171,465 |
| 12 | 12 | 155,792 |
| 13 | 13 | 263,044 |
| 14 | 14 | 194,826 |
| 15 | 15 | 202,227 |
| 16 | 16 | 490,474 |
| 17 | 17 | 363,582 |
| 18 | 18 | 322,418 |
| 19 | 19 | 215,927 |
| 20 | 20 | 137,962 |
| 21 | 21 | 87,404 |
| 22 | 22 | 95,386 |
| 23 | 23 | 108,314 |
| 24 | 24 | 65,374 |
| 25 | 25 | 44,670 |
| 26 | 26 | 25,823 |
| 27 | 27 | 17,353 |
| 28 | 28 | 12,526 |
| 29 | 29 | 11,402 |
| 30\-39 | 30 | 4,881 |
| 40\-49 | 40 | 10 |
| 50\-59 | 50 | 10 |
| 60\-69 | 60 | 10 |
| 70\-79 | 70 | 10 |
| 80\-89 | 80 | 10 |
| 90\-99 | 90 | 10 |
| 100\-109 | 100 | 10 |
| 110\-119 | 110 | 10 |
| 120\-129 | 120 | 10 |
| 130\-139 | 130 | 10 |
| 140\-149 | 140 | 10 |
| 150\-159 | 150 | 10 |
| 160\-169 | 160 | 10 |
| 170\-179 | 170 | 10 |
| 180\-189 | 180 | 10 |
| 190\-199 | 190 | 10 |
| 200\-209 | 200 | 2 |

### C. Longest roads to Philosophy

| title | clicks |
|---|---:|
| Gelasius | 201 |
| Gelasius of Nilopolis | 200 |
| December 31 \(Eastern Orthodox liturgics\) | 199 |
| December 30 \(Eastern Orthodox liturgics\) | 198 |
| December 29 \(Eastern Orthodox liturgics\) | 197 |
| December 28 \(Eastern Orthodox liturgics\) | 196 |
| December 27 \(Eastern Orthodox liturgics\) | 195 |
| December 26 \(Eastern Orthodox liturgics\) | 194 |
| December 25 \(Eastern Orthodox liturgics\) | 193 |
| December 24 \(Eastern Orthodox liturgics\) | 192 |

### D. Where Philosophy itself leads

::: note
*(chain until a node repeats)*
:::

- Philosophy → Existence → Reality

### E. Biggest dead ends

::: note
*(kind: red = link to a page that does not exist, redirect = first link is a redirect that never resolves, none = page has no qualifying first link)*
:::

| dead end | kind | articles ending here |
|---|---|---:|
| Ecclesiastical | none | 545 |
| Lunar eclipse | redirect | 362 |
| Geo\-cultural region | red | 338 |
| London, Ontario | none | 221 |
| Exoteric | none | 202 |
| Gaumee Film Awards | none | 120 |
| Administrative divisions of Altai Krai | none | 78 |
| Ecological reserves of Quebec | none | 71 |
| Administrative divisions of Novosibirsk Oblast | none | 70 |
| Dignitary | none | 70 |
| Administrative divisions of the Sakha Republic | none | 67 |
| Administrative divisions of Kirov Oblast | none | 60 |
| Administrative divisions of Saratov Oblast | none | 56 |
| Administrative divisions of Orenburg Oblast | none | 54 |
| Administrative divisions of Nizhny Novgorod Oblast | none | 54 |

### F. Dead ends by kind

| kind | dead ends | articles trapped |
|---|---:|---:|
| none | 34,033 | 38,978 |
| red | 28,732 | 34,095 |
| redirect | 461 | 891 |

### G. Biggest cycles

| articles | cycle len | loop |
|---:|---:|---|
| 3,116,361 | 7 | Attitude \(psychology\) → Psychology → Mind → Thought → Cognition → Knowledge → Belief |
| 100,154 | 2 | Mathematics → Number theory |
| 55,924 | 2 | Existence → Reality |
| 23,656 | 1 | Publishing |
| 12,721 | 3 | Natural resource → Resource → Non\-renewable resource |
| 7,961 | 2 | Amateur sports → Professional sports |
| 7,954 | 1 | Fiber |
| 6,166 | 2 | Autonomous communities of Spain → Political divisions of Spain |
| 5,864 | 2 | Ski → Skiing |
| 3,610 | 2 | History of Canadian sports → Sports in Canada |

# Report: parens_ok rule (italicized and template links are skipped)

### A. Where do articles end up?

| terminal type | articles | pct | avg clicks | max clicks |
|---|---:|---:|---:|---:|
| philosophy | 6,873,610 | 94.82 | 14.13 | 201 |
| cycle | 306,074 | 4.22 | 3.95 | 22 |
| dead end | 69,414 | 0.96 | 0.63 | 7 |

### B. Clicks-to-Philosophy distribution

::: note
*(buckets of 1 up to 29, then 10)*
:::

| clicks | sort key | articles |
|---|---:|---:|
| 0 | 0 | 1 |
| 1 | 1 | 2,051 |
| 2 | 2 | 3,158 |
| 3 | 3 | 3,355 |
| 4 | 4 | 7,766 |
| 5 | 5 | 18,076 |
| 6 | 6 | 104,449 |
| 7 | 7 | 271,280 |
| 8 | 8 | 301,532 |
| 9 | 9 | 405,387 |
| 10 | 10 | 443,918 |
| 11 | 11 | 441,151 |
| 12 | 12 | 430,594 |
| 13 | 13 | 560,998 |
| 14 | 14 | 428,259 |
| 15 | 15 | 544,520 |
| 16 | 16 | 821,164 |
| 17 | 17 | 679,758 |
| 18 | 18 | 501,823 |
| 19 | 19 | 310,502 |
| 20 | 20 | 186,252 |
| 21 | 21 | 136,719 |
| 22 | 22 | 135,974 |
| 23 | 23 | 55,104 |
| 24 | 24 | 41,059 |
| 25 | 25 | 23,463 |
| 26 | 26 | 8,444 |
| 27 | 27 | 3,374 |
| 28 | 28 | 2,655 |
| 29 | 29 | 552 |
| 30\-39 | 30 | 106 |
| 40\-49 | 40 | 14 |
| 50\-59 | 50 | 10 |
| 60\-69 | 60 | 10 |
| 70\-79 | 70 | 10 |
| 80\-89 | 80 | 10 |
| 90\-99 | 90 | 10 |
| 100\-109 | 100 | 10 |
| 110\-119 | 110 | 10 |
| 120\-129 | 120 | 10 |
| 130\-139 | 130 | 10 |
| 140\-149 | 140 | 10 |
| 150\-159 | 150 | 10 |
| 160\-169 | 160 | 10 |
| 170\-179 | 170 | 10 |
| 180\-189 | 180 | 10 |
| 190\-199 | 190 | 10 |
| 200\-209 | 200 | 2 |

### C. Longest roads to Philosophy

| title | clicks |
|---|---:|
| Gelasius | 201 |
| Gelasius of Nilopolis | 200 |
| December 31 \(Eastern Orthodox liturgics\) | 199 |
| December 30 \(Eastern Orthodox liturgics\) | 198 |
| December 29 \(Eastern Orthodox liturgics\) | 197 |
| December 28 \(Eastern Orthodox liturgics\) | 196 |
| December 27 \(Eastern Orthodox liturgics\) | 195 |
| December 26 \(Eastern Orthodox liturgics\) | 194 |
| December 25 \(Eastern Orthodox liturgics\) | 193 |
| December 24 \(Eastern Orthodox liturgics\) | 192 |

### D. Where Philosophy itself leads

::: note
*(chain until a node repeats)*
:::

- Philosophy → Ancient Greek → Greek language → Indo\-European languages → Language family → Language → Communication → Information → Abstract and concrete

### E. Biggest dead ends

::: note
*(kind: red = link to a page that does not exist, redirect = first link is a redirect that never resolves, none = page has no qualifying first link)*
:::

| dead end | kind | articles ending here |
|---|---|---:|
| Ecclesiastical | none | 502 |
| Lunar eclipse | redirect | 362 |
| London, Ontario | none | 273 |
| Exoteric | none | 177 |
| Geo\-cultural region | red | 164 |
| Gaumee Film Awards | none | 120 |
| Ancient roman | red | 78 |
| Ecological reserves of Quebec | none | 71 |
| Dignitary | none | 68 |
| Mount Baloy | red | 48 |
| Asia Pacific Screen Academy | red | 44 |
| Linguistic norm | none | 38 |
| Bimonthly | none | 37 |
| Translation of gods | red | 37 |
| Serial entrepreneurship | none | 37 |

### F. Dead ends by kind

| kind | dead ends | articles trapped |
|---|---:|---:|
| none | 31,545 | 35,177 |
| red | 28,255 | 33,434 |
| redirect | 379 | 803 |

### G. Biggest cycles

| articles | cycle len | loop |
|---:|---:|---|
| 86,109 | 2 | Mathematics → Number theory |
| 45,724 | 2 | Existence → Reality |
| 22,892 | 1 | Publishing |
| 12,358 | 3 | Natural resource → Resource → Non\-renewable resource |
| 10,868 | 2 | Art music → Classical music |
| 7,494 | 2 | Amateur sports → Professional sports |
| 6,580 | 2 | Autonomous communities of Spain → Political divisions of Spain |
| 5,907 | 2 | Guernésiais → Norman language |
| 5,511 | 2 | Ski → Skiing |
| 3,560 | 2 | History of Canadian sports → Sports in Canada |

# Report: skip_parens rule (only parenthesized links are skipped)

### A. Where do articles end up?

| terminal type | articles | pct | avg clicks | max clicks |
|---|---:|---:|---:|---:|
| cycle | 6,502,846 | 89.71 | 10.50 | 187 |
| philosophy | 567,977 | 7.84 | 13.67 | 45 |
| dead end | 178,275 | 2.46 | 1.97 | 79 |

### B. Clicks-to-Philosophy distribution

::: note
*(buckets of 1 up to 29, then 10)*
:::

| clicks | sort key | articles |
|---|---:|---:|
| 0 | 0 | 1 |
| 1 | 1 | 1,281 |
| 2 | 2 | 3,416 |
| 3 | 3 | 3,851 |
| 4 | 4 | 3,364 |
| 5 | 5 | 5,184 |
| 6 | 6 | 29,463 |
| 7 | 7 | 72,537 |
| 8 | 8 | 56,413 |
| 9 | 9 | 39,069 |
| 10 | 10 | 25,165 |
| 11 | 11 | 19,526 |
| 12 | 12 | 19,068 |
| 13 | 13 | 11,775 |
| 14 | 14 | 14,002 |
| 15 | 15 | 16,011 |
| 16 | 16 | 12,919 |
| 17 | 17 | 30,338 |
| 18 | 18 | 16,129 |
| 19 | 19 | 54,931 |
| 20 | 20 | 50,326 |
| 21 | 21 | 19,426 |
| 22 | 22 | 34,131 |
| 23 | 23 | 14,280 |
| 24 | 24 | 8,051 |
| 25 | 25 | 3,753 |
| 26 | 26 | 1,519 |
| 27 | 27 | 1,256 |
| 28 | 28 | 307 |
| 29 | 29 | 284 |
| 30\-39 | 30 | 195 |
| 40\-49 | 40 | 6 |

### C. Longest roads to Philosophy

| title | clicks |
|---|---:|
| 2025–26 CAF Champions League group stage | 45 |
| 2024–25 CAF Champions League group stage | 44 |
| 2023–24 CAF Champions League group stage | 43 |
| 2022–23 CAF Champions League group stage | 42 |
| 2021–22 CAF Champions League group stage | 41 |
| 2020–21 CAF Champions League group stage | 40 |
| 2019–20 CAF Champions League group stage | 39 |
| 1978–79 Tercera División | 38 |
| 2018–19 CAF Champions League group stage | 38 |
| 1977–78 Tercera División | 37 |

### D. Where Philosophy itself leads

::: note
*(chain until a node repeats)*
:::

- Philosophy → Existence → Reality

### E. Biggest dead ends

::: note
*(kind: red = link to a page that does not exist, redirect = first link is a redirect that never resolves, none = page has no qualifying first link)*
:::

| dead end | kind | articles ending here |
|---|---|---:|
| Erling Sivertsen | red | 4,615 |
| MOS:SANDWICH | red | 4,370 |
| Kubanychbek Malikov | red | 1,370 |
| Lípsia \(singer\) | red | 1,362 |
| Dirk Ahrens | none | 1,226 |
| John Ernest Breun | red | 1,106 |
| Lend Lease Program | red | 963 |
| Coal Industry Act 1973 | red | 852 |
| Council of Quebec | red | 731 |
| List of UK Parliamentary constituencies \(1950–1955\) | red | 669 |
| Ernst Brenske | none | 586 |
| Wootton St Lawrence with Ramsdell | red | 568 |
| MOS:NOSECTIONLINKS | red | 553 |
| Emilio Rolán | none | 544 |
| Chrissy Schoonmaker | red | 484 |

### F. Dead ends by kind

| kind | dead ends | articles trapped |
|---|---:|---:|
| none | 8,415 | 33,364 |
| red | 77,549 | 144,503 |
| redirect | 78 | 408 |

### G. Biggest cycles

| articles | cycle len | loop |
|---:|---:|---|
| 2,116,012 | 2 | Provinces of Laos → Xaisomboun province |
| 691,519 | 7 | Attitude \(psychology\) → Psychology → Mind → Thought → Cognition → Knowledge → Belief |
| 673,665 | 2 | Antequera Dolmens Site → Dolmen of Menga |
| 282,326 | 2 | Medieval stained glass → Middle Ages |
| 273,443 | 2 | Mathematics → Number theory |
| 181,601 | 2 | Branches of physics → Physics |
| 120,696 | 2 | Commonwealth of Nations → Member states of the Commonwealth of Nations |
| 73,005 | 2 | Cerebrum → Frontal lobe |
| 69,905 | 2 | East Renfrewshire \(constituency\) → Renfrewshire \(UK Parliament constituency\) |
| 67,424 | 2 | UK \(disambiguation\) → United Kingdom |

# Report: skip_italics rule (only italicized links are skipped)

### A. Where do articles end up?

| terminal type | articles | pct | avg clicks | max clicks |
|---|---:|---:|---:|---:|
| cycle | 5,884,261 | 81.17 | 9.85 | 187 |
| philosophy | 1,190,490 | 16.42 | 14.77 | 55 |
| dead end | 174,347 | 2.41 | 1.94 | 79 |

### B. Clicks-to-Philosophy distribution

::: note
*(buckets of 1 up to 29, then 10)*
:::

| clicks | sort key | articles |
|---|---:|---:|
| 0 | 0 | 1 |
| 1 | 1 | 1,130 |
| 2 | 2 | 3,336 |
| 3 | 3 | 3,755 |
| 4 | 4 | 3,294 |
| 5 | 5 | 6,740 |
| 6 | 6 | 42,413 |
| 7 | 7 | 86,046 |
| 8 | 8 | 81,044 |
| 9 | 9 | 77,991 |
| 10 | 10 | 75,128 |
| 11 | 11 | 55,871 |
| 12 | 12 | 77,457 |
| 13 | 13 | 52,327 |
| 14 | 14 | 39,116 |
| 15 | 15 | 31,845 |
| 16 | 16 | 46,698 |
| 17 | 17 | 52,923 |
| 18 | 18 | 70,113 |
| 19 | 19 | 84,780 |
| 20 | 20 | 66,505 |
| 21 | 21 | 46,155 |
| 22 | 22 | 58,406 |
| 23 | 23 | 35,671 |
| 24 | 24 | 30,227 |
| 25 | 25 | 21,299 |
| 26 | 26 | 13,729 |
| 27 | 27 | 7,693 |
| 28 | 28 | 6,532 |
| 29 | 29 | 4,188 |
| 30\-39 | 30 | 7,954 |
| 40\-49 | 40 | 87 |
| 50\-59 | 50 | 36 |

### C. Longest roads to Philosophy

| title | clicks |
|---|---:|
| 2003 World Table Tennis Championships – Men's doubles | 55 |
| 2003 World Table Tennis Championships – Men's singles | 55 |
| 2003 World Table Tennis Championships – Women's doubles | 55 |
| 2003 World Table Tennis Championships – Women's singles | 55 |
| 2004 World Team Table Tennis Championships – Men's team | 55 |
| 2004 World Team Table Tennis Championships – Women's team | 55 |
| 2001 World Table Tennis Championships – Men's doubles | 54 |
| 2001 World Table Tennis Championships – Men's singles | 54 |
| 2001 World Table Tennis Championships – Men's team | 54 |
| 2001 World Table Tennis Championships – Women's doubles | 54 |

### D. Where Philosophy itself leads

::: note
*(chain until a node repeats)*
:::

- Philosophy → Ancient Greek → Athena Parthenos → Chryselephantine sculpture → Gold → Chemical element → Chemical species → Chemical nomenclature → Systematic name → Substance \(chemistry\) → Chemistry → Outline of chemistry → Outline \(list\) → List → Information → Abstract and concrete

### E. Biggest dead ends

::: note
*(kind: red = link to a page that does not exist, redirect = first link is a redirect that never resolves, none = page has no qualifying first link)*
:::

| dead end | kind | articles ending here |
|---|---|---:|
| Erling Sivertsen | red | 4,602 |
| MOS:SANDWICH | red | 4,415 |
| Lípsia \(singer\) | red | 1,396 |
| Kubanychbek Malikov | red | 1,366 |
| Dirk Ahrens | none | 1,226 |
| John Ernest Breun | red | 1,100 |
| Lend Lease Program | red | 953 |
| Tui Atua Tupua Tamasese Efi Government Building | red | 913 |
| Ancient roman | red | 907 |
| Coal Industry Act 1973 | red | 857 |
| Council of Quebec | red | 732 |
| List of UK Parliamentary constituencies \(1950–1955\) | red | 680 |
| Ernst Brenske | none | 586 |
| MOS:NOSECTIONLINKS | red | 557 |
| Emilio Rolán | none | 541 |

### F. Dead ends by kind

| kind | dead ends | articles trapped |
|---|---:|---:|
| none | 14,247 | 39,760 |
| red | 69,513 | 134,181 |
| redirect | 78 | 406 |

### G. Biggest cycles

| articles | cycle len | loop |
|---:|---:|---|
| 2,828,118 | 2 | Provinces of Laos → Xaisomboun province |
| 203,110 | 2 | English language → English\-speaking world |
| 159,070 | 2 | UK \(disambiguation\) → United Kingdom |
| 157,254 | 2 | Medieval stained glass → Middle Ages |
| 135,687 | 2 | Mathematics → Number theory |
| 117,973 | 2 | Branches of physics → Physics |
| 115,014 | 2 | Commonwealth of Nations → Member states of the Commonwealth of Nations |
| 90,747 | 2 | French language → Lingua franca |
| 89,070 | 2 | Existence → Reality |
| 71,572 | 2 | East Renfrewshire \(constituency\) → Renfrewshire \(UK Parliament constituency\) |

# Report: loose rule (only template links are skipped)

### A. Where do articles end up?

| terminal type | articles | pct | avg clicks | max clicks |
|---|---:|---:|---:|---:|
| philosophy | 6,875,315 | 94.84 | 14.04 | 201 |
| cycle | 314,361 | 4.34 | 3.92 | 33 |
| dead end | 59,422 | 0.82 | 0.73 | 7 |

### B. Clicks-to-Philosophy distribution

::: note
*(buckets of 1 up to 29, then 10)*
:::

| clicks | sort key | articles |
|---|---:|---:|
| 0 | 0 | 1 |
| 1 | 1 | 2,047 |
| 2 | 2 | 3,131 |
| 3 | 3 | 3,363 |
| 4 | 4 | 7,972 |
| 5 | 5 | 18,223 |
| 6 | 6 | 102,661 |
| 7 | 7 | 274,752 |
| 8 | 8 | 313,611 |
| 9 | 9 | 406,356 |
| 10 | 10 | 448,886 |
| 11 | 11 | 445,036 |
| 12 | 12 | 432,597 |
| 13 | 13 | 560,620 |
| 14 | 14 | 434,092 |
| 15 | 15 | 562,696 |
| 16 | 16 | 831,781 |
| 17 | 17 | 682,758 |
| 18 | 18 | 499,252 |
| 19 | 19 | 303,309 |
| 20 | 20 | 183,151 |
| 21 | 21 | 134,522 |
| 22 | 22 | 133,598 |
| 23 | 23 | 50,184 |
| 24 | 24 | 20,574 |
| 25 | 25 | 10,766 |
| 26 | 26 | 4,990 |
| 27 | 27 | 2,132 |
| 28 | 28 | 1,439 |
| 29 | 29 | 438 |
| 30\-39 | 30 | 160 |
| 40\-49 | 40 | 39 |
| 50\-59 | 50 | 27 |
| 60\-69 | 60 | 19 |
| 70\-79 | 70 | 10 |
| 80\-89 | 80 | 10 |
| 90\-99 | 90 | 10 |
| 100\-109 | 100 | 10 |
| 110\-119 | 110 | 10 |
| 120\-129 | 120 | 10 |
| 130\-139 | 130 | 10 |
| 140\-149 | 140 | 10 |
| 150\-159 | 150 | 10 |
| 160\-169 | 160 | 10 |
| 170\-179 | 170 | 10 |
| 180\-189 | 180 | 10 |
| 190\-199 | 190 | 10 |
| 200\-209 | 200 | 2 |

### C. Longest roads to Philosophy

| title | clicks |
|---|---:|
| Gelasius | 201 |
| Gelasius of Nilopolis | 200 |
| December 31 \(Eastern Orthodox liturgics\) | 199 |
| December 30 \(Eastern Orthodox liturgics\) | 198 |
| December 29 \(Eastern Orthodox liturgics\) | 197 |
| December 28 \(Eastern Orthodox liturgics\) | 196 |
| December 27 \(Eastern Orthodox liturgics\) | 195 |
| December 26 \(Eastern Orthodox liturgics\) | 194 |
| December 25 \(Eastern Orthodox liturgics\) | 193 |
| December 24 \(Eastern Orthodox liturgics\) | 192 |

### D. Where Philosophy itself leads

::: note
*(chain until a node repeats)*
:::

- Philosophy → Ancient Greek → Greek language → Indo\-European languages → Language family → Language → Communication → Information → Abstract and concrete

### E. Biggest dead ends

::: note
*(kind: red = link to a page that does not exist, redirect = first link is a redirect that never resolves, none = page has no qualifying first link)*
:::

| dead end | kind | articles ending here |
|---|---|---:|
| Ecclesiastical | none | 504 |
| Lunar eclipse | redirect | 362 |
| London, Ontario | none | 261 |
| Exoteric | none | 170 |
| Geo\-cultural region | red | 159 |
| Gaumee Film Awards | none | 112 |
| Ancient roman | red | 76 |
| Ecological reserves of Quebec | none | 71 |
| Dignitary | none | 67 |
| Mount Baloy | red | 48 |
| Bimonthly | none | 48 |
| Saída do Pessoal Operário da Fábrica Confiança | red | 47 |
| Asia Pacific Screen Academy | red | 41 |
| Translation of gods | red | 38 |
| Serial entrepreneurship | none | 37 |

### F. Dead ends by kind

| kind | dead ends | articles trapped |
|---|---:|---:|
| none | 21,610 | 24,492 |
| red | 28,835 | 34,126 |
| redirect | 379 | 804 |

### G. Biggest cycles

| articles | cycle len | loop |
|---:|---:|---|
| 87,544 | 2 | Mathematics → Number theory |
| 45,384 | 2 | Existence → Reality |
| 26,702 | 1 | Publishing |
| 12,288 | 3 | Natural resource → Resource → Non\-renewable resource |
| 10,714 | 2 | Art music → Classical music |
| 7,500 | 2 | Amateur sports → Professional sports |
| 6,300 | 2 | Autonomous communities of Spain → Political divisions of Spain |
| 5,842 | 2 | Guernésiais → Norman language |
| 5,509 | 2 | Ski → Skiing |
| 3,554 | 2 | History of Canadian sports → Sports in Canada |

# Full statistics: strict rule (parenthesized, italicized and template links are skipped)

### A. Cumulative share of articles within N clicks of Philosophy

| within clicks | at this distance | cumulative | pct of all articles | pct of those reaching |
|---:|---:|---:|---:|---:|
| 0 | 1 | 1 | 0.00 | 0.00 |
| 1 | 2,266 | 2,267 | 0.03 | 0.06 |
| 2 | 3,356 | 5,623 | 0.08 | 0.15 |
| 3 | 3,578 | 9,201 | 0.13 | 0.25 |
| 4 | 8,167 | 17,368 | 0.24 | 0.46 |
| 5 | 17,600 | 34,968 | 0.48 | 0.94 |
| 6 | 87,121 | 122,089 | 1.68 | 3.27 |
| 7 | 171,924 | 294,013 | 4.06 | 7.87 |
| 8 | 155,738 | 449,751 | 6.20 | 12.04 |
| 9 | 128,409 | 578,160 | 7.98 | 15.47 |
| 10 | 167,531 | 745,691 | 10.29 | 19.96 |
| 11 | 171,465 | 917,156 | 12.65 | 24.54 |
| 12 | 155,792 | 1,072,948 | 14.80 | 28.71 |
| 13 | 263,044 | 1,335,992 | 18.43 | 35.75 |
| 14 | 194,826 | 1,530,818 | 21.12 | 40.97 |
| 15 | 202,227 | 1,733,045 | 23.91 | 46.38 |
| 16 | 490,474 | 2,223,519 | 30.67 | 59.50 |
| 17 | 363,582 | 2,587,101 | 35.69 | 69.23 |
| 18 | 322,418 | 2,909,519 | 40.14 | 77.86 |
| 19 | 215,927 | 3,125,446 | 43.11 | 83.64 |
| 20 | 137,962 | 3,263,408 | 45.02 | 87.33 |
| 21 | 87,404 | 3,350,812 | 46.22 | 89.67 |
| 22 | 95,386 | 3,446,198 | 47.54 | 92.23 |
| 23 | 108,314 | 3,554,512 | 49.03 | 95.12 |
| 24 | 65,374 | 3,619,886 | 49.94 | 96.87 |
| 25 | 44,670 | 3,664,556 | 50.55 | 98.07 |
| 26 | 25,823 | 3,690,379 | 50.91 | 98.76 |
| 27 | 17,353 | 3,707,732 | 51.15 | 99.22 |
| 28 | 12,526 | 3,720,258 | 51.32 | 99.56 |
| 29 | 11,402 | 3,731,660 | 51.48 | 99.87 |
| 30 | 4,112 | 3,735,772 | 51.53 | 99.98 |
| 31 | 646 | 3,736,418 | 51.54 | 99.99 |
| 32 | 90 | 3,736,508 | 51.54 | 99.99 |
| 33 | 15 | 3,736,523 | 51.54 | 100.00 |
| 34 | 4 | 3,736,527 | 51.54 | 100.00 |

### B. Clicks needed to reach Philosophy, by share of articles

::: note
*(blank = never)*
:::

| % of articles | clicks, all articles | clicks, those reaching |
|---:|---:|---:|
| 10 | 10 | 8 |
| 25 | 16 | 12 |
| 35 | 17 | 13 |
| 50 | 25 | 16 |
| 75 |  | 18 |
| 90 |  | 22 |
| 95 |  | 23 |
| 99 |  | 27 |

### C. Farthest chain heads

::: note
*(no other article links into them)*
:::

| title | distance |
|---|---:|
| Gelasius | 201 |
| Bec | 39 |
| Ciannachta | 37 |
| Corbmac | 36 |
| Eochaid Gonnat | 35 |
| Énna Aignech | 34 |
| Conall Collamrach | 33 |
| Danley | 33 |
| Dinotopia \(disambiguation\) | 33 |
| USS H\-2 | 33 |

### D. Farthest chain heads outside the single-file tail

::: note
*(distances still shared by 10+ articles)*
:::

| title | distance |
|---|---:|
| Conall Collamrach | 33 |
| Danley | 33 |
| Dinotopia \(disambiguation\) | 33 |
| USS H\-2 | 33 |
| USS H\-3 | 33 |
| USS H\-4 | 33 |
| USS H\-5 | 33 |
| USS H\-6 | 33 |
| USS H\-7 | 33 |
| USS H\-8 | 33 |

### E. Single-file tails: chains that own the far distances, and where they rejoin the crowd

| head | head distance | pages in single file | midpoint page | rejoins crowd at | crowd distance |
|---|---:|---:|---|---|---:|
| Gelasius | 201 | 168 | October 11 \(Eastern Orthodox liturgics\) | July 18 \(Eastern Orthodox liturgics\) | 33 |
| Bec | 39 | 6 | Fiachu Muillethan | Dui Dallta Dedad | 33 |
| Ciannachta | 37 | 4 | Tadc mac Céin | Dui Dallta Dedad | 33 |
| Corbmac | 36 | 3 | Corbmac | Dui Dallta Dedad | 33 |
| Eochaid Gonnat | 35 | 2 | Eochaid Gonnat | Óengus Tuirmech Temrach | 33 |
| Énna Aignech | 34 | 1 |  | Óengus Tuirmech Temrach | 33 |

### F. Counts at 1, 2, 3 clicks

| distance | count |
|---:|---:|
| 1 | 2,266 |
| 2 | 3,356 |
| 3 | 3,578 |

### G. One click: first link is Philosophy, common-word titles that are not obviously philosophical

::: note
*(random 30)*
:::

- Practical reason
- Whole language
- Leap of faith
- Incorrigibility
- Relationship between mathematics and physics
- White paper
- Immanent evaluation
- Salva veritate
- Compossibility
- First principle
- Antiperistasis
- Pancasila
- Tunnel problem
- Potentiality and actuality
- Moral responsibility
- Infinite divisibility
- Aristion
- Holocentric
- Aletheia
- Animal rights
- Embodied embedded cognition
- Homaranismo
- Family resemblance
- Natural law
- Frankfurt cases
- Tattvabindu
- Supervenience
- Hypostatic abstraction
- Passive intellect
- Awareness

### H. Two clicks, single common-word titles with their path

::: note
*(random 30)*
:::

- Information → Abstract and concrete → Philosophy
- Busybody → Theophrastus → Philosophy
- Fieser → James Fieser → Philosophy
- Ontotheology → Ontology → Philosophy
- Whaddyado → Ethical dilemma → Philosophy
- Formulation → Abstract and concrete → Philosophy
- Condillac → Étienne Bonnot de Condillac → Philosophy
- Carneiscus → Epicureanism → Philosophy
- Subjective → Subjectivity and objectivity \(philosophy\) → Philosophy
- Leontyev → Aleksei Leontiev → Philosophy
- Moby → Animal rights → Philosophy
- Reincarnated → Reincarnation → Philosophy
- Bovio → Giovanni Bovio → Philosophy
- Wenzi → Taoism → Philosophy
- Callard → Agnes Callard → Philosophy
- Quantity → Property \(philosophy\) → Philosophy
- Plumwood → Val Plumwood → Philosophy
- Massumi → Brian Massumi → Philosophy
- Akhudiat → Humanism → Philosophy
- Neology → Rationalism → Philosophy
- Impossibility → Epistemic possibility → Philosophy
- Meherabad → Universalism → Philosophy
- Crinis → Stoicism → Philosophy
- Qualia → Philosophy of mind → Philosophy
- Semiosis → Action \(philosophy\) → Philosophy
- Manner → Methodology → Philosophy
- Tawatur → Epistemology → Philosophy
- Currere → Postmodern philosophy → Philosophy
- Anhedonia → Hedonism → Philosophy
- Worlds → World → Philosophy

# Full statistics: parens_ok rule (italicized and template links are skipped)

### A. Cumulative share of articles within N clicks of Philosophy

| within clicks | at this distance | cumulative | pct of all articles | pct of those reaching |
|---:|---:|---:|---:|---:|
| 0 | 1 | 1 | 0.00 | 0.00 |
| 1 | 2,051 | 2,052 | 0.03 | 0.03 |
| 2 | 3,158 | 5,210 | 0.07 | 0.08 |
| 3 | 3,355 | 8,565 | 0.12 | 0.12 |
| 4 | 7,766 | 16,331 | 0.23 | 0.24 |
| 5 | 18,076 | 34,407 | 0.47 | 0.50 |
| 6 | 104,449 | 138,856 | 1.92 | 2.02 |
| 7 | 271,280 | 410,136 | 5.66 | 5.97 |
| 8 | 301,532 | 711,668 | 9.82 | 10.35 |
| 9 | 405,387 | 1,117,055 | 15.41 | 16.25 |
| 10 | 443,918 | 1,560,973 | 21.53 | 22.71 |
| 11 | 441,151 | 2,002,124 | 27.62 | 29.13 |
| 12 | 430,594 | 2,432,718 | 33.56 | 35.39 |
| 13 | 560,998 | 2,993,716 | 41.30 | 43.55 |
| 14 | 428,259 | 3,421,975 | 47.21 | 49.78 |
| 15 | 544,520 | 3,966,495 | 54.72 | 57.71 |
| 16 | 821,164 | 4,787,659 | 66.04 | 69.65 |
| 17 | 679,758 | 5,467,417 | 75.42 | 79.54 |
| 18 | 501,823 | 5,969,240 | 82.34 | 86.84 |
| 19 | 310,502 | 6,279,742 | 86.63 | 91.36 |
| 20 | 186,252 | 6,465,994 | 89.20 | 94.07 |
| 21 | 136,719 | 6,602,713 | 91.08 | 96.06 |
| 22 | 135,974 | 6,738,687 | 92.96 | 98.04 |
| 23 | 55,104 | 6,793,791 | 93.72 | 98.84 |
| 24 | 41,059 | 6,834,850 | 94.29 | 99.44 |
| 25 | 23,463 | 6,858,313 | 94.61 | 99.78 |
| 26 | 8,444 | 6,866,757 | 94.73 | 99.90 |
| 27 | 3,374 | 6,870,131 | 94.77 | 99.95 |
| 28 | 2,655 | 6,872,786 | 94.81 | 99.99 |
| 29 | 552 | 6,873,338 | 94.82 | 100.00 |
| 30 | 68 | 6,873,406 | 94.82 | 100.00 |
| 31 | 9 | 6,873,415 | 94.82 | 100.00 |
| 32 | 5 | 6,873,420 | 94.82 | 100.00 |
| 33 | 5 | 6,873,425 | 94.82 | 100.00 |
| 34 | 5 | 6,873,430 | 94.82 | 100.00 |

### B. Clicks needed to reach Philosophy, by share of articles

::: note
*(blank = never)*
:::

| % of articles | clicks, all articles | clicks, those reaching |
|---:|---:|---:|
| 10 | 9 | 8 |
| 25 | 11 | 11 |
| 35 | 13 | 12 |
| 50 | 15 | 15 |
| 75 | 17 | 17 |
| 90 | 21 | 19 |
| 95 |  | 21 |
| 99 |  | 24 |

### C. Philosophy returns to itself in 9 clicks under this rule. Articles exactly that far from Philosophy

::: note
*(single common-word titles, random 40)*
:::

| title | distance |
|---|---:|
| Zeyrek | 9 |
| Hyalophysa | 9 |
| Eunicella | 9 |
| Auxilio | 9 |
| Saphenophis | 9 |
| Sulestes | 9 |
| Neoanalthes | 9 |
| Thasthara | 9 |
| Morghab | 9 |
| Clelandina | 9 |
| Speocropia | 9 |
| Icichthys | 9 |
| Izmirictis | 9 |
| Fucaria | 9 |
| Tryblidium | 9 |
| Parerupa | 9 |
| Neosalurnis | 9 |
| Rhopiella | 9 |
| Caiuajara | 9 |
| Tutusius | 9 |
| Saloca | 9 |
| Otwaya | 9 |
| Gnathoenia | 9 |
| Liniaxis | 9 |
| Budugu | 9 |
| Vanadocyte | 9 |
| Urokodia | 9 |
| Prodesmodon | 9 |
| Amadocus | 9 |
| Epiblem | 9 |
| Pseudocnus | 9 |
| Thaumaspis | 9 |
| Haua | 9 |
| Limenavis | 9 |
| Transindex | 9 |
| Tetanolita | 9 |
| Megistaspis | 9 |
| Yanoama | 9 |
| Podisus | 9 |
| Elliptoleus | 9 |

### D. Farthest chain heads

::: note
*(no other article links into them)*
:::

| title | distance |
|---|---:|
| Gelasius | 201 |
| 2016 Solihull Metropolitan Borough Council election | 43 |
| 1945 Ontario general election | 37 |
| Eochaid Gonnat | 35 |
| Énna Aignech | 34 |
| Conall Collamrach | 33 |
| BISP | 32 |
| Amherst | 31 |
| Chalita | 31 |
| Kemmis | 31 |

### E. Farthest chain heads outside the single-file tail

::: note
*(distances still shared by 10+ articles)*
:::

| title | distance |
|---|---:|
| Anauktaw | 30 |
| Aniporn Chalermburanawong | 30 |
| Anna Sueangam\-iam | 30 |
| Ayadaw \(disambiguation\) | 30 |
| Bogon | 30 |
| Chanyasorn Sakornchan | 30 |
| Chiang Rai Airport | 30 |
| Daniel Coakley | 30 |
| Dayu | 30 |
| Farida Waller | 30 |

### F. Single-file tails: chains that own the far distances, and where they rejoin the crowd

| head | head distance | pages in single file | midpoint page | rejoins crowd at | crowd distance |
|---|---:|---:|---|---|---:|
| Gelasius | 201 | 171 | October 10 \(Eastern Orthodox liturgics\) | July 15 \(Eastern Orthodox liturgics\) | 30 |
| 2016 Solihull Metropolitan Borough Council election | 43 | 13 | 2010 Solihull Metropolitan Borough Council election | 1999 Solihull Metropolitan Borough Council election | 30 |
| 1945 Ontario general election | 37 | 7 | 1948 Ontario general election | 25th Parliament of Ontario | 30 |
| Eochaid Gonnat | 35 | 5 | Fíatach Finn | Connla Cáem | 30 |
| Énna Aignech | 34 | 4 | Óengus Tuirmech Temrach | Connla Cáem | 30 |
| Conall Collamrach | 33 | 3 | Conall Collamrach | Connla Cáem | 30 |
| BISP | 32 | 2 | BISP | Amanda Obdam | 30 |
| Chalita | 31 | 1 |  | Chalita Suansane | 30 |
| Amherst | 31 | 1 |  | Amherst \(surname\) | 30 |
| Kemmis | 31 | 1 |  | Anchilee Scott\-Kemmis | 30 |

### G. Counts at 1, 2, 3 clicks

| distance | count |
|---:|---:|
| 1 | 2,051 |
| 2 | 3,158 |
| 3 | 3,355 |

### H. One click: first link is Philosophy, common-word titles that are not obviously philosophical

::: note
*(random 30)*
:::

- Alterity
- Awareness
- Salva veritate
- Qualification problem
- Chrysanthius
- Timeless universe
- Common good
- Erkenntnis
- Proving too much
- Environmental hermeneutics
- Abstract and concrete
- Il problema della guerra e le vie della pace
- Management fad
- Aufheben
- Heterophenomenology
- Emergence
- Ontopoetics
- Equipossibility
- Mimpathy
- Metempsychosis
- Nomothetic
- Downward causation
- Paradox of fiction
- Architectonics
- Ressentiment
- Panopticon
- Good and evil
- Moral compass
- Henology
- Further facts

### I. Two clicks, single common-word titles with their path

::: note
*(random 30)*
:::

- Bicchieri → Cristina Bicchieri → Philosophy
- Haugeland → John Haugeland → Philosophy
- Credibility → Subjectivity and objectivity \(philosophy\) → Philosophy
- Bugang → Taoism → Philosophy
- Vidyatmananda → Swami Prabhavananda → Philosophy
- Xishengjing → Taoism → Philosophy
- Agathology → Henology → Philosophy
- Soble → Alan Soble → Philosophy
- Interpretant → Subject and object \(philosophy\) → Philosophy
- Megill → Kenneth Megill → Philosophy
- Anhedonia → Hedonism → Philosophy
- Information → Abstract and concrete → Philosophy
- Wenzi → Taoism → Philosophy
- Brogaard → Berit Brogaard → Philosophy
- Thymology → Praxeology → Philosophy
- Thomasius → Jakob Thomasius → Philosophy
- Vallega → Alejandro Vallega → Philosophy
- Hermeneutics → Methodology → Philosophy
- Sittlichkeit → Georg Wilhelm Friedrich Hegel → Philosophy
- Tussman → Joseph Tussman → Philosophy
- Erasmus → Humanism → Philosophy
- Biocomplexity → Emergence → Philosophy
- Avens → Henry Corbin → Philosophy
- Caird → Edward Caird → Philosophy
- Dianoia → Platonism → Philosophy
- Consciousness → Awareness → Philosophy
- Reincarnated → Reincarnation → Philosophy
- Loewer → Barry Loewer → Philosophy
- Balibar → Étienne Balibar → Philosophy
- Sundo → Taoism → Philosophy

# Full statistics: skip_parens rule (only parenthesized links are skipped)

### A. Cumulative share of articles within N clicks of Philosophy

| within clicks | at this distance | cumulative | pct of all articles | pct of those reaching |
|---:|---:|---:|---:|---:|
| 0 | 1 | 1 | 0.00 | 0.00 |
| 1 | 1,281 | 1,282 | 0.02 | 0.23 |
| 2 | 3,416 | 4,698 | 0.06 | 0.83 |
| 3 | 3,851 | 8,549 | 0.12 | 1.51 |
| 4 | 3,364 | 11,913 | 0.16 | 2.10 |
| 5 | 5,184 | 17,097 | 0.24 | 3.01 |
| 6 | 29,463 | 46,560 | 0.64 | 8.20 |
| 7 | 72,537 | 119,097 | 1.64 | 20.97 |
| 8 | 56,413 | 175,510 | 2.42 | 30.90 |
| 9 | 39,069 | 214,579 | 2.96 | 37.78 |
| 10 | 25,165 | 239,744 | 3.31 | 42.21 |
| 11 | 19,526 | 259,270 | 3.58 | 45.65 |
| 12 | 19,068 | 278,338 | 3.84 | 49.01 |
| 13 | 11,775 | 290,113 | 4.00 | 51.08 |
| 14 | 14,002 | 304,115 | 4.20 | 53.54 |
| 15 | 16,011 | 320,126 | 4.42 | 56.36 |
| 16 | 12,919 | 333,045 | 4.59 | 58.64 |
| 17 | 30,338 | 363,383 | 5.01 | 63.98 |
| 18 | 16,129 | 379,512 | 5.24 | 66.82 |
| 19 | 54,931 | 434,443 | 5.99 | 76.49 |
| 20 | 50,326 | 484,769 | 6.69 | 85.35 |
| 21 | 19,426 | 504,195 | 6.96 | 88.77 |
| 22 | 34,131 | 538,326 | 7.43 | 94.78 |
| 23 | 14,280 | 552,606 | 7.62 | 97.29 |
| 24 | 8,051 | 560,657 | 7.73 | 98.71 |
| 25 | 3,753 | 564,410 | 7.79 | 99.37 |
| 26 | 1,519 | 565,929 | 7.81 | 99.64 |
| 27 | 1,256 | 567,185 | 7.82 | 99.86 |
| 28 | 307 | 567,492 | 7.83 | 99.91 |
| 29 | 284 | 567,776 | 7.83 | 99.96 |
| 30 | 123 | 567,899 | 7.83 | 99.99 |
| 31 | 38 | 567,937 | 7.83 | 99.99 |
| 32 | 11 | 567,948 | 7.83 | 99.99 |
| 33 | 8 | 567,956 | 7.83 | 100.00 |
| 34 | 6 | 567,962 | 7.83 | 100.00 |

### B. Clicks needed to reach Philosophy, by share of articles

::: note
*(blank = never)*
:::

| % of articles | clicks, all articles | clicks, those reaching |
|---:|---|---:|
| 10 |  | 7 |
| 25 |  | 8 |
| 35 |  | 9 |
| 50 |  | 13 |
| 75 |  | 19 |
| 90 |  | 22 |
| 95 |  | 23 |
| 99 |  | 25 |

### C. Farthest chain heads

::: note
*(no other article links into them)*
:::

| title | distance |
|---|---:|
| 2025–26 CAF Champions League group stage | 45 |
| 1978–79 Tercera División | 38 |
| 1998 Georgia Secretary of State election | 34 |
| 2026–27 Northern Football League | 34 |
| Brooks Coleman | 34 |
| Cathy Cox | 34 |
| 2026 Beninese parliamentary election | 33 |
| Kathy Cox | 33 |
| Martin Scott | 33 |
| 2005 Brisbane Broncos season | 32 |

### D. Farthest chain heads outside the single-file tail

::: note
*(distances still shared by 10+ articles)*
:::

| title | distance |
|---|---:|
| 2005 Brisbane Broncos season | 32 |
| Dan Lakly | 32 |
| Donna McLeod | 32 |
| Jonathan Wallace \(Georgia politician\) | 32 |
| 95th State House District | 31 |
| Alberta Anderson | 31 |
| Allen Peake | 31 |
| Beth Moore \(politician\) | 31 |
| Bubber Epps | 31 |
| Carol Fullerton | 31 |

### E. Single-file tails: chains that own the far distances, and where they rejoin the crowd

| head | head distance | pages in single file | midpoint page | rejoins crowd at | crowd distance |
|---|---:|---:|---|---|---:|
| 2025–26 CAF Champions League group stage | 45 | 13 | 2020–21 CAF Champions League group stage | 2013 CAF Champions League group stage | 32 |
| 1978–79 Tercera División | 38 | 6 | 1976–77 Tercera División | 1972–73 Tercera División | 32 |
| 2026–27 Northern Football League | 34 | 2 | 2026–27 Northern Football League | 2024–25 Northern Football League | 32 |
| 1998 Georgia Secretary of State election | 34 | 2 | 1998 Georgia Secretary of State election | Kathy Cox \(American politician\) | 32 |
| Brooks Coleman | 34 | 2 | Brooks Coleman | Long Tran | 32 |
| Cathy Cox | 34 | 2 | Cathy Cox | Kathy Cox \(American politician\) | 32 |
| Martin Scott | 33 | 1 |  | Martin Scott \(politician\) | 32 |
| 2026 Beninese parliamentary election | 33 | 1 |  | 2023 Beninese parliamentary election | 32 |
| Kathy Cox | 33 | 1 |  | Kathy Cox \(American politician\) | 32 |

### F. Counts at 1, 2, 3 clicks

| distance | count |
|---:|---:|
| 1 | 1,281 |
| 2 | 3,416 |
| 3 | 3,851 |

### G. One click: first link is Philosophy, common-word titles that are not obviously philosophical

::: note
*(random 30)*
:::

- Eristic
- Infinite divisibility
- Transcendental homelessness
- Embodied embedded cognition
- Proving too much
- Euphraeus
- Evidential existentiality
- Panopticon
- Process thinking
- Accidental necessity
- Unity of opposites
- Innate language
- Immanent evaluation
- Augustiniana
- Digital physics
- Pancasila
- Awareness
- Environmental hermeneutics
- Transcendent theosophy
- Quaestio
- Grouped events
- Management fad
- Holocentric
- Musica universalis
- Whole language
- Nomology
- Composition of causes
- Methodology
- Ramification problem
- Objective precision

### H. Two clicks, single common-word titles with their path

::: note
*(random 30)*
:::

- Aristocreon → Stoicism → Philosophy
- Ibbur → Reincarnation → Philosophy
- Process → Action \(philosophy\) → Philosophy
- Rationality → Quality \(philosophy\) → Philosophy
- Biocomplexity → Emergence → Philosophy
- Hermarchus → Western philosophy → Philosophy
- Socrates → Western philosophy → Philosophy
- Archewell → First principle → Philosophy
- Universality → Universalism → Philosophy
- Vorstellung → Epistemology → Philosophy
- Paracelsus → Western philosophy → Philosophy
- Quantity → Property \(philosophy\) → Philosophy
- Amalrician → Pantheism → Philosophy
- Shingaku → Ishida Baigan → Philosophy
- Reincarnated → Reincarnation → Philosophy
- Celso → Celsus → Philosophy
- Particular → Metaphysics → Philosophy
- Diotogenes → Ancient philosophy → Philosophy
- Antisthenes → Western philosophy → Philosophy
- Sociogeny → Ontology → Philosophy
- Licking → Action \(philosophy\) → Philosophy
- Carneades → Western philosophy → Philosophy
- Panopticons → Panopticon → Philosophy
- Information → Abstract and concrete → Philosophy
- Speusippus → Western philosophy → Philosophy
- Metaxy → Platonism → Philosophy
- Gilgul → Reincarnation → Philosophy
- Worldwide → World → Philosophy
- Agathology → Henology → Philosophy
- Sibawayh → Islamic philosophy → Philosophy

# Full statistics: skip_italics rule (only italicized links are skipped)

### A. Cumulative share of articles within N clicks of Philosophy

| within clicks | at this distance | cumulative | pct of all articles | pct of those reaching |
|---:|---:|---:|---:|---:|
| 0 | 1 | 1 | 0.00 | 0.00 |
| 1 | 1,130 | 1,131 | 0.02 | 0.10 |
| 2 | 3,336 | 4,467 | 0.06 | 0.38 |
| 3 | 3,755 | 8,222 | 0.11 | 0.69 |
| 4 | 3,294 | 11,516 | 0.16 | 0.97 |
| 5 | 6,740 | 18,256 | 0.25 | 1.53 |
| 6 | 42,413 | 60,669 | 0.84 | 5.10 |
| 7 | 86,046 | 146,715 | 2.02 | 12.32 |
| 8 | 81,044 | 227,759 | 3.14 | 19.13 |
| 9 | 77,991 | 305,750 | 4.22 | 25.68 |
| 10 | 75,128 | 380,878 | 5.25 | 31.99 |
| 11 | 55,871 | 436,749 | 6.02 | 36.69 |
| 12 | 77,457 | 514,206 | 7.09 | 43.19 |
| 13 | 52,327 | 566,533 | 7.82 | 47.59 |
| 14 | 39,116 | 605,649 | 8.35 | 50.87 |
| 15 | 31,845 | 637,494 | 8.79 | 53.55 |
| 16 | 46,698 | 684,192 | 9.44 | 57.47 |
| 17 | 52,923 | 737,115 | 10.17 | 61.92 |
| 18 | 70,113 | 807,228 | 11.14 | 67.81 |
| 19 | 84,780 | 892,008 | 12.31 | 74.93 |
| 20 | 66,505 | 958,513 | 13.22 | 80.51 |
| 21 | 46,155 | 1,004,668 | 13.86 | 84.39 |
| 22 | 58,406 | 1,063,074 | 14.66 | 89.30 |
| 23 | 35,671 | 1,098,745 | 15.16 | 92.29 |
| 24 | 30,227 | 1,128,972 | 15.57 | 94.83 |
| 25 | 21,299 | 1,150,271 | 15.87 | 96.62 |
| 26 | 13,729 | 1,164,000 | 16.06 | 97.77 |
| 27 | 7,693 | 1,171,693 | 16.16 | 98.42 |
| 28 | 6,532 | 1,178,225 | 16.25 | 98.97 |
| 29 | 4,188 | 1,182,413 | 16.31 | 99.32 |
| 30 | 3,335 | 1,185,748 | 16.36 | 99.60 |
| 31 | 1,636 | 1,187,384 | 16.38 | 99.74 |
| 32 | 647 | 1,188,031 | 16.39 | 99.79 |
| 33 | 714 | 1,188,745 | 16.40 | 99.85 |
| 34 | 865 | 1,189,610 | 16.41 | 99.93 |

### B. Clicks needed to reach Philosophy, by share of articles

::: note
*(blank = never)*
:::

| % of articles | clicks, all articles | clicks, those reaching |
|---:|---:|---:|
| 10 | 17 | 7 |
| 25 |  | 9 |
| 35 |  | 11 |
| 50 |  | 14 |
| 75 |  | 20 |
| 90 |  | 23 |
| 95 |  | 25 |
| 99 |  | 29 |

### C. Philosophy returns to itself in 16 clicks under this rule. Articles exactly that far from Philosophy

::: note
*(single common-word titles, random 40)*
:::

| title | distance |
|---|---:|
| Apridon | 16 |
| Afterpay | 16 |
| Eroge | 16 |
| Hadrucalcin | 16 |
| Ciroadas | 16 |
| Tsintsila | 16 |
| Swanville | 16 |
| Whiton | 16 |
| Vanchikulam | 16 |
| Shingkarap | 16 |
| Ruchheim | 16 |
| Philmore | 16 |
| Polyxo | 16 |
| Villadam | 16 |
| Newtype | 16 |
| Marusyllus | 16 |
| Weapemeoc | 16 |
| Jeshua | 16 |
| Agetor | 16 |
| Chembukkavu | 16 |
| Mithaecus | 16 |
| Wernick | 16 |
| Thujopsene | 16 |
| Thinae | 16 |
| Suidakra | 16 |
| Laicism | 16 |
| Hermeias | 16 |
| Acta | 16 |
| Gigging | 16 |
| Davydky | 16 |
| Critasirus | 16 |
| Humbler | 16 |
| Pyromancy | 16 |
| Abelox | 16 |
| Hutsuls | 16 |
| Asahel | 16 |
| Janes | 16 |
| Tonuzoba | 16 |
| Senecionine | 16 |
| Rugvica | 16 |

### D. Farthest chain heads

::: note
*(no other article links into them)*
:::

| title | distance |
|---|---:|
| 2003 World Table Tennis Championships – Men's doubles | 55 |
| 2003 World Table Tennis Championships – Men's singles | 55 |
| 2003 World Table Tennis Championships – Women's doubles | 55 |
| 2003 World Table Tennis Championships – Women's singles | 55 |
| 2004 World Team Table Tennis Championships – Men's team | 55 |
| 2004 World Team Table Tennis Championships – Women's team | 55 |
| 1921 WAFL season | 46 |
| 1985 World Table Tennis Championships – Mixed doubles | 46 |
| 2025–26 CAF Champions League group stage | 45 |
| 2016 Solihull Metropolitan Borough Council election | 42 |

### E. Farthest chain heads outside the single-file tail

::: note
*(distances still shared by 10+ articles)*
:::

| title | distance |
|---|---:|
| 2016 Solihull Metropolitan Borough Council election | 42 |
| 1889 Scottish Cup final | 40 |
| 1889–90 Scottish Cup | 40 |
| 1962 All England Badminton Championships | 40 |
| 1980 All England Open Badminton Championships | 40 |
| 1888 Scottish Cup final | 39 |
| Wank | 39 |
| 1887 Scottish Cup final | 38 |
| 1947–48 Bemidji State Beavers men's ice hockey season | 38 |
| 2019–20 Bemidji State Beavers men's ice hockey season | 38 |

### F. Single-file tails: chains that own the far distances, and where they rejoin the crowd

| head | head distance | pages in single file | midpoint page | rejoins crowd at | crowd distance |
|---|---:|---:|---|---|---:|
| 2004 World Team Table Tennis Championships – Men's team | 55 | 13 | 1993 World Table Tennis Championships – Men's team | 1977 World Table Tennis Championships – Men's team | 42 |
| 2004 World Team Table Tennis Championships – Women's team | 55 | 13 | 1993 World Table Tennis Championships – Women's team | 1977 World Table Tennis Championships – Women's team | 42 |
| 2003 World Table Tennis Championships – Men's doubles | 55 | 13 | 1993 World Table Tennis Championships – Men's doubles | 1977 World Table Tennis Championships – Men's doubles | 42 |
| 2003 World Table Tennis Championships – Men's singles | 55 | 13 | 1993 World Table Tennis Championships – Men's singles | 1977 World Table Tennis Championships – Men's singles | 42 |
| 2003 World Table Tennis Championships – Women's doubles | 55 | 13 | 1993 World Table Tennis Championships – Women's doubles | 1977 World Table Tennis Championships – Women's doubles | 42 |
| 2003 World Table Tennis Championships – Women's singles | 55 | 13 | 1993 World Table Tennis Championships – Women's singles | 1977 World Table Tennis Championships – Women's singles | 42 |
| 1921 WAFL season | 46 | 4 | 1920 WAFL season | 1917 WAFL season | 42 |
| 1985 World Table Tennis Championships – Mixed doubles | 46 | 4 | 1983 World Table Tennis Championships – Mixed doubles | 1977 World Table Tennis Championships – Mixed doubles | 42 |
| 2025–26 CAF Champions League group stage | 45 | 3 | 2025–26 CAF Champions League group stage | 2022–23 CAF Champions League group stage | 42 |

### G. Counts at 1, 2, 3 clicks

| distance | count |
|---:|---:|
| 1 | 1,130 |
| 2 | 3,336 |
| 3 | 3,755 |

### H. One click: first link is Philosophy, common-word titles that are not obviously philosophical

::: note
*(random 30)*
:::

- Brain in a vat
- Qualification problem
- Infinite regress
- Nomology
- Architectonics
- Ontopoetics
- Frankfurt cases
- Overbelief
- Filozofia
- Antinomy
- Panopticon
- Il problema della guerra e le vie della pace
- Emergence
- Dysteleology
- Antiperistasis
- Associative economics
- Kriterion
- Pancasila
- Animal rights
- Chrysanthius
- Augustiniana
- Metempsychosis
- Kindness
- Kritike
- Aufheben
- Happiness pump
- Agile construction
- Family resemblance
- Timeless universe
- Leap of faith

### I. Two clicks, single common-word titles with their path

::: note
*(random 30)*
:::

- Posidonius → Western philosophy → Philosophy
- Biocomplexity → Emergence → Philosophy
- Onasander → Ancient philosophy → Philosophy
- Samvara → Ontology → Philosophy
- Gaze → Awareness → Philosophy
- Stilpo → Western philosophy → Philosophy
- Carneades → Western philosophy → Philosophy
- Sibawayh → Islamic philosophy → Philosophy
- Archytas → Western philosophy → Philosophy
- Archewell → First principle → Philosophy
- Intermedia → Aesthetics → Philosophy
- Speusippus → Western philosophy → Philosophy
- Vulnerability → Methodology → Philosophy
- Logos → Western philosophy → Philosophy
- Atonement → Action \(philosophy\) → Philosophy
- Carneiscus → Epicureanism → Philosophy
- Cleanthes → Western philosophy → Philosophy
- Biofacticity → Subject and object \(philosophy\) → Philosophy
- Hermarchus → Western philosophy → Philosophy
- Parsimony → Occam's razor → Philosophy
- Documentality → Ontology → Philosophy
- Herrigel → Eugen Herrigel → Philosophy
- Noesis → Nous → Philosophy
- Commonweal → Common good → Philosophy
- Biofeedback → Awareness → Philosophy
- Object → Subject and object \(philosophy\) → Philosophy
- Pyrrho → Western philosophy → Philosophy
- Heraclitus → Western philosophy → Philosophy
- Action → Action \(philosophy\) → Philosophy
- Xeniades → Western philosophy → Philosophy

# Full statistics: loose rule (only template links are skipped)

### A. Cumulative share of articles within N clicks of Philosophy

| within clicks | at this distance | cumulative | pct of all articles | pct of those reaching |
|---:|---:|---:|---:|---:|
| 0 | 1 | 1 | 0.00 | 0.00 |
| 1 | 2,047 | 2,048 | 0.03 | 0.03 |
| 2 | 3,131 | 5,179 | 0.07 | 0.08 |
| 3 | 3,363 | 8,542 | 0.12 | 0.12 |
| 4 | 7,972 | 16,514 | 0.23 | 0.24 |
| 5 | 18,223 | 34,737 | 0.48 | 0.51 |
| 6 | 102,661 | 137,398 | 1.90 | 2.00 |
| 7 | 274,752 | 412,150 | 5.69 | 5.99 |
| 8 | 313,611 | 725,761 | 10.01 | 10.56 |
| 9 | 406,356 | 1,132,117 | 15.62 | 16.47 |
| 10 | 448,886 | 1,581,003 | 21.81 | 23.00 |
| 11 | 445,036 | 2,026,039 | 27.95 | 29.47 |
| 12 | 432,597 | 2,458,636 | 33.92 | 35.76 |
| 13 | 560,620 | 3,019,256 | 41.65 | 43.91 |
| 14 | 434,092 | 3,453,348 | 47.64 | 50.23 |
| 15 | 562,696 | 4,016,044 | 55.40 | 58.41 |
| 16 | 831,781 | 4,847,825 | 66.87 | 70.51 |
| 17 | 682,758 | 5,530,583 | 76.29 | 80.44 |
| 18 | 499,252 | 6,029,835 | 83.18 | 87.70 |
| 19 | 303,309 | 6,333,144 | 87.36 | 92.11 |
| 20 | 183,151 | 6,516,295 | 89.89 | 94.78 |
| 21 | 134,522 | 6,650,817 | 91.75 | 96.73 |
| 22 | 133,598 | 6,784,415 | 93.59 | 98.68 |
| 23 | 50,184 | 6,834,599 | 94.28 | 99.41 |
| 24 | 20,574 | 6,855,173 | 94.57 | 99.71 |
| 25 | 10,766 | 6,865,939 | 94.71 | 99.86 |
| 26 | 4,990 | 6,870,929 | 94.78 | 99.94 |
| 27 | 2,132 | 6,873,061 | 94.81 | 99.97 |
| 28 | 1,439 | 6,874,500 | 94.83 | 99.99 |
| 29 | 438 | 6,874,938 | 94.84 | 99.99 |
| 30 | 72 | 6,875,010 | 94.84 | 100.00 |
| 31 | 18 | 6,875,028 | 94.84 | 100.00 |
| 32 | 11 | 6,875,039 | 94.84 | 100.00 |
| 33 | 10 | 6,875,049 | 94.84 | 100.00 |
| 34 | 11 | 6,875,060 | 94.84 | 100.00 |

### B. Clicks needed to reach Philosophy, by share of articles

::: note
*(blank = never)*
:::

| % of articles | clicks, all articles | clicks, those reaching |
|---:|---:|---:|
| 10 | 8 | 8 |
| 25 | 11 | 11 |
| 35 | 13 | 12 |
| 50 | 15 | 14 |
| 75 | 17 | 17 |
| 90 | 21 | 19 |
| 95 |  | 21 |
| 99 |  | 23 |

### C. Philosophy returns to itself in 9 clicks under this rule. Articles exactly that far from Philosophy

::: note
*(single common-word titles, random 40)*
:::

| title | distance |
|---|---:|
| Ramban | 9 |
| Dixomyces | 9 |
| Cromptodon | 9 |
| Snezhnoye | 9 |
| Unisex | 9 |
| Dralfa | 9 |
| Neaporia | 9 |
| Toffolo | 9 |
| Ulocladium | 9 |
| Ecdysone | 9 |
| Mimasarta | 9 |
| Biosphere | 9 |
| Underworld | 9 |
| Tormes | 9 |
| Abaeletes | 9 |
| Socratea | 9 |
| Eurylomia | 9 |
| Misionella | 9 |
| Ethanimine | 9 |
| Demodioides | 9 |
| Leptopterna | 9 |
| Trachyboa | 9 |
| Pleiosorbus | 9 |
| Acidosasa | 9 |
| Pendine | 9 |
| Aegosoma | 9 |
| Pseudatelus | 9 |
| Nucras | 9 |
| Tongyang | 9 |
| Cerastium | 9 |
| Psammodes | 9 |
| Ichibengops | 9 |
| Trialestes | 9 |
| Lodderia | 9 |
| Callipelis | 9 |
| Notobryon | 9 |
| Zonulispira | 9 |
| Piratula | 9 |
| Look | 9 |
| Phorine | 9 |

### D. Farthest chain heads

::: note
*(no other article links into them)*
:::

| title | distance |
|---|---:|
| Gelasius | 201 |
| Jōkyū | 66 |
| Emperor Juntoku | 64 |
| Kennin \(disambiguation\) | 61 |
| Miyagishima | 58 |
| Battle of Yahagi\-gawa | 55 |
| Battle of Kanasa Castle | 54 |
| Jisho | 54 |
| Siege of Nara | 54 |
| Enchō | 50 |

### E. Farthest chain heads outside the single-file tail

::: note
*(distances still shared by 10+ articles)*
:::

| title | distance |
|---|---:|
| Bunmei | 35 |
| Daiji | 35 |
| Eishō | 35 |
| Eochaid Gonnat | 35 |
| Onin | 35 |
| 文正 | 34 |
| Énna Aignech | 34 |
| Conall Collamrach | 33 |
| BISP | 32 |
| Kanshō famine | 32 |

### F. Single-file tails: chains that own the far distances, and where they rejoin the crowd

| head | head distance | pages in single file | midpoint page | rejoins crowd at | crowd distance |
|---|---:|---:|---|---|---:|
| Gelasius | 201 | 166 | October 12 \(Eastern Orthodox liturgics\) | July 20 \(Eastern Orthodox liturgics\) | 35 |
| Jōkyū | 66 | 31 | Angen | Tenshō \(Heian period\) | 35 |
| Emperor Juntoku | 64 | 29 | Jōan \(era\) | Tenshō \(Heian period\) | 35 |
| Kennin \(disambiguation\) | 61 | 26 | Nin'an | Tenshō \(Heian period\) | 35 |
| Miyagishima | 58 | 23 | Eiman | Tenshō \(Heian period\) | 35 |
| Battle of Yahagi\-gawa | 55 | 20 | Ōhō | Tenshō \(Heian period\) | 35 |
| Jisho | 54 | 19 | Ōhō | Tenshō \(Heian period\) | 35 |
| Battle of Kanasa Castle | 54 | 19 | Ōhō | Tenshō \(Heian period\) | 35 |
| Siege of Nara | 54 | 19 | Ōhō | Tenshō \(Heian period\) | 35 |
| Enchō | 50 | 15 | Jōgan | Enryaku | 35 |

### G. Counts at 1, 2, 3 clicks

| distance | count |
|---:|---:|
| 1 | 2,047 |
| 2 | 3,131 |
| 3 | 3,363 |

### H. One click: first link is Philosophy, common-word titles that are not obviously philosophical

::: note
*(random 30)*
:::

- Mimpathy
- Overbelief
- Original position
- Timeless universe
- Process thinking
- Aporia
- Transcendent theosophy
- Ousia
- Digital physics
- Invisible labor
- Immanent evaluation
- Personhood
- Denotation
- Aletheia
- Ontopoetics
- Aedesia
- Deconstruction
- Self
- First principle
- Gnosiology
- Transpersonal
- Ramification problem
- Abstract and concrete
- Erkenntnis
- Pyrrho
- Verisimilitude
- Choiceless awareness
- Happiness pump
- Governmentality
- Agile construction

### I. Two clicks, single common-word titles with their path

::: note
*(random 30)*
:::

- Crinis → Stoicism → Philosophy
- Intermedia → Aesthetics → Philosophy
- Policraticus → John of Salisbury → Philosophy
- Weltalter → Friedrich Wilhelm Joseph Schelling → Philosophy
- Aristocreon → Stoicism → Philosophy
- Hermeneutics → Methodology → Philosophy
- Pujante → José Antonio Pujante → Philosophy
- Atonement → Action \(philosophy\) → Philosophy
- Levinas → Emmanuel Levinas → Philosophy
- Kind → Kindness → Philosophy
- Yubu → Taoism → Philosophy
- Regress → Infinite regress → Philosophy
- Neidan → Taoism → Philosophy
- Thomasius → Jakob Thomasius → Philosophy
- Abano → Pietro d'Abano → Philosophy
- Katalepsis → Stoicism → Philosophy
- Brogaard → Berit Brogaard → Philosophy
- Ehrenfels → Christian von Ehrenfels → Philosophy
- Quelle → Horst Matthai Quelle → Philosophy
- Booleo → George Boole → Philosophy
- Artmedia → Aesthetics → Philosophy
- Holzamer → Karl Holzamer → Philosophy
- Zhizha → Taoism → Philosophy
- Taipingjing → Taoism → Philosophy
- Abstract → Abstract and concrete → Philosophy
- Keshin → Reincarnation → Philosophy
- Physiologus → Didacticism → Philosophy
- Justice → Stanford Encyclopedia of Philosophy → Philosophy
- Oncken → Arthur Oncken Lovejoy → Philosophy
- Desboulmiers → David Hume → Philosophy
