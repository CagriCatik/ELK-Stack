---
title: "5. [Exercise] Generating Histogram Data"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 05 · EXERCISE</div>

# 5. [Exercise] Generating Histogram Data



In this exercise, you will use `histogram` and `range` aggregations on the `movies` index to analyze how release years are distributed across the dataset.

## Your task

Using `curl` (or Kibana Dev Tools) against `http://127.0.0.1:9200/movies/_search`:

1. **Decade histogram (gap-free):** Build a `histogram` aggregation on `year` with an interval of `10`. Include empty decades between `1920` and `2020` using `min_doc_count` and `extended_bounds`. Set `size: 0` so no individual documents are returned.
2. **Filtered 5-year histogram:** Filter the query to only `Sci-Fi` movies (`genre.keyword`) and aggregate `year` with an interval of `5` (omit empty buckets).
3. **Custom era ranges:** Replace the histogram with a `range` aggregation on `year` that groups all movies into three labeled buckets:
   - `"classic"`: before `1980`
   - `"modern"`: `1980` (inclusive) to `2000` (exclusive)
   - `"recent"`: `2000` and later

## Walkthrough

<details>
<summary>Show solution</summary>

### 1. Gap-free decade histogram

```bash
curl -s -X GET "http://127.0.0.1:9200/movies/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "aggs": {
    "movies_by_decade": {
      "histogram": {
        "field": "year",
        "interval": 10,
        "min_doc_count": 0,
        "extended_bounds": {
          "min": 1920,
          "max": 2020
        }
      }
    }
  }
}'
```

### 2. Filtered 5-year histogram for Sci-Fi

```bash
curl -s -X GET "http://127.0.0.1:9200/movies/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "query": {
    "term": {
      "genre.keyword": "Sci-Fi"
    }
  },
  "aggs": {
    "scifi_5yr_histogram": {
      "histogram": {
        "field": "year",
        "interval": 5
      }
    }
  }
}'
```

### 3. Custom era `range` aggregation

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

Each bucket in the response reports `"key"`, `"from"` / `"to"` bounds, and `"doc_count"`.

</details>

## Why this matters

Every bar chart and distribution panel in Kibana Lens is powered by these exact `histogram` and `range` queries under the hood. Knowing how `min_doc_count: 0`, `extended_bounds`, and `query` scoping interact lets you build accurate distribution APIs and debug missing or skewed chart bars immediately.

<div class="chapter-nav">
<a class="chapter-nav__item" href="004-time-series.html"><span>Previous</span><strong>4. Time Series</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="006-nested-aggregations-part-1.html"><span>Next</span><strong>6. Nested Aggregations, Part 1</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 6</a></p>
