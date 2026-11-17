---
title: "105. Failover in Action, Part 1"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 105. Failover in Action, Part 1



High availability in Elasticsearch relies on two coordinated mechanisms: **master election** (keeping cluster coordination alive) and **shard failover** (promoting replicas to primaries when a data node disappears).

## Master Election and Quorum

Elasticsearch uses a consensus protocol (built into the coordination layer since 7.0, replacing Zen Discovery) where master-eligible nodes form a **voting configuration** and require a **quorum** (`(N / 2) + 1`) to elect an active master and commit cluster-state updates.

- With **3 master-eligible nodes**, quorum is **2**. Losing 1 node triggers a sub-second election among the remaining 2, and the cluster stays fully operational.
- If a network partition isolates 1 master node from the other 2, the isolated node **cannot** reach quorum (`1 < 2`) and refuses to act as master—preventing **split-brain** (two masters accepting diverging writes).

Key `elasticsearch.yml` settings for cluster formation:

```yaml
cluster.name: prod-elk
node.name: es-master-01
node.roles: [ master ]
discovery.seed_hosts:
  - 10.0.1.11
  - 10.0.1.12
  - 10.0.1.13
# Only used on the very first cluster bootstrap:
cluster.initial_master_nodes:
  - es-master-01
  - es-master-02
  - es-master-03
```

## Primary and Replica Failover

Suppose you have a 3-node data cluster (`es-data-01`, `es-data-02`, `es-data-03`) holding `movies` with `number_of_shards: 1` and `number_of_replicas: 1`:
- **Primary shard `0` (`p`)** lives on `es-data-01`.
- **Replica shard `0` (`r`)** lives on `es-data-02`.

When `es-data-01` suddenly crashes or loses power:
1. The active master detects the missed heartbeat and removes `es-data-01` from the cluster state.
2. The master immediately **promotes the replica `0` on `es-data-02` to primary `0` (`p`)**.
3. Writes and reads to `movies` continue without interruption, though `_cluster/health` turns **`yellow`** because the new primary now lacks a replica.

## Delayed Allocation (`node_left.delayed_timeout`)

If `es-data-01` is only rebooting for 30 seconds, immediately copying a 40 GB replica onto `es-data-03` would waste massive disk and network I/O. By default, Elasticsearch waits **`1m`** (`index.unassigned.node_left.delayed_timeout`) before allocating a new replica elsewhere:

```bash
curl -X PUT "http://127.0.0.1:9200/movies/_settings" \
  -H "Content-Type: application/json" \
  -d '{
  "index.unassigned.node_left.delayed_timeout": "5m"
}'
```

- If `es-data-01` rejoins within the timeout, Elasticsearch syncs only the missed operations (via sequence numbers / retention leases) and restores **`green`** health in seconds.
- If `es-data-01` stays down past the timeout, the master allocates a fresh replica on `es-data-03` and copies the shard over the network until the cluster returns to **`green`**.

## Key takeaways

- Master election requires a **quorum** (`(N / 2) + 1`); deploy **3 master-eligible nodes** so the cluster survives 1 master failure without split-brain.
- When a data node fails, the master **promotes replica shards to primaries** immediately so reads and writes continue (`yellow` state).
- `index.unassigned.node_left.delayed_timeout` (default `1m`) prevents expensive full-shard copies during brief node restarts.

<div class="chapter-nav">
<a class="chapter-nav__item" href="104-troubleshooting-common-issues.html"><span>Previous</span><strong>104. Troubleshooting Common Issues</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="106-index-design-changes-grouping-splitting-and-shrinking-indices.html"><span>Next</span><strong>106. Index Design Changes (Grouping, Splitting, and Shrinking Indices)</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
