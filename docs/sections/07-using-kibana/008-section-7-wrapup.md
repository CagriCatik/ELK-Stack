---
title: "8. Section 7 Wrapup"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 07</div>

# 8. Section 7 Wrapup

You now have the full visual and administrative toolkit for working with data in Kibana, sitting cleanly on top of the Elasticsearch search and aggregation primitives you learned in Sections 3–5.

## What this section covered

- **Installing & connecting Kibana (`81`)** — Configuring `kibana.yml` (port `5601`, `elasticsearch.hosts`) and authenticating securely to 8.x/9.x clusters using an **enrollment token** or an `elastic/kibana` **service account token**.
- **Discover, Data Views & Dev Tools (`82`–`83`)** — Mapping indices into Kibana with **Data Views**, filtering documents interactively using **KQL**, inspecting field distributions, and prototyping Query DSL in **Dev Tools Console**.
- **Kibana Lens (`84`)** — Building charts and dashboards with drag-and-drop bucket/metric aggregations and **Lens Formula** expressions (ratios, filtered counts, time shifts).
- **Stack Management (`85`)** — Administering indices, ILM policies, snapshots, **Saved Objects** (`.ndjson` export/import), and **RBAC Roles & Spaces**.
- **Elasticsearch SQL & ES|QL (`86`)** — Running `SELECT ... GROUP BY` queries via `/_sql?format=txt`, translating SQL to Query DSL with `/_sql/translate`, and understanding when to use **ES|QL** (`/_query`) for piped analytics.

## Where to next

So far, we have worked with pre-loaded datasets (`movies`). In **Section 7: Analyzing Log Data with the Elastic Stack**, you will connect real-world log streams—starting with Apache/Nginx access logs—using **Beats** and **Logstash**, parse unstructured text into structured fields, and build live operational dashboards in Kibana.


## Official References & Further Reading

- [Kibana Guide — Create visualization with Lens (lnsDatatable, lnsXY, lnsMetric, Formula)](https://www.elastic.co/guide/en/kibana/current/lens.html)
- [Kibana Guide — Data Views (formerly Index Patterns) & Saved Objects](https://www.elastic.co/guide/en/kibana/current/data-views.html)
- [Kibana Guide — Kibana Query Language (KQL)](https://www.elastic.co/guide/en/kibana/current/kuery-query.html)
- [Elasticsearch Guide — ES|QL (Elasticsearch Piped Query Language) & SQL](https://www.elastic.co/guide/en/elasticsearch/reference/current/esql.html)

<div class="chapter-nav">
<a class="chapter-nav__item" href="007-elasticsearch-sql.html"><span>Previous</span><strong>7. Elasticsearch SQL</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="../08-analyzing-log-data-with-the-elastic-stack/001-section-8-intro.html"><span>Next</span><strong>1. Section 8 Intro</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 7</a></p>
