---
title: "1. Section 6 Intro"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 06</div>

# 1. Section 6 Intro



## Why aggregations matter

Searching Elasticsearch tells you **which** documents match a query. Aggregations tell you **what your dataset looks like as a whole**. Instead of fetching 500,000 log events or movie records into your application and looping over them in Python or JavaScript, Elasticsearch computes counts, averages, percentiles, histograms, and multi-level breakdowns directly on the data nodes and returns only the compact summary.

This is the engine behind every faceted search sidebar, analytics API, and Kibana dashboard.

## What you will learn in this section

Across the next seven chapters, you will move from basic summaries to multi-dimensional analytics:

1. **Buckets, metrics, and pipelines** — Understand the three core aggregation families (`terms`, `avg`, `stats`, `cardinality`, and `buckets_path` pipelines) and why `size: 0` is standard for analytics requests.
2. **Numeric histograms and ranges** — Group continuous numbers into uniform intervals (`histogram`) or custom boundaries (`range`).
3. **Time-series analysis** — Use `date_histogram` with `calendar_interval`, `fixed_interval`, `time_zone`, and `min_doc_count: 0` to build gap-free timelines.
4. **Hands-on histogram exercise** — Practice building decade histograms, filtered intervals, and custom ranges against the `movies` index.
5. **Sub-aggregations (buckets inside buckets)** — Nest metrics inside buckets, sort buckets by computed metrics, and build multi-level breakdowns.
6. **`nested` field aggregations** — Solve the array-of-objects flattening problem with `nested` mappings, `nested` aggregations, and `reverse_nested` rollups.

## Anatomy of an aggregation request

Every aggregation request uses the same top-level `aggs` (or `aggregations`) block alongside an optional `query`:

```bash
curl -s -X GET "http://127.0.0.1:9200/movies/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "query": {
    "range": { "year": { "gte": 2000 } }
  },
  "aggs": {
    "top_genres": {
      "terms": { "field": "genre.keyword", "size": 5 }
    }
  }
}'
```

- `"size": 0` tells Elasticsearch not to return individual `hits.hits` documents—you only pay for and receive the aggregation summary.
- `"query"` narrows the set of documents fed into `aggs` (here, movies released in or after `2000`).
- `"top_genres"` is a user-defined label you choose; Elasticsearch echoes that exact key under `"aggregations"` in the JSON response.

<div class="chapter-nav">
<a class="chapter-nav__item" href="../05-logstash-pipelines-and-xml-normalization/008-section-5-wrapup.html"><span>Previous</span><strong>8. Section 5 Wrapup</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="002-aggregations-buckets-and-metrics.html"><span>Next</span><strong>2. Aggregations, Buckets, and Metrics</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 6</a></p>
