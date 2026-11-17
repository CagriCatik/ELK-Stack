---
title: "45. Section 3 Wrapup"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03</div>

# 45. Section 3 Wrapup

You now have the complete Elasticsearch search toolkit—from quick terminal checks to production-grade relevance tuning, deep pagination, and instant autocomplete.

## What this section covered

- **Query Lite vs. JSON Query DSL:** Quick `?q=` URI searches for debugging versus structured `match`, `term`, `range`, and `bool` (`must`, `should`, `must_not`, `filter`) queries for applications.
- **Phrase matching:** Enforcing word order and adjacency with `match_phrase` and relaxing it with `slop`.
- **Pagination and sorting:** Using `from`/`size` for shallow pages, `search_after` (with a unique tie-breaker) to bypass `index.max_result_window`, and sorting on `keyword`/numeric fields rather than `text`.
- **Filter context:** Moving exact constraints into `filter` and `must_not` to skip BM25 scoring and take advantage of segment bitset caching.
- **Typo tolerance and partial matching:** Handling misspellings with `fuzziness: "AUTO"`, `prefix_length`, and `max_expansions`, and understanding the cost of `prefix`, `wildcard`, and `regexp`.
- **Search-as-you-type:** Comparing query-time `match_phrase_prefix`, custom index-time `edge_ngram` analyzers (paired with a `standard` `search_analyzer`), and the built-in `search_as_you_type` field type (`bool_prefix`).

## Where to next

In **Section 4: Importing Data Into Your Index, Big or Small**, you will move beyond individual `curl` requests and learn how to ingest data at scale—from Python client scripts and the Bulk API to Logstash pipelines and Beat shippers.

<div class="chapter-nav">
<a class="chapter-nav__item" href="044-search-as-you-type-field-type.html"><span>Previous</span><strong>44. "Search as you Type" Field Type</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="../04-importing-data-into-your-index-big-or-small/046-section-4-intro.html"><span>Next</span><strong>46. Section 4 Intro</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
