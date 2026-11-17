---
title: "34. [Exercise] Querying in Different Ways"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03 · EXERCISE</div>

# 34. [Exercise] Querying in Different Ways

Put what you have learned about URI search, `match`, `match_phrase`, `term`, and `bool` into practice against your `movies` index.

## Your task

Write and run Elasticsearch queries for each of the following scenarios:

1. **URI search (Query Lite):** Find movies with `"trek"` in the `title` released in `1982` using `?q=`.
2. **Exact phrase search:** Using JSON Query DSL, find movies whose `title` contains the exact phrase `"star wars"`.
3. **Phrase with `slop`:** Find movies matching `"star hope"` in `title` with enough `slop` to match `"Star Wars: A New Hope"`.
4. **Compound `bool` query:** Find movies that:
   - **must** match `"star"` in `title`,
   - **must** have `Sci-Fi` in `genre.keyword`,
   - **must not** be released before `1980` (hint: `range` inside `must_not` or `filter`),
   - **should** boost movies with `"trek"` in `title`.

## Walkthrough

<details>
<summary>Show solution</summary>

1. **URI search (Query Lite):**

```bash
curl -s -X GET "http://127.0.0.1:9200/movies/_search?q=title:trek+AND+year:1982&pretty"
```

2. **Exact phrase search:**

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match_phrase": {
        "title": "star wars"
      }
    }
  }'
```

3. **Phrase with `slop`:**

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match_phrase": {
        "title": {
          "query": "star hope",
          "slop": 3
        }
      }
    }
  }'
```

4. **Compound `bool` query:**

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "bool": {
        "must": [
          { "match": { "title": "star" } }
        ],
        "filter": [
          { "term": { "genre.keyword": "Sci-Fi" } }
        ],
        "must_not": [
          { "range": { "year": { "lt": 1980 } } }
        ],
        "should": [
          { "match": { "title": "trek" } }
        ]
      }
    }
  }'
```

</details>

## Why this matters

Expressing the same business question in multiple ways reveals how Elasticsearch separates **analyzed full-text matching** (`match`, `match_phrase`) from **exact structured constraints** (`term`, `range` in `filter`/`must_not`). Choosing the right clause keeps your queries both accurate and fast.

<div class="chapter-nav">
<a class="chapter-nav__item" href="033-phrase-matching.html"><span>Previous</span><strong>33. Phrase Matching</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="035-pagination.html"><span>Next</span><strong>35. Pagination</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
