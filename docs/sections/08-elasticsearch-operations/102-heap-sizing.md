---
title: "102. Heap Sizing"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 102. Heap Sizing



Elasticsearch runs on the Java Virtual Machine (JVM). Configuring the JVM heap incorrectly—either too large, too small, or allowed to swap to disk—is one of the fastest ways to destabilize a production cluster.

## Two Golden Rules of Heap Sizing

1. **Set heap to no more than 50% of physical RAM.**
   Lucene uses the remaining 50% (via the OS page cache) to memory-map segment files. If you starve the OS page cache, disk reads spike and query latency collapses.
2. **Never exceed the compressed OOPs threshold (~31–32 GB).**
   On 64-bit JVMs, object pointers are 64 bits wide unless **Compressed Ordinary Object Pointers (Compressed OOPs)** are enabled, which pack pointers into 32 bits. Above ~31.5 GB (exact cutoff depends on the JVM, typically `31g` is safe), Compressed OOPs turn **off**—suddenly consuming ~20–30% more heap just for pointer overhead, so a 35 GB heap actually holds *fewer* objects than a 31 GB heap.

> **Note.** In Elasticsearch 7.11+ and 8.x/9.x, if you do not explicitly set `-Xms` and `-Xmx`, Elasticsearch **automatically** sizes the heap based on node RAM and available roles (capping at ~31 GB on 64 GB+ machines).

## Configuring `jvm.options`

Never edit the default `/etc/elasticsearch/jvm.options` directly (package upgrades overwrite it). Instead, drop a custom `.options` file in `/etc/elasticsearch/jvm.options.d/`:

```text
# /etc/elasticsearch/jvm.options.d/heap.options
-Xms31g
-Xmx31g
```

Always set `-Xms` (initial heap) **equal** to `-Xmx` (maximum heap) so the JVM does not pause to resize the heap at runtime.

You can verify Compressed OOPs and active heap settings via the Nodes Info API:

```bash
curl -s "http://127.0.0.1:9200/_nodes/jvm?filter_path=nodes.*.jvm.mem,nodes.*.jvm.using_compressed_ordinary_object_pointers&pretty"
```

```json
{
  "nodes": {
    "node-1": {
      "jvm": {
        "mem": {
          "heap_init_in_bytes": 33285996544,
          "heap_max_in_bytes": 33285996544
        },
        "using_compressed_ordinary_object_pointers": "true"
      }
    }
  }
}
```

## Disable Swapping Completely

If the Linux kernel swaps JVM heap pages to disk, a routine Garbage Collection (GC) pause that normally takes 50 milliseconds can stretch to **30+ seconds**—causing the node to miss cluster heartbeats and drop out of the cluster.

Disable swap using one of these approaches:
- **OS-level (recommended)**: Run `sudo swapoff -a` and remove swap entries from `/etc/fstab` (or set `vm.swappiness = 1` in `/etc/sysctl.conf`).
- **Elasticsearch memory lock**: Set `bootstrap.memory_lock: true` in `elasticsearch.yml` (requires `LimitMEMLOCK=infinity` in systemd) so the JVM locks its heap into RAM at startup.

## Garbage Collection (G1GC)

Modern Elasticsearch (8.x/9.x on JDK 17/21+) uses **G1GC** by default, which keeps pause times predictable even on 30 GB heaps. Avoid overriding GC flags manually unless advised by Elastic support—default JVM options are tuned for Elasticsearch's allocation patterns.

## Key takeaways

- Give the JVM heap **at most 50% of physical RAM**, leaving the other 50% for the OS page cache.
- Cap `-Xms` and `-Xmx` at **~31 GB** so **Compressed OOPs** remain enabled; set `-Xms == -Xmx`.
- Place custom heap settings in `jvm.options.d/` rather than editing `jvm.options`.
- **Never allow swap** on Elasticsearch nodes (`swapoff -a` or `bootstrap.memory_lock: true`), as swapping turns millisecond GC pauses into node disconnects.

<div class="chapter-nav">
<a class="chapter-nav__item" href="101-choosing-your-cluster-s-hardware.html"><span>Previous</span><strong>101. Choosing your Cluster's Hardware</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="103-monitoring.html"><span>Next</span><strong>103. Monitoring</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
