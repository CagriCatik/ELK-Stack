---
title: "99. Index Alias Rotation"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 99. Index Alias Rotation



Calendar-based naming (`logs-2026.11.17`) has a major flaw: traffic is rarely uniform. A quiet Sunday might produce 2 GB, while a Black Friday spike produces 200 GB—leaving you with both undersharded and oversharded indices. **Index alias rotation** solves this by decoupling the name your applications write to from the underlying physical indices, rotating to a fresh index based on **size, document count, or age**.

## How Aliases and `is_write_index` Work

An **alias** is a pointer to one or more indices. Applications read from and write to the alias (`logs-app`), never the physical index (`logs-app-000001`). When multiple indices share the same alias for reads, exactly **one** index is marked `"is_write_index": true` so Elasticsearch knows where to route incoming writes.

```text
           ┌──▶ logs-app-000001  (read-only)
logs-app ──┼──▶ logs-app-000002  (read-only)
           └──▶ logs-app-000003  (is_write_index: true) ◀── writes go here
```

## Setting Up Alias Rotation with `_rollover`

### 1. Bootstrap the Initial Index

Create the first index with a trailing 6-digit counter (`-000001`) and attach the write alias:

```bash
curl -X PUT "http://127.0.0.1:9200/logs-app-000001" \
  -H "Content-Type: application/json" \
  -d '{
  "aliases": {
    "logs-app": {
      "is_write_index": true
    }
  }
}'
```

> **Note.** The trailing `-000001` (or date math like `<logs-app-{now/d}-000001>`) is required so `_rollover` can auto-increment the name to `logs-app-000002` without you specifying a target name.

### 2. Trigger `_rollover` with Conditions

Call `_rollover` on the alias with one or more thresholds. Elasticsearch checks the current write index and **only** creates a new index if at least one condition is met:

```bash
curl -X POST "http://127.0.0.1:9200/logs-app/_rollover" \
  -H "Content-Type: application/json" \
  -d '{
  "conditions": {
    "max_age": "7d",
    "max_docs": 50000000,
    "max_primary_shard_size": "30gb"
  }
}'
```

When a threshold is exceeded, Elasticsearch atomically:
1. Creates `logs-app-000002` using matching index templates.
2. Flips `"is_write_index": false` on `logs-app-000001`.
3. Attaches `logs-app` with `"is_write_index": true` to `logs-app-000002`.

The response tells you whether a rollover occurred (`"rolled_over": true` or `false`) and which conditions matched.

## Manual Atomic Alias Swaps (`_aliases`)

You can also swap aliases manually—for example, when reindexing `movies-v1` to `movies-v2` with zero downtime. Because `_aliases` executes all actions in a **single atomic cluster-state update**, readers never see an empty or duplicate result set:

```bash
curl -X POST "http://127.0.0.1:9200/_aliases" \
  -H "Content-Type: application/json" \
  -d '{
  "actions": [
    { "remove": { "index": "movies-v1", "alias": "movies" } },
    { "add":    { "index": "movies-v2", "alias": "movies", "is_write_index": true } }
  ]
}'
```

## How Data Streams Automate This

If you use a **Data Stream** (introduced in the previous chapter), you do not need to manage `is_write_index` or `-000001` aliases manually—the data stream itself acts as the write/read abstraction, and **Index Lifecycle Management (ILM)** triggers `_rollover` automatically on your behalf.

## Key takeaways

- **Index aliases** decouple application endpoints from physical indices, enabling zero-downtime rotation and reindexing.
- `is_write_index: true` designates the single active write target among multiple indices sharing a read alias.
- `POST /<alias>/_rollover` rotates indices based on `max_primary_shard_size`, `max_docs`, or `max_age`—keeping shard sizes predictable regardless of traffic spikes.
- `POST /_aliases` performs atomic add/remove swaps for zero-downtime migrations.

<div class="chapter-nav">
<a class="chapter-nav__item" href="098-adding-indices-as-a-scaling-strategy.html"><span>Previous</span><strong>98. Adding Indices as a Scaling Strategy</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="100-index-lifecycle-management.html"><span>Next</span><strong>100. Index Lifecycle Management</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
