---
title: "9. Troubleshooting Common Issues"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 09</div>

# 9. Troubleshooting Common Issues



When an Elasticsearch cluster degrades—turning `yellow` or `red`, rejecting writes, or throwing memory exceptions—having a systematic diagnostic workflow saves precious minutes during an incident.

## 1. Yellow or Red Cluster: Unassigned Shards

Whenever `_cluster/health` reports `yellow` or `red`, do not guess. Ask Elasticsearch **why** a shard cannot be allocated using the **Cluster Allocation Explain API**:

```bash
curl -s "http://127.0.0.1:9200/_cluster/allocation/explain?pretty"
```

Common root causes revealed by `_cluster/allocation/explain`:
- **Single-node cluster with `number_of_replicas: 1`**: A replica can never be placed on the same node as its primary. Fix by adding a node or setting `number_of_replicas: 0` in dev.
- **Disk watermark exceeded**: All eligible nodes are above the low (`85%`) or high (`90%`) disk watermark.
- **Allocation disabled**: Someone left `cluster.routing.allocation.enable: "primaries"` or `"none"` after maintenance.
- **Max shards per node reached**: Default `cluster.max_shards_per_node` is `1000` (preventing runaway oversharding).

If a cluster is `red` because a node crashed and will never return, and no replica exists, you may have to delete the corrupt/unrecoverable index and restore from a snapshot—or as a last resort use `_cluster/reroute` (`allocate_empty_primary`, which acknowledges data loss).

## 2. Disk Watermarks and `FORBIDDEN/12/index read-only`

Elasticsearch protects nodes from running out of disk using three watermarks:

| Watermark | Default | Behavior |
| --- | --- | --- |
| **Low** | `85%` | Stops allocating **new** shards to the node. |
| **High** | `90%` | Actively **relocates** shards away from the node to other nodes. |
| **Flood Stage** | `95%` | Forces every index with a shard on that node into **read-only (`read_only_allow_delete`)** mode, rejecting all writes with HTTP `429` / `403`. |

Once you free disk space (or add nodes) and drop below the high watermark, Elasticsearch 7.4+ automatically clears `read_only_allow_delete`. On older versions or if stuck, clear it manually:

```bash
curl -X PUT "http://127.0.0.1:9200/_all/_settings" \
  -H "Content-Type: application/json" \
  -d '{
  "index.blocks.read_only_allow_delete": null
}'
```

## 3. Circuit Breakers (`circuit_breaking_exception`)

To prevent `OutOfMemoryError` crashes, Elasticsearch estimates memory before executing queries or aggregations. If an operation would push heap past the **parent circuit breaker** (`indices.breaker.total.limit`, default `95%` of JVM heap with real-memory tracking), Elasticsearch aborts the request with:

```text
[parent] Data too large, data for [<http_request>] would be [31.2gb/33500mb], which is larger than the limit of [30.4gb/32641mb]
```

**How to fix it:**
- Reduce shard count (oversharding wastes baseline heap).
- Avoid unbounded `fielddata` on `text` fields (use `keyword` / `doc_values` instead).
- Break huge `terms` aggregations or deep `from`/`size` pagination into `search_after` or composite aggregations.

## 4. Thread Pool Rejections (`429 Too Many Requests`)

If bulk indexing or concurrent searches outpace CPU/disk capacity, the `write` or `search` queue fills up and Elasticsearch returns `429 EsRejectedExecutionException`.

- **Fix**: Implement **exponential backoff** in your clients (Logstash, Beats, and Elastic clients do this automatically), increase `refresh_interval` (e.g., `30s`) during heavy bulk loads, or scale out data nodes. Never blindly crank queue sizes to `10000`—that only masks backpressure and spikes heap usage.

## Key takeaways

- Always run `GET /_cluster/allocation/explain` first when diagnosing `yellow` or `red` clusters.
- Understand the **85% / 90% / 95% disk watermarks**; hitting 95% triggers `read_only_allow_delete` across affected indices.
- `circuit_breaking_exception` protects the JVM from OOM—fix the underlying heap pressure (oversharding, heavy aggregations, `fielddata`) rather than raising breaker limits.
- Handle `429` queue rejections with **client backoff** and bulk tuning, not oversized queues.

<div class="chapter-nav">
<a class="chapter-nav__item" href="008-monitoring.html"><span>Previous</span><strong>8. Monitoring</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="010-failover-in-action-part-1.html"><span>Next</span><strong>10. Failover in Action, Part 1</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 9</a></p>
