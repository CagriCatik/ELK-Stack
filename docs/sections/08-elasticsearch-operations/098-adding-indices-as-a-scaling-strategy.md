---
title: "98. Adding Indices as a Scaling Strategy"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 98. Adding Indices as a Scaling Strategy



Because `number_of_shards` is fixed when an index is created, you cannot simply "add a shard" to a single monolithic index as your data grows. Instead, Elasticsearch scales horizontally by **creating new indices over time**—each with an appropriate shard count—so older data can be aged out or moved to cheaper storage without touching active writes.

## Why Time-Based Indices Beat Monolithic Indices

Consider a log platform ingesting 50 GB/day for 90 days (4.5 TB total):

| Approach | Outcome |
| --- | --- |
| **Single index (`logs-all`)** | Must guess shard count on day 1; deleting old logs requires expensive `_delete_by_query` (creates tombstones and forces heavy segment merges) |
| **Time-based indices (`logs-2026.11.17`)** | Each day/week gets right-sized shards; retiring old data is an instant `DELETE /logs-2026.08.19` metadata operation |

Time-based indices also improve query performance: when Kibana queries `last 24 hours` with a range filter on `@timestamp`, Elasticsearch checks each index's min/max `@timestamp` metadata and **skips shards outside the time window** (`can_match` phase).

## Index Templates (`_index_template`)

To ensure every newly created daily or rolling index gets consistent mappings and shard settings automatically, define a composable **index template**:

```bash
curl -X PUT "http://127.0.0.1:9200/_index_template/app-logs-template" \
  -H "Content-Type: application/json" \
  -d '{
  "index_patterns": ["app-logs-*"],
  "priority": 200,
  "template": {
    "settings": {
      "number_of_shards": 2,
      "number_of_replicas": 1,
      "refresh_interval": "5s"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "service":    { "type": "keyword" },
        "level":      { "type": "keyword" },
        "message":    { "type": "text" }
      }
    }
  }
}'
```

## Data Streams: The Modern Default for Append-Only Data

In Elasticsearch 7.9+ and 8.x/9.x, **Data Streams** are the recommended way to manage time-series data (logs, metrics, traces). A Data Stream is a single logical endpoint backed by hidden, auto-generated indices (`.ds-<name>-YYYY.MM.DD-000001`).

Add `"data_stream": {}` to your index template to enable it:

```bash
curl -X PUT "http://127.0.0.1:9200/_index_template/logs-stream-template" \
  -H "Content-Type: application/json" \
  -d '{
  "index_patterns": ["logs-app-*"],
  "data_stream": {},
  "priority": 300,
  "template": {
    "settings": {
      "number_of_shards": 2,
      "number_of_replicas": 1
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "message":    { "type": "text" }
      }
    }
  }
}'
```

When you index a document with `@timestamp` into `logs-app-prod`, Elasticsearch automatically creates the data stream and routes writes to its current write index:

```bash
curl -X POST "http://127.0.0.1:9200/logs-app-prod/_doc" \
  -H "Content-Type: application/json" \
  -d '{
  "@timestamp": "2026-11-17T18:00:00Z",
  "message": "Checkout service started"
}'
```

> **Note.** Data streams require every document to include a `@timestamp` field and only support append-only writes (`POST /<stream>/_doc` or `create` bulk actions). If you need in-place updates or deletes by ID, use a standard index with alias rotation instead.

## Choosing the Right Granularity

Avoid creating **daily indices for low-volume streams**. If a service only produces 50 MB/day, daily indices create 365 tiny 50 MB shards per year—classic oversharding. Use **weekly or monthly indices** (`logs-2026.11`), or better yet, **size-based rollover** (covered in the next chapter) so new indices are created only when shards reach your target size (e.g., 30–50 GB).

## Key takeaways

- Scaling by **adding indices over time** avoids guessing total multi-year shard counts upfront and makes retention a fast `DELETE` instead of `_delete_by_query`.
- **Index templates** (`_index_template`) guarantee consistent settings and mappings for every new index.
- **Data Streams** (`"data_stream": {}`) are the modern, built-in abstraction for append-only time-series data.
- Match index granularity to ingest volume—never create daily indices for megabyte-scale workloads.

<div class="chapter-nav">
<a class="chapter-nav__item" href="097-choosing-the-right-number-of-shards.html"><span>Previous</span><strong>97. Choosing the Right Number of Shards</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="099-index-alias-rotation.html"><span>Next</span><strong>99. Index Alias Rotation</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
