---
title: "80. Section 6 Intro"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 06</div>

# 80. Section 6 Intro

Up to this point, every interaction with Elasticsearch has gone through raw HTTP requests (`curl` and JSON payloads). That is essential for understanding how the engine works and for automating queries in application code, but it is not how analysts, SREs, or product teams explore data day to day.

**Kibana** is the visual interface and management plane for the Elastic Stack. It sits in front of Elasticsearch, translates point-and-click interactions into Query DSL and aggregation requests, and renders the results as interactive tables, charts, and dashboards.

## What this section covers

- **Installation and configuration** — Installing Kibana alongside Elasticsearch, configuring `kibana.yml` (port `5601`, `elasticsearch.hosts`), and connecting securely using an enrollment token or service account token.
- **Exploring data in Discover and Dev Tools** — Creating **Data Views** (formerly called Index Patterns), filtering documents with **KQL (Kibana Query Language)**, and running raw API requests in the **Dev Tools Console**.
- **Hands-on exploration** — Building a Data View and investigating the `movies` dataset using KQL filters, field statistics, and the time/histogram controls.
- **Kibana Lens** — Building bar, line, pie, and metric visualizations with drag-and-drop fields, breakdown dimensions, and custom **Formula** expressions, then assembling them into a dashboard.
- **Stack Management** — Managing indices, Data Views, **Saved Objects** (export/import across environments), and **Users & Roles** directly from the Kibana UI.
- **Elasticsearch SQL (and ES|QL)** — Querying Elasticsearch indices using familiar `SELECT ... FROM ... GROUP BY` syntax via `/_sql`, translating SQL to Query DSL with `/_sql/translate`, and understanding how **ES|QL** (Piped Query Language) extends this in modern 8.x/9.x clusters.

> **Why Kibana matters operationally.** Even if your production application queries Elasticsearch via a client library, Kibana is where you debug slow queries in Dev Tools, inspect mapping conflicts in Stack Management, and build operational dashboards for latency, error rates, and cluster health.

<div class="chapter-nav">
<a class="chapter-nav__item" href="../05-aggregation/079-section-5-wrapup.html"><span>Previous</span><strong>79. Section 5 Wrapup</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="081-installing-kibana.html"><span>Next</span><strong>81. Installing Kibana</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 6</a></p>
