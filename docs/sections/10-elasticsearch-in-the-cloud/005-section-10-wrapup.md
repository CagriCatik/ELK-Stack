---
title: "5. Section 10 Wrapup"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 10</div>

# 5. Section 10 Wrapup



You have reached the end of **Section 10: Elasticsearch in the Cloud**—and the final chapter of the course.

## What this section covered

- **The cloud operational shift (Chapter 1):** Managed services eliminate OS patching, TLS rotation, and rolling upgrade toil, while leaving data modeling, shard strategy, query tuning, and cost governance in your hands.
- **Amazon OpenSearch Service Architecture (Chapter 2):** How AWS domains combine managed data nodes, **3 dedicated master nodes**, and **3-AZ Zone Awareness**; why **VPC access** is the production standard; and how **OpenSearch** has diverged from **Elasticsearch** since the 7.10 fork.
- **Amazon OpenSearch Operations & Security (Chapter 3):** Tiering data across **Hot**, **UltraWarm**, and **Cold** with **ISM**; layering **VPC + IAM (SigV4) + Fine-Grained Access Control (FGAC)**; and using **manual S3 snapshots** alongside AWS's 14-day automated backups.
- **The Elastic Cloud (Chapter 4):** Running upstream Elasticsearch across **AWS, GCP, and Azure** with workload **deployment profiles**, **autoscaling**, **Traffic Filters / PrivateLink**, **Searchable Snapshots** (Frozen tier), **Elastic Cloud Serverless**, and built-in **Lens, ES|QL, Fleet, APM, and SIEM**.

## Looking back across the full Elastic Stack

Over the ten sections of this guide, you have built a complete mental model of the Elastic Stack from first principles to cloud production:

1. **Foundations (Section 1):** Inverted indices, TF/IDF & BM25, shards, replicas, and RESTful HTTP APIs.
2. **Data Modeling & Mappings (Section 2):** Explicit & dynamic mappings (`dynamic: strict`), analyzers, CRUD, `_bulk`, concurrency, and `flattened` vs. parent-child relationships.
3. **Search & Relevance (Section 3):** Query DSL, `match` vs. `term`, phrase & fuzzy queries, filter context, pagination (`from`/`size`, `search_after`, PIT), and `search_as_you_type`.
4. **Importing Data & Logstash Fundamentals (Section 4):** Client scripts, Logstash `input → filter → output` pipelines, JDBC, CSV/JSON/S3, Grok, input plugins, Dead Letter Queues, Kafka, Spark, and `dense_vector` kNN search.
5. **Logstash Deep Dive, XML Pipelines & Error Mapping (Section 5):** HTTP JSON envelopes, DTD/XXE security guards, `xml` filter, Ruby filter 1-to-N event fan-out (`normalize_report.rb`), config-driven error mapping (`error_mapping.yaml`), deterministic SHA-256 routing, and historical reprocessing.
6. **Aggregations (Section 6):** Metric, bucket, histogram, time-series, and nested aggregations for real-time analytics.
7. **Kibana (Section 7):** Data Views, Discover, Lens visualizations & aggregated Data Tables (`lnsDatatable`), dashboards, Stack Management, and Elasticsearch SQL / ES|QL.
8. **Beats & Log Analytics (Section 8):** Data Frame Transforms, Filebeat & Elastic Agent architecture, X-Pack Security, and Kibana log analysis dashboards.
9. **Operations (Section 9):** Shard sizing, index alias rotation, ILM, hardware & JVM heap sizing, monitoring, troubleshooting, failover, snapshots/SLM, rolling restarts, and Heartbeat.
10. **Cloud (Section 10):** Amazon OpenSearch Service, Elastic Cloud Hosted, and Elastic Cloud Serverless.

## Where to next

- **Build an end-to-end project:** Spin up a free **Elastic Cloud** trial (or a local Docker Compose stack) and ingest real application logs and OpenTelemetry traces via **Elastic Agent + Fleet**, then build a **Kibana Lens** dashboard and an **ILM** retention policy.
- **Explore modern search & ES\|QL:** Practice combining **BM25 lexical search** with **`dense_vector` semantic search** (hybrid search with Reciprocal Rank Fusion) and writing piped analytics queries in **ES\|QL**.
- **Deepen your credentials:** If you plan to validate your skills professionally, consider the **Elastic Certified Engineer**, **Elastic Certified Observability Engineer**, or **AWS Certified Data Engineer** tracks.


## Official References & Further Reading

- [Elastic Cloud — Hosted Elasticsearch Service & Serverless Documentation](https://www.elastic.co/guide/en/cloud/current/ec-getting-started.html)
- [Amazon OpenSearch Service — Developer Guide & Multi-AZ Architecture](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/what-is.html)
- [OpenSearch Project — Official Technical Documentation](https://docs.opensearch.org/)

<div class="chapter-nav">
<a class="chapter-nav__item" href="004-the-elastic-cloud.html"><span>Previous</span><strong>4. The Elastic Cloud</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 10</a></p>
