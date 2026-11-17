---
title: "101. Choosing your Cluster's Hardware"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 101. Choosing your Cluster's Hardware



Elasticsearch performance is governed by four hardware resources: **storage I/O**, **memory**, **CPU**, and **network**. Sizing them poorly—especially skimping on disk speed or sharing master responsibilities with overloaded data nodes—causes cascading latency spikes under load.

## Storage: NVMe SSDs Over Spinning Disks

Lucene constantly writes segments on refresh, merges segments in the background, and reads inverted/columnar structures during queries. Disk I/O is the #1 bottleneck in most clusters:

- **Use local NVMe SSDs** for **hot** and **search-heavy** tiers. Avoid network-attached spinning disks (HDDs) or slow SANs for hot data; random I/O during segment merges will stall indexing.
- **Avoid RAID 5/6**: Parity writes degrade write throughput. Elasticsearch already provides redundancy via replica shards, so use **RAID 0** (or multiple `path.data` paths / JBOD) on local SSDs for maximum IOPS.
- **Keep 15–20% headroom** above the high disk watermark (`90%` by default) so segment merges have temporary scratch space.

## Memory: RAM Is for the OS Page Cache, Not Just Heap

A common mistake is giving all system RAM to the JVM heap. Elasticsearch relies heavily on the **operating system's filesystem page cache** to keep hot Lucene index files (`.tim`, `.doc`, `.dvd`) in memory off-heap:

- **64 GB RAM** is the sweet spot for general-purpose data nodes (~30–31 GB JVM heap + ~32 GB OS page cache + OS overhead).
- More RAM directly accelerates aggregations, sorting (`doc_values`), and vector (`dense_vector` HNSW) searches because Lucene memory-maps (`mmap`) those files via the OS page cache.

## CPU: Concurrency Over Raw Clock Speed

- **Indexing and search** are CPU-bound for tokenization, scoring, aggregations, and compression.
- More physical cores (e.g., **8–32 vCPUs** per data node) allow Elasticsearch's `search` and `write` thread pools to process more concurrent shard operations.
- Avoid oversubscribed burstable cloud VMs (e.g., `t3` instances) for production—CPU credit exhaustion causes sudden node disconnects.

## Node Roles and Dedicated Master Nodes

In small dev clusters, a single node can hold all roles. In production, separate **master-eligible** nodes from **data** nodes:

| Node Role (`node.roles`) | Recommended Spec | Why Isolate It? |
| --- | --- | --- |
| `master` (dedicated) | 3 nodes, 4–8 vCPU, 8–16 GB RAM, fast small SSD | Keeps cluster-state updates and master elections immune to heavy search/GC pauses on data nodes |
| `data_hot` | 8–32 vCPU, 64 GB RAM, local NVMe SSD | Handles high write throughput and recent queries |
| `data_warm` / `data_cold` | 4–16 vCPU, 32–64 GB RAM, larger/cheaper SSD or object-backed cache | Stores older read-only indices at lower cost per GB |
| `ingest` | CPU-heavy, minimal disk | Runs heavy Ingest Pipelines (Grok, GeoIP, ML inference) without stealing data-node CPU |

> **Warning.** Always deploy an **odd number** of master-eligible nodes—typically **3**—so the cluster can tolerate 1 master failure while maintaining quorum (`(3 / 2) + 1 = 2`). Never run 2 master-eligible nodes: losing 1 breaks quorum and freezes the cluster.

## Key takeaways

- Prioritize **local NVMe SSDs** for hot data; rely on Elasticsearch replicas rather than RAID 5/6.
- Leave **at least 50% of RAM** free for the **OS page cache**, which Lucene uses to memory-map index files.
- Use **3 dedicated master-eligible nodes** in production so cluster coordination never competes with heavy queries or GC pauses.
- Match node roles (`data_hot`, `data_warm`, `ingest`) to workload bottlenecks rather than over-provisioning uniform nodes.

<div class="chapter-nav">
<a class="chapter-nav__item" href="100-index-lifecycle-management.html"><span>Previous</span><strong>100. Index Lifecycle Management</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="102-heap-sizing.html"><span>Next</span><strong>102. Heap Sizing</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
