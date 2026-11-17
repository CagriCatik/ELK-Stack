---
title: "71. Section 4 Wrapup"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 71. Section 4 Wrapup



Section 4 took you across the entire ingestion spectrum—from loading a handful of JSON documents with `curl` to running distributed, buffered, and vector-enriched pipelines.

## What this section covered

- **Direct & scriptable ingestion:** Indexing via `curl`, the `_bulk` API, and client libraries, while avoiding mapping surprises.
- **Elastic Agent, Beats, and Logstash:** Shipping files and metrics with Filebeat/Elastic Agent, and transforming unstructured logs with Logstash `grok`, `date`, `mutate`, and `geoip` (plus debugging patterns in Kibana Dev Tools and `_ingest/pipeline/_simulate`).
- **Specialized Logstash inputs & resilience:** Monitoring pipeline liveness with `heartbeat`, load-testing with `generator`, capturing rejected documents with the **Dead Letter Queue (DLQ)**, polling REST APIs with `http_poller`, and parsing RFC 3164/5424 syslog with `syslog_pri`.
- **Big-data & buffered architectures:** Placing **Apache Kafka** in front of Logstash for spike buffering and multi-consumer replay, and using **Apache Spark** (`elasticsearch-spark`) for distributed batch and streaming ETL.
- **AI & semantic search:** Storing embeddings in `dense_vector` fields with HNSW indexing and combining BM25 + `knn` using **Reciprocal Rank Fusion (RRF)**.

### Choosing the Right Ingestion Tool

| Use case | Best-fit tool |
| :--- | :--- |
| Ad-hoc JSON, small datasets, CI fixtures | `curl` / `_bulk` API / Python client |
| Host logs, metrics, security telemetry | **Elastic Agent** or **Beats** |
| Complex parsing, enrichment, multi-destination routing | **Logstash** (with DLQ enabled) |
| High-volume spike buffering & replayability | **Apache Kafka** + Logstash `kafka` input |
| Terabyte-scale joins, Parquet/lakehouse ETL, ML prep | **Apache Spark** (`elasticsearch-spark`) |
| Semantic search & RAG pipelines | `dense_vector` + HNSW `knn` + RRF |

## Where to next

Now that you know how to get data of any shape or scale into Elasticsearch, **Section 5: Aggregation** shifts focus to *analyzing* that data—using bucket and metric aggregations to power analytics, histograms, percentiles, and dashboards.

<div class="chapter-nav">
<a class="chapter-nav__item" href="070-using-elasticsearch-as-a-vector-database-with-embeddings-and-dense-vecto.html"><span>Previous</span><strong>70. Using Elasticsearch as a Vector Database with Embeddings and dense_vector</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="../05-aggregation/072-section-5-intro.html"><span>Next</span><strong>72. Section 5 Intro</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
