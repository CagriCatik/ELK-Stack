---
title: "32. JSON Search In-Depth"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03</div>

# 32. JSON Search In-Depth

The **JSON Query DSL** is Elasticsearch's primary search API. Instead of cramming logic into a URL, you send a structured JSON body to `/_search` (either `GET` or `POST` works; `POST` is often preferred by HTTP clients that disallow `GET` bodies).

## Anatomy of a Query DSL request

Every Query DSL request has a top-level `query` object, alongside optional top-level parameters such as `size`, `from`, `sort`, and `_source`:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match_all": {}
    },
    "size": 3
  }'
```

The `match_all` query matches every document in the index with a uniform `_score` of `1.0` and is useful for inspecting sample documents or combining with filters.

## Full-text vs. exact-value leaf queries

Choosing the right leaf query depends on how the target field is mapped:

| Query type | Target field | Analyzed? | Typical use case |
| :--- | :--- | :--- | :--- |
| `match` | `text` | Yes (uses field's search analyzer) | Human-readable titles, descriptions |
| `term` / `terms` | `keyword`, numbers, booleans, dates | No (exact token match) | IDs, status codes, exact genre tags |
| `range` | numbers, dates | No | `year >= 1995`, timestamps |

### `match` (analyzed full-text search)

When you run a `match` query on `title`, Elasticsearch analyzes `"Star Wars"` into `["star", "wars"]` and matches documents containing either token by default (`operator: "or"`):

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match": {
        "title": {
          "query": "Star Wars",
          "operator": "and"
        }
      }
    }
  }'
```

### `term` (exact, unanalyzed match)

`term` does **not** run the query string through an analyzer. If `genre` is mapped as `keyword` (or has a `.keyword` sub-field) and stores `"Sci-Fi"`, searching `"sci-fi"` with `term` will return zero hits because case matters:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "term": {
        "genre.keyword": "Sci-Fi"
      }
    }
  }'
```

> **Warning.** Never use `term` against a `text` field expecting to match a mixed-case or multi-word string. The `text` field's inverted index holds lowercased single tokens (`"sci"`, `"fi"`), so `term` on `"Sci-Fi"` will not match.

## Compound queries with `bool`

Real-world searches combine multiple criteria using the `bool` query, which exposes four distinct clauses:

- **`must`** — clauses that **must** match; contributes to `_score` (query context).
- **`should`** — optional clauses that **boost** `_score` if matched. (If there are no `must` or `filter` clauses, at least one `should` clause must match by default, controlled by `minimum_should_match`.)
- **`must_not`** — clauses that **must not** match; does not contribute to `_score` (filter context).
- **`filter`** — clauses that **must** match, but skip scoring and are eligible for filter caching (filter context).

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "bool": {
        "must": [
          { "match": { "title": "star" } }
        ],
        "should": [
          { "match": { "title": "wars" } }
        ],
        "must_not": [
          { "term": { "genre.keyword": "Documentary" } }
        ],
        "filter": [
          { "range": { "year": { "gte": 1975, "lte": 2005 } } }
        ]
      }
    }
  }'
```

In this query, every hit must contain `"star"` in `title`, must not have `Documentary` in `genre.keyword`, and must have a `year` between 1975 and 2005. Movies that also contain `"wars"` in `title` rank higher because of the `should` clause.

## Key takeaways

- JSON Query DSL sends structured search requests in the HTTP body, avoiding URL-encoding and length limits.
- Use `match` for analyzed `text` fields and `term`/`range` for exact `keyword` or numeric fields.
- Combine criteria with `bool` using `must`, `should`, `must_not`, and `filter` to control both matching logic and relevance scoring.

<div class="chapter-nav">
<a class="chapter-nav__item" href="031-query-lite-interface.html"><span>Previous</span><strong>31. "Query Lite" interface</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="033-phrase-matching.html"><span>Next</span><strong>33. Phrase Matching</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
