---
title: "97. Choosing the Right Number of Shards"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 97. Choosing the Right Number of Shards



Every Elasticsearch index is divided into one or more **primary shards**, and each primary shard can have zero or more **replica shards**. Because a shard is a full Apache Lucene index under the hood, choosing the right shard count is the single most impactful capacity-planning decision you make before indexing data.

## Primary vs. Replica Shards

| Aspect | Primary Shard (`number_of_shards`) | Replica Shard (`number_of_replicas`) |
| --- | --- | --- |
| **Purpose** | Stores a partition of the index's documents; handles writes first | Exact copy of a primary shard; provides high availability and read scaling |
| **Mutability** | Fixed at index creation (requires `_reindex`, `_split`, or `_shrink` to change) | Dynamic—can be changed at any time via `_settings` |
| **Failure impact** | Losing a primary with no replica makes the cluster **red** (data loss) | Losing a replica makes the cluster **yellow** (data intact, reduced redundancy) |
| **Search throughput** | Participates in queries | Participates in queries (doubles read concurrency with 1 replica) |

You can adjust `number_of_replicas` on a live index at any time:

```bash
curl -X PUT "http://127.0.0.1:9200/movies/_settings" \
  -H "Content-Type: application/json" \
  -d '{
  "index": {
    "number_of_replicas": 1
  }
}'
```

## The 10–50 GB Rule of Thumb

For general-purpose search and logging workloads, aim for **average shard sizes between 10 GB and 50 GB**:

- **Too large (> 50–100 GB)**: Shard recovery and rebalancing after a node failure take a long time because massive Lucene segments must be copied across the network. Search concurrency on a single shard is also limited because a shard query runs on a single thread per shard (though concurrent segment search in newer versions helps).
- **Too small (< 1 GB) — Oversharding**: Each shard consumes JVM heap memory for Lucene segment metadata, FST term dictionaries, and cluster state entries, plus file descriptors and thread-pool overhead. A cluster with 10,000 tiny 5 MB shards wastes gigabytes of heap just tracking empty or near-empty indices.

> **Tip.** Keep the total shard count per node well below **20 shards per GB of JVM heap** (e.g., at most ~600 shards on a node with a 30 GB heap). Since Elasticsearch 7.x, the default `number_of_shards` is `1` (down from `5` in older versions) specifically to prevent accidental oversharding.

## Sizing Calculation Example

Suppose you expect **120 GB of primary log data per day** (excluding replicas) and want shards around **30 GB** each:

```text
120 GB / 30 GB per shard = 4 primary shards
```

With `number_of_replicas: 1`, that day's index uses **4 primary + 4 replica = 8 shards** (240 GB total disk across nodes). If you have 4 data nodes, each node holds 2 shards (1 primary, 1 replica, never on the same node).

## Inspecting Current Shard Sizes

Use `_cat/shards` to spot undersized or skewed shards across your cluster:

```bash
curl -s "http://127.0.0.1:9200/_cat/shards?v=true&s=store:desc&h=index,shard,prirep,state,docs,store,node"
```

```text
index          shard prirep state   docs  store node
logs-000004    0     p      STARTED 18420 28.4gb es-data-01
logs-000004    0     r      STARTED 18420 28.4gb es-data-02
movies         0     p      STARTED  9742  2.1mb es-data-01
```

If an index like `movies` is only 2.1 MB, `number_of_shards: 1` is the right choice—splitting it across 5 shards would add overhead with zero benefit.

## Key takeaways

- **Primary shards** partition data and are fixed at index creation; **replicas** provide failover and read scaling and can be changed dynamically.
- Target **10–50 GB per shard** for most workloads and stay below **~20 shards per GB of JVM heap**.
- **Oversharding** is a silent killer: thousands of tiny shards exhaust heap, bloat cluster state, and slow down master operations.
- Always check `_cat/shards` to verify that shard sizes and distribution match your hardware topology.

<div class="chapter-nav">
<a class="chapter-nav__item" href="096-section-8-intro.html"><span>Previous</span><strong>96. Section 8 Intro</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="098-adding-indices-as-a-scaling-strategy.html"><span>Next</span><strong>98. Adding Indices as a Scaling Strategy</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
