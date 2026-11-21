---
title: "1. Section 4 Intro"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 1. Section 4 Intro

Up to this point, you have worked with small datasets loaded via single `_bulk` calls or hand-crafted `curl` requests. In production, data rarely arrives in neat, pre-formatted NDJSON files. It lives in relational databases, object storage buckets, rotating application log files, CSV exports, and message queues—and it often arrives continuously at thousands of events per second.

Section 4 covers the full spectrum of importing data into Elasticsearch, from lightweight scripts for one-off migrations to durable, production-grade ingestion pipelines.

## The ingestion spectrum

Choosing the right ingestion tool depends on volume, transformation complexity, and whether the workload is a one-time backfill or a continuous stream:

| Approach | Best for | Strengths | Trade-offs |
| :--- | :--- | :--- | :--- |
| **Custom scripts & client libraries** | One-off migrations, custom APIs, data-science backfills | Full control over parsing, batching, and error handling | You own retries, state tracking, and scaling |
| **Logstash** | Heavy ETL, heterogeneous sources (JDBC, S3, Kafka), complex parsing | Rich plugin ecosystem, Grok/mutate/date filters, persistent queues | Higher JVM memory footprint than lightweight shippers |
| **Beats & Elastic Agent** | Edge log/metric shipping from servers, containers, and cloud services | Minimal footprint, built-in backpressure, centralized Fleet management | Less suited for complex multi-source joins or arbitrary SQL polling |
| **Elasticsearch Ingest Pipelines** | Lightweight field transforms directly on Elasticsearch ingest nodes | No extra infrastructure to run | Consumes cluster CPU; limited to Elasticsearch-side processors |

## What you will learn in this section

1. **Scripting & client libraries**: Generating `_bulk` payloads, tuning batch sizes, and using `elasticsearch.helpers.bulk` in Python (and `@elastic/elasticsearch` in Node.js) to handle retries and partial failures safely.
2. **Logstash fundamentals**: Installing and running Logstash, understanding its `input { ... } filter { ... } output { ... }` pipeline architecture, and managing pipeline configuration files.
3. **Structured & cloud sources**: Pulling incremental rows from MySQL via the JDBC input plugin (`sql_last_value`), parsing CSV and JSON datasets, and reading objects from Amazon S3 with `sincedb` state tracking.
4. **Unstructured log parsing**: Turning raw Apache/Nginx access logs into structured, queryable documents using `grok`, `date`, `geoip`, and `mutate` filters.
5. **Lightweight edge shipping**: Installing and configuring Filebeat to tail log files reliably and ship events either to Logstash or directly into Elasticsearch.

> **Note.** In Elastic Stack 8.x and 9.x, Elasticsearch enables TLS and authentication by default on first boot. Every ingestion tool in this section—whether a Python script, Logstash, or Filebeat—must authenticate (via API key or username/password) and trust the cluster's CA certificate.

<div class="chapter-nav">
<a class="chapter-nav__item" href="../03-searching-with-elasticsearch/016-section-3-wrapup.html"><span>Previous</span><strong>16. Section 3 Wrapup</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="002-importing-data-with-a-script.html"><span>Next</span><strong>2. Importing Data with a Script</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
