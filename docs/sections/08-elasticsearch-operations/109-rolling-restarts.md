---
title: "109. Rolling Restarts"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 109. Rolling Restarts



Whether you are upgrading Elasticsearch, patching the Linux kernel, or changing `elasticsearch.yml` / `jvm.options`, you can restart nodes **one at a time with zero downtime**—provided every index has at least `number_of_replicas: 1` and you follow the rolling restart sequence.

## Why Not Just Reboot a Node?

If you simply stop a node, the master waits `node_left.delayed_timeout` (1 minute by default) and then begins copying gigabytes of replica shards to other nodes. When the restarted node comes back up 2 minutes later, the cluster has to rebalance shards all over again—wasting disk I/O and network bandwidth.

A proper **rolling restart** pauses replica allocation while each node restarts.

## The Zero-Downtime Rolling Restart Procedure

### Step 1: Verify Cluster Health Is `green`
Never start a rolling restart on a `yellow` or `red` cluster—taking down a node holding the only copy of a shard causes downtime or data loss.

```bash
curl -s "http://127.0.0.1:9200/_cluster/health?pretty"
```

### Step 2: Restrict Shard Allocation to Primaries Only
Pause replica allocation so the cluster does not copy shards away from the node you are about to stop:

```bash
curl -X PUT "http://127.0.0.1:9200/_cluster/settings" \
  -H "Content-Type: application/json" \
  -d '{
  "persistent": {
    "cluster.routing.allocation.enable": "primaries"
  }
}'
```

> **Note.** Setting `"primaries"` (rather than `"none"`) allows primary shards to still be promoted or recovered if an unexpected failure occurs during maintenance.

### Step 3: Flush Translogs to Disk
Run a flush so Lucene commits in-memory translog operations to disk segments, making shard recovery near-instantaneous when the node rejoins:

```bash
curl -X POST "http://127.0.0.1:9200/_flush"
```

*(On Elasticsearch 7.x and earlier, `POST /_flush/synced` was used for idle indices; in 8.x+, `POST /_flush` suffices because sequence-number recovery handles fast resyncs automatically.)*

### Step 4: Stop, Upgrade/Patch, and Start One Node
On the target node (restart **data nodes first**, then **master-eligible nodes**, restarting the **active master last**):

```bash
sudo systemctl stop elasticsearch
# Perform OS/Elasticsearch upgrade or config change
sudo systemctl start elasticsearch
```

Confirm the node has rejoined via `GET /_cat/nodes?v`.

### Step 5: Re-enable Shard Allocation and Wait for `green`
Reset `cluster.routing.allocation.enable` to `null` (reverts to default `"all"`):

```bash
curl -X PUT "http://127.0.0.1:9200/_cluster/settings" \
  -H "Content-Type: application/json" \
  -d '{
  "persistent": {
    "cluster.routing.allocation.enable": null
  }
}'
```

Wait until the cluster returns to **`green`** before moving to the next node:

```bash
curl -s "http://127.0.0.1:9200/_cluster/health?wait_for_status=green&timeout=5m&pretty"
```

### Step 6: Repeat for Each Remaining Node
Repeat Steps 2–5 for every remaining node in the cluster.

## Key takeaways

- Only perform rolling restarts when the cluster is **`green`** and all indices have at least 1 replica.
- Set `cluster.routing.allocation.enable: "primaries"` before stopping a node to prevent unnecessary shard rebalancing.
- Run `POST /_flush` before stopping the service to speed up recovery.
- Always re-enable allocation (`null`) and wait for **`green`** health before restarting the next node.

<div class="chapter-nav">
<a class="chapter-nav__item" href="108-snapshot-lifecycle-management.html"><span>Previous</span><strong>108. Snapshot Lifecycle Management</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="110-uptime-monitoring-with-heartbeat.html"><span>Next</span><strong>110. Uptime Monitoring with Heartbeat</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
