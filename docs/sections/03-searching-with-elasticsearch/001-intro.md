---
title: "30. Section 3 Intro"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03</div>

# 30. Section 3 Intro

Now that your `movies` index is mapped and populated, it is time to put Elasticsearch to work for what it does best: **fast, relevant, flexible search**.

In this section, you move from simple URI-based lookups to full JSON Query DSL, learn how Elasticsearch scores and filters documents, and build production-ready autocomplete ("search-as-you-type") experiences.

## What this section covers

- **Query Lite vs. JSON Query DSL** — when a quick `?q=` URI query is enough, and why production applications rely on structured JSON request bodies (`match`, `term`, `bool`).
- **Phrase matching and proximity** — matching exact word sequences with `match_phrase` and relaxing word order or gaps with `slop`.
- **Pagination and sorting** — paging through results with `from`/`size`, why deep pagination hits `index.max_result_window`, and how `search_after` solves it cleanly; plus sorting by `_score` vs. `keyword` and numeric fields.
- **Filter context vs. query context** — skipping relevance scoring for exact criteria (`term`, `range`) so Elasticsearch can cache bitsets and serve repeated filters in microseconds.
- **Fuzzy and partial matching** — handling typos with Levenshtein edit distance (`fuzziness: AUTO`), plus `prefix`, `wildcard`, and `regexp` queries and their performance trade-offs.
- **Search-as-you-type** — comparing query-time prefix matching, custom `edge_ngram` analyzers, and the dedicated `search_as_you_type` field type.

Two hands-on exercises let you practice writing multi-clause queries and filter-context searches against the `movies` dataset before wrapping up.

<div class="chapter-nav">
<a class="chapter-nav__item" href="../02-mapping-and-indexing-data/029-section-2-wrapup.html"><span>Previous</span><strong>29. Section 2 Wrapup</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="031-query-lite-interface.html"><span>Next</span><strong>31. "Query Lite" interface</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
