---
title: "16. Section 9 Wrapup"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 09</div>

# 16. Section 9 Wrapup



Running Elasticsearch reliably in production comes down to proactive capacity planning, disciplined hardware and JVM configuration, automated lifecycle management, and practiced recovery procedures.

## What this section covered

- **Shard and Index Scaling**: Sizing shards between **10–50 GB** to avoid oversharding, scaling horizontally with **time-based indices** and **Data Streams**, rotating write targets via **aliases (`is_write_index`, `_rollover`)**, and automating hot/warm/cold/frozen/delete transitions with **ILM (`_ilm/policy`)**.
- **Hardware and JVM Tuning**: Pairing **local NVMe SSDs** with **50% RAM for the OS page cache**, isolating **3 dedicated master nodes**, capping JVM heap at **~31 GB** to preserve **Compressed OOPs**, and disabling **swap** completely.
- **Monitoring and Troubleshooting**: Using `_cluster/health`, `_cat/nodes`, `_cat/shards`, and **Stack Monitoring** to catch issues early; diagnosing `yellow`/`red` clusters with `_cluster/allocation/explain`, handling **85%/90%/95% disk watermarks**, **circuit breakers**, and `429` queue rejections.
- **Resilience, Backups, and Maintenance**: Understanding **master quorum** and **replica promotion** during failover, reshaping indices with **`_reindex`**, **`_split`**, and **`_shrink`**, automating incremental backups with **`_snapshot`** and **SLM (`_slm/policy`)**, executing **zero-downtime rolling restarts**, and monitoring external endpoints with **Elastic Heartbeat**.

## Where to next

Managing hardware, upgrades, snapshots, and multi-tier ILM nodes yourself gives you full control—but it also carries significant operational overhead. In **Section 9: Elasticsearch in the Cloud**, you will see how **Elastic Cloud** (and managed cloud deployments) automates cluster provisioning, scaling, upgrades, and snapshots so your team can focus on search and observability rather than infrastructure maintenance.


## Official References & Further Reading

- [Elasticsearch Guide — Size your shards & capacity planning](https://www.elastic.co/guide/en/elasticsearch/reference/current/size-your-shards.html)
- [Elasticsearch Guide — Index Lifecycle Management (ILM) & Rollover](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-lifecycle-management.html)
- [Elasticsearch Guide — Advanced configuration & JVM Heap sizing](https://www.elastic.co/guide/en/elasticsearch/reference/current/heap-size.html)
- [Elasticsearch Guide — Snapshot and restore & Snapshot Lifecycle Management (SLM)](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html)

<div class="chapter-nav">
<a class="chapter-nav__item" href="015-uptime-monitoring-with-heartbeat.html"><span>Previous</span><strong>15. Uptime Monitoring with Heartbeat</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="../10-elasticsearch-in-the-cloud/001-section-10-intro.html"><span>Next</span><strong>1. Section 10 Intro</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 9</a></p>
