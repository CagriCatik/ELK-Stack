---
title: "38. [Exercise] Using Filters"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03 · EXERCISE</div>

# 38. [Exercise] Using Filters

Now that you know how filter context avoids scoring and leverages segment bitset caching, practice rewriting and combining filters on the `movies` index.

## Your task

Write and execute Query DSL requests for the following requirements:

1. **Pure filter + sort:** Find all `Sci-Fi` movies released between `1990` and `1999` (inclusive), using only `filter` context (no scoring), sorted alphabetically by `title.keyword` ascending, returning the first 10 hits.
2. **Scored query + filter + exclusion:** Find movies matching `"love"` in `title`, **filtered** to `year >= 2000`, and **excluding** `Horror` and `Thriller` in `genre.keyword`.
3. **Check `_score`:** Inspect the `_score` field in both responses to verify that query 1 returns `"_score": null` while query 2 scores hits by relevance of `"love"`.

## Walkthrough

<details>
<summary>Show solution</summary>

1. **Pure filter + sort:**

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 10,
    "query": {
      "bool": {
        "filter": [
          { "term": { "genre.keyword": "Sci-Fi" } },
          { "range": { "year": { "gte": 1990, "lte": 1999 } } }
        ]
      }
    },
    "sort": [
      { "title.keyword": "asc" }
    ]
  }'
```

2. **Scored query + filter + exclusion:**

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "bool": {
        "must": [
          { "match": { "title": "love" } }
        ],
        "filter": [
          { "range": { "year": { "gte": 2000 } } }
        ],
        "must_not": [
          { "terms": { "genre.keyword": ["Horror", "Thriller"] } }
        ]
      }
    }
  }'
```

3. **Observing `_score`:**
   - In query 1, sorting by `title.keyword` without `_score` and using only `filter` produces `"_score": null` on every hit.
   - In query 2, `must` runs in query context, so each hit receives a positive BM25 `_score` based on how strongly `"love"` matches `title`.

</details>

## Why this matters

Moving exact constraints (`term`, `terms`, `range`) out of `must` and into `filter` or `must_not` is one of the highest-impact optimizations in Elasticsearch—it eliminates unnecessary BM25 math and lets the cluster reuse cached bitsets across thousands of queries.

<div class="chapter-nav">
<a class="chapter-nav__item" href="037-more-with-filters.html"><span>Previous</span><strong>37. More with Filters</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="039-fuzzy-queries.html"><span>Next</span><strong>39. Fuzzy Queries</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
