---
title: "6. Nested Aggregations, Part 1"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 06</div>

# 6. Nested Aggregations, Part 1



So far, every aggregation has sat at the top level of `aggs`. The real analytical power of Elasticsearch comes from **sub-aggregations**—nesting `aggs` inside a bucket aggregation so that metrics or further buckets are computed *independently for each parent bucket*.

## Metrics inside buckets

Suppose you want to know not just how many movies exist per genre, but also the **earliest, latest, and average release year** for each genre. Nest a `stats` metric inside a `terms` bucket:

```bash
curl -s -X GET "http://127.0.0.1:9200/movies/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "aggs": {
    "by_genre": {
      "terms": {
        "field": "genre.keyword",
        "size": 5,
        "order": { "year_stats.avg": "desc" }
      },
      "aggs": {
        "year_stats": {
          "stats": { "field": "year" }
        }
      }
    }
  }
}'
```

Notice `"order": { "year_stats.avg": "desc" }`: you can sort parent `terms` buckets by any single-value sub-aggregation metric (or a specific property of a multi-value metric like `year_stats.avg`).

## Buckets inside buckets

You can also nest bucket aggregations inside other bucket aggregations to build multi-dimensional breakdowns—for example, top genres broken down by decade:

```bash
curl -s -X GET "http://127.0.0.1:9200/movies/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "aggs": {
    "by_genre": {
      "terms": {
        "field": "genre.keyword",
        "size": 3
      },
      "aggs": {
        "by_decade": {
          "histogram": {
            "field": "year",
            "interval": 10
          }
        }
      }
    }
  }
}'
```

In a time-series context, the classic pattern is `date_histogram` (outer bucket) -> `terms` on `service.name` or `http.response.status_code` (inner bucket) -> `avg` on `latency_ms` (metric).

> **Beware of bucket explosion.** Every level of nested buckets multiplies the total bucket count (`outer_size × inner_size × ...`). Keep `size` small on inner `terms` aggregations so you do not hit `search.max_buckets` (default `65536`) or overwhelm coordinator memory.

## Targeted buckets with `filter`

A `filter` (or `filters`) bucket lets you compute a sub-aggregation on a specific subset of documents without filtering the entire request:

```bash
curl -s -X GET "http://127.0.0.1:9200/movies/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "aggs": {
    "post_2010": {
      "filter": { "range": { "year": { "gte": 2010 } } },
      "aggs": {
        "top_modern_genres": {
          "terms": { "field": "genre.keyword", "size": 5 }
        }
      }
    }
  }
}'
```

## Key takeaways

- Nesting `aggs` inside a bucket aggregation runs those sub-aggregations on the documents inside each bucket.
- You can sort `terms` buckets by a sub-aggregation metric using `order` (e.g., `"order": { "year_stats.avg": "desc" }`).
- Watch out for multiplicative bucket counts when nesting multiple `terms` or `histogram` buckets.

<div class="chapter-nav">
<a class="chapter-nav__item" href="005-exercise-generating-histogram-data.html"><span>Previous</span><strong>5. [Exercise] Generating Histogram Data</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="007-nested-aggregations-part-2.html"><span>Next</span><strong>7. Nested Aggregations, Part 2</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 6</a></p>
