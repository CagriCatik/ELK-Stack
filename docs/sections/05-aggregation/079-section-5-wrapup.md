---
title: "79. Section 5 Wrapup"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 05</div>

# 79. Section 5 Wrapup



## What this section covered

In this section, you moved beyond returning matching documents to summarizing entire datasets inside Elasticsearch:

- **Three aggregation families:** Bucket aggregations (`terms`, `histogram`, `range`, `date_histogram`, `filter`) group documents; metric aggregations (`avg`, `stats`, `cardinality`) compute numbers; pipeline aggregations (`avg_bucket`) operate on other aggregations via `buckets_path`.
- **Histograms and ranges:** Grouped continuous numeric fields into fixed-width intervals (`histogram`) or custom `[from, to)` tiers (`range`), using `min_doc_count: 0` and `extended_bounds` to keep axes continuous.
- **Time-series analysis:** Built gap-free timelines with `date_histogram`, distinguishing calendar-aware `calendar_interval` from exact `fixed_interval`, and aligning daily buckets with `time_zone`.
- **Sub-aggregations:** Nested metrics and buckets inside parent buckets (`aggs` inside `aggs`), sorted buckets by sub-aggregation metrics, and guarded against bucket explosion.
- **`nested` field aggregations:** Prevented array-of-objects flattening with `"type": "nested"` mappings, `"nested": { "path": "..." }`, and `"reverse_nested"` rollups.

| Goal | Aggregation to use |
| :--- | :--- |
| Top N categories | `terms` (on `.keyword` / numeric / boolean) |
| Count, min, max, avg, sum in one call | `stats` |
| Approximate unique count | `cardinality` |
| Evenly spaced numeric buckets | `histogram` (`interval`, `extended_bounds`) |
| Custom numeric tiers | `range` (`from` inclusive, `to` exclusive) |
| Time-series timeline | `date_histogram` (`calendar_interval` / `fixed_interval`) |
| Correlated array-of-objects rollup | `nested` + `reverse_nested` |

## Where to next

Every aggregation pattern you wrote by hand in `curl` is what **Kibana** generates automatically when you explore data and build visualizations. In **Section 6: Using Kibana**, you will connect these concepts to Discover, Lens charts, and interactive Dashboards.

<div class="chapter-nav">
<a class="chapter-nav__item" href="078-nested-aggregations-part-2.html"><span>Previous</span><strong>78. Nested Aggregations, Part 2</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="../06-using-kibana/080-section-6-intro.html"><span>Next</span><strong>80. Section 6 Intro</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 5</a></p>
