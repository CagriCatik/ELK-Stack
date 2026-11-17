---
title: "75. Time Series"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 05</div>

# 75. Time Series



Time-series analytics—traffic per minute, errors per hour, orders per month—is the most common workload in the Elastic Stack. Elasticsearch handles this with the **`date_histogram`** bucket aggregation, which is purpose-built for `date` and `date_nanos` fields.

## `calendar_interval` vs `fixed_interval`

When configuring `date_histogram`, you must choose between two interval parameters:

| Parameter | How it works | Valid units | Example use case |
| :--- | :--- | :--- | :--- |
| **`calendar_interval`** | Calendar-aware; respects varying month lengths (28–31 days), leap years, and DST | `minute` (`1m`), `hour` (`1h`), `day` (`1d`), `week` (`1w`), `month` (`1M`), `quarter` (`1q`), `year` (`1y`) | Daily or monthly business reports |
| **`fixed_interval`** | Exact SI-unit multiples of milliseconds; never varies | `ms`, `s`, `m`, `h`, `d` (e.g., `30s`, `5m`, `12h`, `7d`) | High-resolution metrics, 5-minute rolling charts |

> **Rule of thumb.** `calendar_interval` only accepts a quantity of `1` (e.g., `1d`, `1M`, not `5m` or `2h`). Whenever you need multi-unit intervals like `5m`, `15m`, or `6h`, use `fixed_interval`.

## Basic `date_histogram` example

Here is a daily log volume breakdown over the last 7 days:

```bash
curl -s -X GET "http://127.0.0.1:9200/logs-nginx/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "query": {
    "range": {
      "@timestamp": { "gte": "now-7d/d", "lte": "now" }
    }
  },
  "aggs": {
    "events_per_day": {
      "date_histogram": {
        "field": "@timestamp",
        "calendar_interval": "day",
        "format": "yyyy-MM-dd",
        "min_doc_count": 0,
        "extended_bounds": {
          "min": "now-7d/d",
          "max": "now/d"
        }
      }
    }
  }
}'
```

Key options used here:

- **`min_doc_count: 0`** + **`extended_bounds`**: Ensures days with zero log events still appear with `doc_count: 0` instead of vanishing from your time-series line chart. Date math like `now-7d/d` works directly inside `extended_bounds`.
- **`format`**: Controls `key_as_string` in the response (e.g., `"2026-11-17"`).

## Handling time zones with `time_zone`

Elasticsearch stores all dates internally in UTC. If you run `"calendar_interval": "day"` without a `time_zone`, buckets split at `00:00:00 UTC`. For a business in New York or Berlin, midnight UTC falls in the middle of the evening or afternoon, skewing daily totals.

Add `"time_zone"` using an IANA zone ID or ISO-8601 offset:

```json
"date_histogram": {
  "field": "@timestamp",
  "calendar_interval": "day",
  "time_zone": "America/New_York"
}
```

When `time_zone` is paired with `calendar_interval`, Elasticsearch automatically adjusts bucket boundaries on Daylight Saving Time transitions (creating 23-hour or 25-hour days as needed).

## Key takeaways

- Use `calendar_interval` for human calendar units (`day`, `month`, `year`) and `fixed_interval` for arbitrary multiples (`5m`, `30s`, `6h`).
- Always pair `min_doc_count: 0` with `extended_bounds` for gap-free time-series charts.
- Specify `time_zone` (e.g., `"America/New_York"`) when daily or hourly buckets must align with local time rather than UTC.

<div class="chapter-nav">
<a class="chapter-nav__item" href="074-histograms.html"><span>Previous</span><strong>74. Histograms</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="076-exercise-generating-histogram-data.html"><span>Next</span><strong>76. [Exercise] Generating Histogram Data</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 5</a></p>
