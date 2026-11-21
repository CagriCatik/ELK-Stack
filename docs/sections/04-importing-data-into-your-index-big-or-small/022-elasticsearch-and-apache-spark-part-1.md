---
title: "22. Elasticsearch and Apache Spark, Part 1"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 22. Elasticsearch and Apache Spark, Part 1



Logstash excels at event-by-event streaming, but when you need to join terabytes of historical Parquet files, run machine learning feature engineering, or aggregate massive datasets before indexing, **Apache Spark** is the right tool. The official **Elasticsearch-Hadoop (`elasticsearch-spark`)** connector bridges Spark and Elasticsearch with distributed, shard-aware I/O.

## How `elasticsearch-spark` Scales

A naive script that collects a Spark DataFrame to the driver and calls Elasticsearch's `_bulk` API from one machine creates a single-node bottleneck. Instead, `elasticsearch-spark` runs **directly on Spark executors**:

- **Parallel writes:** Each Spark partition opens its own bulk connection to the Elasticsearch data nodes, scaling throughput linearly with your Spark executors and Elasticsearch primary shards.
- **Shard-aware reads:** When Spark reads an index, the connector inspects the index's shard topology and creates **one Spark partition per Elasticsearch shard**, reading shards in parallel directly from the nodes that hold them.

## Core Connector Configuration

You configure the connector via Spark's `option(...)` / `SparkConf` properties:

| Property | Example | Purpose |
| :--- | :--- | :--- |
| `es.nodes` | `"127.0.0.1"` or `"es-1,es-2"` | Comma-separated list of Elasticsearch hosts |
| `es.port` | `"9200"` | HTTP/HTTPS port of Elasticsearch |
| `es.resource` | `"movies"` | Target index or data stream (`index` in 8.x/9.x; `_doc` is implied) |
| `es.nodes.wan.only` | `"true"` | Disables node discovery; required when connecting through a load balancer, Docker bridge, or Elastic Cloud |
| `es.mapping.id` | `"movie_id"` | Uses a DataFrame column as Elasticsearch's `_id` for idempotent writes |
| `es.write.operation` | `"index"` \| `"create"` \| `"upsert"` \| `"update"` | Controls how documents are written |

> **Warning (`es.nodes.wan.only`).** By default (`false`), the connector asks Elasticsearch for all internal node IPs and tries to connect to them directly. In Docker, Kubernetes, or Elastic Cloud, those internal IPs are often unreachable from Spark executors, causing connection timeouts. Set `es.nodes.wan.only = "true"` whenever Spark connects through a gateway, NAT, or load balancer.

## Key takeaways

- Use Apache Spark + `elasticsearch-spark` for heavy batch ETL, multi-dataset joins, or ML enrichment prior to indexing.
- The connector distributes reads and writes across Spark executors (one partition per shard on reads) rather than funneling data through the driver.
- Always set `es.nodes.wan.only = "true"` in containerized or cloud environments where executors cannot reach Elasticsearch's internal node IPs directly.

<div class="chapter-nav">
<a class="chapter-nav__item" href="021-elasticsearch-and-kafka-part-2.html"><span>Previous</span><strong>21. Elasticsearch and Kafka, Part 2</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="023-elasticsearch-and-apache-spark-part-2.html"><span>Next</span><strong>23. Elasticsearch and Apache Spark, Part 2</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
