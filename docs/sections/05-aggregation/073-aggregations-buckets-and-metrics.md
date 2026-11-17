---
title: "73. Aggregations, Buckets, and Metrics"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 05</div>

# 73. Aggregations, Buckets, and Metrics



Elasticsearch groups aggregations into three families. Understanding which family an aggregation belongs to tells you whether it **creates groups**, **computes numbers**, or **post-processes other aggregations**.

| Family | What it does | Examples |
| :--- | :--- | :--- |
| **Bucket** | Partitions documents into groups (buckets) based on field values, ranges, or filters | `terms`, `histogram`, `date_histogram`, `range`, `filter` |
| **Metric** | Computes a numeric summary over a set of documents (the whole query or each bucket) | `avg`, `sum`, `min`, `max`, `stats`, `cardinality` |
| **Pipeline** | Operates on the output of *other* aggregations rather than raw documents | `avg_bucket`, `sum_bucket`, `derivative`, `moving_fn` |

## Bucket aggregations: `terms`

The `terms` aggregation creates one bucket per unique value in a field, ordered by document count descending by default:

```bash
curl -s -X GET "http://127.0.0.1:9200/movies/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "aggs": {
    "movies_by_genre": {
      "terms": {
        "field": "genre.keyword",
        "size": 10
      }
    }
  }
}'
```

> **Use `keyword`, not `text`.** Aggregations require `doc_values` (columnar on-disk storage) to group values efficiently. `text` fields do not have `doc_values` enabled by default and will throw a `Fielddata is disabled` error unless you target the `.keyword` subfield.

A `terms` response also includes two accuracy fields:

- `doc_count_error_upper_bound`: The maximum number of documents that could be missing from a bucket's count because each shard only returns its local top terms (`shard_size`).
- `sum_other_doc_count`: The total number of documents belonging to terms that did not make the top `size` list.

## Metric aggregations: `avg`, `stats`, and `cardinality`

Metric aggregations compute values across all documents matching the `query` (or inside a parent bucket). You can run multiple metric aggregations side by side in a single request:

```bash
curl -s -X GET "http://127.0.0.1:9200/movies/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "query": {
    "term": { "genre.keyword": "Sci-Fi" }
  },
  "aggs": {
    "avg_release_year": {
      "avg": { "field": "year" }
    },
    "year_stats": {
      "stats": { "field": "year" }
    },
    "unique_titles": {
      "cardinality": { "field": "title.keyword" }
    }
  }
}'
```

- **`avg` / `sum` / `min` / `max`**: Single-value metrics.
- **`stats`**: Returns `count`, `min`, `max`, `avg`, and `sum` in one pass. (Use `extended_stats` if you also need variance and standard deviation.)
- **`cardinality`**: Estimates the number of distinct values using the **HyperLogLog++** algorithm. It trades exactness for bounded memory; you can tune accuracy with `precision_threshold` (default `3000`, max `40000`).

## Pipeline aggregations

Pipeline aggregations read the output of sibling or parent aggregations via `buckets_path` instead of scanning documents. For example, to compute the average number of movies per genre across the top 10 genres:

```bash
curl -s -X GET "http://127.0.0.1:9200/movies/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "aggs": {
    "movies_by_genre": {
      "terms": { "field": "genre.keyword", "size": 10 }
    },
    "avg_movies_per_genre": {
      "avg_bucket": {
        "buckets_path": "movies_by_genre>_count"
      }
    }
  }
}'
```

Notice the `_count` special path, which references each bucket's `doc_count`.

## Key takeaways

- Always set `"size": 0` when you only need aggregation results and not individual documents.
- Target `.keyword` (or numeric/date/boolean) fields for `terms` aggregations—never analyzed `text` fields.
- Use `stats` to get five metrics in a single pass, and `cardinality` for memory-safe approximate distinct counts.
- Combine `query` + `aggs` to scope aggregations to a specific subset of your index.

<div class="chapter-nav">
<a class="chapter-nav__item" href="072-section-5-intro.html"><span>Previous</span><strong>72. Section 5 Intro</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="074-histograms.html"><span>Next</span><strong>74. Histograms</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 5</a></p>
