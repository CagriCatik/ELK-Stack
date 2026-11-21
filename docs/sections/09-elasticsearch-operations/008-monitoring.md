---
title: "8. Monitoring"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 09</div>

# 8. Monitoring



You cannot tune or troubleshoot what you cannot see. Elasticsearch exposes rich real-time health, resource, and performance telemetry through its REST APIs (`_cluster`, `_cat`, `_nodes`) and through **Stack Monitoring** in Kibana.

## Quick Health Checks with `_cluster/health`

The fastest way to check cluster state is `_cluster/health`:

```bash
curl -s "http://127.0.0.1:9200/_cluster/health?pretty"
```

```json
{
  "cluster_name": "prod-elk",
  "status": "green",
  "number_of_nodes": 6,
  "number_of_data_nodes": 3,
  "active_primary_shards": 42,
  "active_shards": 84,
  "relocating_shards": 0,
  "initializing_shards": 0,
  "unassigned_shards": 0,
  "active_shards_percent_as_number": 100.0
}
```

| Status | Meaning |
| --- | --- |
| `green` | All primary **and** replica shards are allocated and active. |
| `yellow` | All **primary** shards are active, but one or more **replica** shards are unassigned (no data loss, reduced HA). |
| `red` | At least one **primary** shard is unassigned (some data is unavailable). |

## Inspecting Nodes and Shards with `_cat`

The `_cat` APIs format cluster state as human-readable tables for terminal workflows:

```bash
# Node CPU, heap %, load average, disk used %, and roles
curl -s "http://127.0.0.1:9200/_cat/nodes?v=true&h=name,node.role,heap.percent,ram.percent,cpu,load_1m,disk.used_percent"
```

```text
name       node.role heap.percent ram.percent cpu load_1m disk.used_percent
es-master1 m                   24          61   4    0.22             18.40
es-data1   dh                  62          94  38    2.45             67.12
es-data2   dh                  59          95  35    2.18             66.85
```

And to see shard allocation, size, and any unassigned shards:

```bash
curl -s "http://127.0.0.1:9200/_cat/shards?v=true&h=index,shard,prirep,state,docs,store,node,unassigned.reason"
```

## Deep Metrics with `_nodes/stats`

For programmatic alerting or deep inspection of JVM GC pauses, thread-pool rejections, and circuit breakers, query `_nodes/stats`:

```bash
curl -s "http://127.0.0.1:9200/_nodes/stats/jvm,thread_pool,breakers?pretty"
```

Watch these critical indicators:
- **JVM Heap Usage (`heap_used_percent`)**: Sustained > 75–85% indicates heap pressure or oversharding; watch old-gen GC frequency and duration.
- **Thread Pool Rejections (`thread_pool.write.rejected`, `search.rejected`)**: Non-zero values mean requests are hitting queue limits and being dropped (`429 Too Many Requests`).
- **Disk Usage (`disk.used_percent`)**: Approaching `85%` (low watermark) or `90%` (high watermark) blocks shard allocation.
- **Search & Indexing Latency**: Compare `query_time_in_millis / query_total` and `index_time_in_millis / index_total` over time.

## Elastic Stack Monitoring in Kibana

While `_cat` gives a point-in-time snapshot, **Stack Monitoring** in Kibana tracks historical trends across Elasticsearch, Logstash, Kibana, and Beats:

- **Production best practice**: Collect monitoring metrics using **Metricbeat** (`elasticsearch-xpack` module) or **Elastic Agent** and ship them to a **separate monitoring cluster**. That way, if your primary cluster goes `red` or becomes unresponsive, your monitoring dashboards and alerts remain online.

## Key takeaways

- `_cluster/health` gives an instant `green` / `yellow` / `red` summary of primary and replica shard availability.
- `_cat/nodes` and `_cat/shards` are your go-to CLI tools for checking heap pressure, CPU, disk usage, and shard state.
- Monitor **heap usage**, **GC pause duration**, **thread pool rejections**, and **disk watermarks** continuously.
- In production, ship **Stack Monitoring** telemetry via Metricbeat or Elastic Agent to a **dedicated monitoring cluster**.

<div class="chapter-nav">
<a class="chapter-nav__item" href="007-heap-sizing.html"><span>Previous</span><strong>7. Heap Sizing</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="009-troubleshooting-common-issues.html"><span>Next</span><strong>9. Troubleshooting Common Issues</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 9</a></p>
