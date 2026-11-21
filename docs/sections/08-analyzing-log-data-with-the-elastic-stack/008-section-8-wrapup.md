---
title: "8. Section 8 Wrapup"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 8. Section 8 Wrapup



## What this section covered

In this section, you moved from static datasets to an end-to-end, secured log-analytics pipeline on the Elastic Stack:

- **Data Frame Transforms (`_transform`)**: Using `pivot` and `latest` transforms (in batch or continuous mode) to convert high-volume, event-centric log indices into fast, entity-centric summaries.
- **Filebeat & Elastic Stack architecture**: Choosing between `Filebeat → Elasticsearch (Ingest Pipelines)` for simplicity and `Filebeat → Logstash → Elasticsearch` for persistent buffering, complex enrichment, and multi-output routing, alongside where Elastic Agent + Fleet fits.
- **X-Pack Security**: Securing transport (`9300`) and HTTP (`9200`) traffic with TLS, managing built-in users with `elasticsearch-reset-password`, and issuing least-privilege RBAC roles and scoped API keys.
- **Installing & configuring Filebeat**: Setting up `filebeat.yml` with `filestream` inputs, enabling modules (`nginx`, `system`), validating with `filebeat test`, and loading templates, pipelines, and dashboards with `filebeat setup`.
- **Kibana log analysis**: Investigating live and historical logs using Discover (KQL), Observability Logs Explorer, pre-built module dashboards, and custom Lens visualizations backed by both raw and transformed indices.

## Where to next

Now that you can ship, secure, transform, and visualize log data, the next section—**Section 8: Elasticsearch Operations**—focuses on keeping clusters healthy in production: capacity planning, shard allocation, Index Lifecycle Management (ILM), snapshot/restore, and diagnosing cluster issues.


## Official References & Further Reading

- [Filebeat Reference — Filebeat Overview, Modules & Architecture](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-overview.html)
- [Fleet & Elastic Agent Guide — Centralized agent management](https://www.elastic.co/guide/en/fleet/current/fleet-overview.html)
- [Elasticsearch Guide — Transforming data (Pivot & Latest Transforms)](https://www.elastic.co/guide/en/elasticsearch/reference/current/transforms.html)
- [Elasticsearch Guide — Security in the Elastic Stack (RBAC, TLS, API Keys)](https://www.elastic.co/guide/en/elasticsearch/reference/current/secure-cluster.html)

<div class="chapter-nav">
<a class="chapter-nav__item" href="007-exercise-log-analysis-with-kibana.html"><span>Previous</span><strong>7. [Exercise] Log analysis with Kibana</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="../09-elasticsearch-operations/001-section-9-intro.html"><span>Next</span><strong>1. Section 9 Intro</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
