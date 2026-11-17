---
title: "106. Index Design Changes (Grouping, Splitting, and Shrinking Indices)"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 106. Index Design Changes (Grouping, Splitting, and Shrinking Indices)



Even with careful planning, requirements change. An index you created with 1 shard might grow to 200 GB, an index with 10 shards might hold only 500 MB, or you might need to change a field's mapping from `text` to `keyword`. Elasticsearch provides three core APIs for reshaping indices: **`_reindex`**, **`_split`**, and **`_shrink`**.

| Operation | Use Case | Mapping Changes? | Speed |
| --- | --- | --- | --- |
| **`_reindex`** | Any shard count change, grouping small indices, changing mappings/analyzers | **Yes** | Slowest (re-parses and re-indexes every document) |
| **`_split`** | Increasing primary shards by an integer factor (e.g., `2` → `4` or `6`) | No | Fast (hard-links Lucene segments, then filters) |
| **`_shrink`** | Decreasing primary shards to a factor of current count (e.g., `6` → `2` or `1`) | No | Very fast (hard-links segments on one node) |

## 1. Grouping or Changing Mappings with `_reindex`

`_reindex` reads `_source` from one or more source indices and indexes into a new destination index (which must already have `_source` enabled on the source). You can also **group** multiple small monthly indices into a single yearly index:

```bash
# 1. Create destination index with desired shards and mappings
curl -X PUT "http://127.0.0.1:9200/logs-2026" \
  -H "Content-Type: application/json" \
  -d '{
  "settings": { "number_of_shards": 2, "number_of_replicas": 1 }
}'

# 2. Reindex multiple small indices into logs-2026 asynchronously
curl -X POST "http://127.0.0.1:9200/_reindex?wait_for_completion=false" \
  -H "Content-Type: application/json" \
  -d '{
  "source": { "index": ["logs-2026.01", "logs-2026.02", "logs-2026.03"] },
  "dest":   { "index": "logs-2026" }
}'
```

Use `wait_for_completion=false` for large indices so the HTTP request returns a `task` ID you can poll via `GET /_tasks/<task_id>`.

## 2. Increasing Shards with `_split`

To split an index, the source index must be **read-only** (`index.blocks.write: true`), and the new `number_of_shards` must be a **multiple** of the original count (and a factor of `index.number_of_routing_shards`):

```bash
# 1. Block writes on the source index
curl -X PUT "http://127.0.0.1:9200/movies-v1/_settings" \
  -H "Content-Type: application/json" \
  -d '{ "index.blocks.write": true }'

# 2. Split 1 primary shard into 4
curl -X POST "http://127.0.0.1:9200/movies-v1/_split/movies-v2" \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "index.number_of_shards": 4
  }
}'
```

## 3. Reducing Shards with `_shrink`

Shrinking is common in ILM's **warm** phase to consolidate multi-shard hot indices into a single shard. All primary shards of the source index must first be relocated onto **a single node**, and writes must be blocked:

```bash
# 1. Block writes and move all shards of logs-000001 to node es-data-01
curl -X PUT "http://127.0.0.1:9200/logs-000001/_settings" \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "index.routing.allocation.require._name": "es-data-01",
    "index.blocks.write": true
  }
}'

# 2. Once all shards are on es-data-01, shrink 4 shards -> 1 shard
curl -X POST "http://127.0.0.1:9200/logs-000001/_shrink/logs-000001-shrunk" \
  -H "Content-Type: application/json" \
  -d '{
  "settings": {
    "index.number_of_shards": 1,
    "index.number_of_replicas": 1
  }
}'
```

> **Tip.** Always combine `_reindex`, `_split`, or `_shrink` with an **atomic alias swap** (`POST /_aliases`) so applications keep querying the same alias without downtime, then delete the old index once verified.

## Key takeaways

- Use **`_reindex`** when you need to change **mappings**, transform documents with an ingest pipeline, or **group** multiple small indices into one.
- Use **`_split`** to multiply primary shards and **`_shrink`** to consolidate shards when mappings don't need to change—both are far faster than `_reindex`.
- Both `_split` and `_shrink` require `index.blocks.write: true`; `_shrink` also requires all primary shards on the same node.
- Swap aliases atomically with `_aliases` for zero-downtime cutovers.

<div class="chapter-nav">
<a class="chapter-nav__item" href="105-failover-in-action-part-1.html"><span>Previous</span><strong>105. Failover in Action, Part 1</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="107-snapshots.html"><span>Next</span><strong>107. Snapshots</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
