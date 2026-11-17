---
title: "37. More with Filters"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03</div>

# 37. More with Filters

In Elasticsearch, a query clause behaves differently depending on **context**: **query context** ("How well does this document match?") versus **filter context** ("Does this document match, yes or no?"). Understanding this distinction is one of the easiest ways to make your searches dramatically faster.

## Query context vs. filter context

| Aspect | Query context (`must`, `should`) | Filter context (`filter`, `must_not`) |
| :--- | :--- | :--- |
| Question answered | *How well* does it match? | *Does* it match? (binary yes/no) |
| Computes `_score`? | Yes (BM25 relevance scoring) | No (`_score` is `0.0` or unaffected) |
| Cached by Elasticsearch? | No | Yes (automatic bitset cache per segment) |
| Best for | Full-text `match`, `match_phrase` | Exact `term`, `terms`, `range`, `exists` |

## Why filter context is so fast

When a clause runs in `filter` (or `must_not`) context:
1. **No scoring math** — Elasticsearch skips BM25 term-frequency and inverse-document-frequency calculations.
2. **Segment bitset caching** — Elasticsearch caches a compact bitset (1 bit per document in a Lucene segment) for frequently used filters. Subsequent queries using the same filter (such as `genre.keyword: "Sci-Fi"` or `year >= 2000`) intersect bitsets in memory in microseconds.

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "bool": {
        "must": [
          { "match": { "title": "space" } }
        ],
        "filter": [
          { "terms": { "genre.keyword": ["Sci-Fi", "Adventure"] } },
          { "range": { "year": { "gte": 1990, "lte": 2010 } } }
        ]
      }
    }
  }'
```

Here, `title: "space"` scores the matching movies by relevance, while `terms` and `range` narrow the candidate set without touching `_score`.

## Pure-filter queries (no scoring at all)

If you are building a facet browser or an exact lookup where relevance order does not matter (for example, "all 1995 comedies sorted alphabetically"), put everything in `filter` inside a `bool` query:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "bool": {
        "filter": [
          { "term": { "genre.keyword": "Comedy" } },
          { "term": { "year": 1995 } }
        ]
      }
    },
    "sort": [
      { "title.keyword": "asc" }
    ]
  }'
```

Another option is `constant_score`, which wraps a `filter` and assigns every matching document a fixed score (default `1.0`):

```json
{
  "query": {
    "constant_score": {
      "filter": { "term": { "year": 1995 } },
      "boost": 1.2
    }
  }
}
```

## Key takeaways

- Put exact-match, range, and existence checks in `filter` or `must_not` so Elasticsearch skips BM25 scoring.
- Filter-context clauses are automatically cached as per-segment bitsets, speeding up repeated queries.
- Reserve `must` and `should` for full-text queries where relevance ranking actually matters.

<div class="chapter-nav">
<a class="chapter-nav__item" href="036-sorting.html"><span>Previous</span><strong>36. Sorting</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="038-exercise-using-filters.html"><span>Next</span><strong>38. [Exercise] Using Filters</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
