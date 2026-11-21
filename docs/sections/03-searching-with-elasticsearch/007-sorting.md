---
title: "7. Sorting"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03</div>

# 7. Sorting

By default, Elasticsearch sorts search results in descending order of **`_score`**—a floating-point relevance score computed by BM25. When users want to sort by release year, title, or rating instead, you specify a `sort` array in the request body.

## Sorting by a field

To sort movies by `year` descending, and break ties by relevance `_score`:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match": { "title": "star" }
    },
    "sort": [
      { "year": { "order": "desc" } },
      { "_score": { "order": "desc" } }
    ]
  }'
```

> **Note.** When you sort by a field without including `_score` in `sort`, Elasticsearch skips computing `_score` altogether (returning `"_score": null`), which saves CPU.

## Why sorting on `text` fields fails

If you try to sort directly on `title` (mapped as `text`), Elasticsearch throws an `illegal_argument_exception`:

```text
Text fields are not optimised for operations that require per-document field data
like aggregations and sorting, so these operations are disabled by default.
```

Here is why:
1. A `text` field is broken into multiple tokens (`"Star Wars"` → `"star"`, `"wars"`). Which token would Elasticsearch sort by?
2. `text` fields do not build **doc values** (the on-disk columnar structure used for fast sorting and aggregations). Enabling `fielddata: true` loads the entire inverted index into JVM heap, which can trigger out-of-memory crashes.

Instead, sort on the **`keyword` sub-field** (`title.keyword`), which stores the original unanalyzed string and maintains doc values on disk:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": { "match": { "genre": "Sci-Fi" } },
    "sort": [
      { "title.keyword": { "order": "asc" } }
    ],
    "size": 5
  }'
```

## Multi-value fields and missing values

Documents can contain arrays (for example, `genre` having `["Action", "Adventure", "Sci-Fi"]`). When sorting on a multi-value field, use `mode` to tell Elasticsearch which value to pick:

| `mode` | Behavior |
| :--- | :--- |
| `min` | Pick the lowest value (default for `asc`) |
| `max` | Pick the highest value (default for `desc`) |
| `avg` / `sum` / `median` | Numeric fields only |

You can also control where documents missing the sort field appear using `missing` (`"_last"` or `"_first"`):

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": { "match_all": {} },
    "sort": [
      {
        "year": {
          "order": "desc",
          "missing": "_last"
        }
      }
    ]
  }'
```

## Key takeaways

- Default sorting is `_score` descending; adding `sort` without `_score` disables score calculation for better performance.
- Never sort on analyzed `text` fields; sort on a `keyword` sub-field (`title.keyword`) backed by on-disk doc values.
- Use `mode` for multi-value array fields and `missing` (`_first` / `_last`) to handle documents without a value.

<div class="chapter-nav">
<a class="chapter-nav__item" href="006-pagination.html"><span>Previous</span><strong>6. Pagination</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="008-more-with-filters.html"><span>Next</span><strong>8. More with Filters</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
