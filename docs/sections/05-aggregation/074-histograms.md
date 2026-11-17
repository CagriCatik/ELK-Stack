---
title: "74. Histograms"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 05</div>

# 74. Histograms



While `terms` groups discrete values, **`histogram`** and **`range`** group continuous numeric fields (prices, ages, release years, response times, ratings) into numeric buckets.

## The `histogram` aggregation

A `histogram` divides a numeric field into fixed-width intervals. Each bucket key represents the inclusive lower bound of that interval:

```bash
curl -s -X GET "http://127.0.0.1:9200/movies/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "aggs": {
    "movies_per_decade": {
      "histogram": {
        "field": "year",
        "interval": 10
      }
    }
  }
}'
```

With `interval: 10`, a movie from `1994` lands in bucket `1990`, and a movie from `2000` lands in bucket `2000`.

### Filling empty buckets with `min_doc_count` and `extended_bounds`

By default, `histogram` omits empty buckets (`min_doc_count: 1`). For bar charts, skipping empty decades or ratings distorts the x-axis. Set `min_doc_count: 0` alongside `extended_bounds` to guarantee a continuous axis:

```bash
curl -s -X GET "http://127.0.0.1:9200/ratings/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "aggs": {
    "rating_distribution": {
      "histogram": {
        "field": "rating",
        "interval": 0.5,
        "min_doc_count": 0,
        "extended_bounds": {
          "min": 0.5,
          "max": 5.0
        }
      }
    }
  }
}'
```

> **Warning.** Never combine `min_doc_count: 0` with a tiny `interval` on a wide numeric range without `extended_bounds`. Generating millions of empty buckets can trigger `too_many_buckets_exception` (default limit: `65536` buckets per request in Elasticsearch 8.x) and exhaust heap memory.

You can also shift bucket boundaries using `offset` (e.g., `"interval": 10, "offset": 5` creates buckets at `1985`, `1995`, `2005`).

## The `range` aggregation

When your buckets are **not** uniform—such as "Classic", "Modern", and "Recent" eras, or HTTP latency tiers (`<100ms`, `100-500ms`, `>500ms`)—use `range` instead of `histogram`.

In `range`, `from` is **inclusive** and `to` is **exclusive** (`[from, to)`):

```bash
curl -s -X GET "http://127.0.0.1:9200/movies/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "aggs": {
    "movie_eras": {
      "range": {
        "field": "year",
        "ranges": [
          { "key": "classic", "to": 1980 },
          { "key": "modern", "from": 1980, "to": 2000 },
          { "key": "recent", "from": 2000 }
        ]
      }
    }
  }
}'
```

Providing `"key"` gives each bucket a human-readable label instead of a generated string like `"1980.0-2000.0"`.

## Choosing between `terms`, `histogram`, and `range`

| Aggregation | Best for | Bucket width | Empty buckets |
| :--- | :--- | :--- | :--- |
| `terms` | Discrete categories (`genre.keyword`, `status`) | N/A (exact values) | Never included |
| `histogram` | Continuous numbers with even spacing (`year`, `bytes`) | Fixed (`interval`) | Optional (`min_doc_count: 0`) |
| `range` | Custom, uneven tiers (eras, SLA latency bands) | Arbitrary `[from, to)` | Always included |

## Key takeaways

- Use `histogram` with `interval` for evenly spaced numeric buckets, and `range` for custom `[from, to)` tiers.
- Set `min_doc_count: 0` and `extended_bounds` when plotting histograms so empty intervals still appear on the chart.
- Remember that `from` is inclusive and `to` is exclusive in `range` aggregations.

<div class="chapter-nav">
<a class="chapter-nav__item" href="073-aggregations-buckets-and-metrics.html"><span>Previous</span><strong>73. Aggregations, Buckets, and Metrics</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="075-time-series.html"><span>Next</span><strong>75. Time Series</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 5</a></p>
