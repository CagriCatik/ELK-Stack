---
title: "6. Analyzing Logs with Kibana Dashboards"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 6. Analyzing Logs with Kibana Dashboards



Once Filebeat is shipping structured logs into Elasticsearch, Kibana turns those documents into interactive investigations. Rather than grepping through flat files on individual servers, you can filter across the entire fleet in real time, correlate spikes with HTTP status codes or source IPs, and drill into raw log lines.

## 1. Data Views and Discover (KQL)

After `filebeat setup`, Kibana has a `filebeat-*` **Data View** (called an Index Pattern in 7.x) bound to `@timestamp`. Open **Analytics → Discover** to inspect raw documents and filter with **Kibana Query Language (KQL)**:

```text
event.module : "nginx" and http.response.status_code >= 500
```

```text
event.module : "nginx" and url.path : "/api/*" and not source.ip : "10.0.0.0/8"
```

Useful Discover workflows during an incident:
- **Pinning fields as columns**: Add `source.ip`, `http.request.method`, `url.path`, and `http.response.status_code` to the table so you can scan requests without expanding every JSON document.
- **Field statistics**: Click any field in the left sidebar to see its top 5 values and percentage breakdown for the current time window.

## 2. Observability → Logs Explorer

For tailing logs like `tail -f`, open **Observability → Logs → Explorer**. Logs Explorer provides:
- A compact, single-line log stream optimized for reading messages rather than JSON trees.
- **Live streaming** mode (`Stream live`) for watching deployments or reproducing bugs in real time.
- **View in context** (surrounding documents) to inspect the exact lines emitted immediately before and after an error on the same host.

## 3. Pre-built vs. custom Lens dashboards

Running `filebeat setup` installs module dashboards such as **`[Filebeat Nginx] Access and error logs`**, which include:
- Request volume and response code breakdown over time (`2xx`, `3xx`, `4xx`, `5xx`).
- Geographic map of client IPs (`source.geo.location`, populated by the module's GeoIP ingest processor).
- Top requested URLs and user agents.

When module dashboards don't answer your specific operational question, build a custom **Dashboard** with **Kibana Lens**:

| Question | Lens visualization | Configuration |
| :--- | :--- | :--- |
| *When did errors spike?* | **Stacked Bar** | X-axis: `@timestamp` (Date histogram); Y-axis: `Count`; Breakdown: `http.response.status_code` |
| *Which endpoints are failing?* | **Data Table** | Rows: `url.path` (Top 10); Metrics: `Count`, and a formula `count(kql='http.response.status_code >= 500') / count()` formatted as `%` |
| *Which client IPs are scraping or attacking?* | **Horizontal Bar** (or Transform index) | Y-axis: `source.ip`; X-axis: `Count`; Filter: `http.response.status_code : 404` |

> **Combining Transforms with Dashboards.** For high-volume logs, create a Data View on your entity-centric transform index (`nginx-ip-summary`) and add a table to your dashboard showing top IPs by `error_4xx_5xx.doc_count`. Clicking a `source.ip` in that table applies a global dashboard filter that immediately filters the raw `filebeat-*` panels alongside it.

## Key takeaways

- Use **Discover** with **KQL** for structured field filtering and quick top-value inspection across `filebeat-*`.
- Use **Observability → Logs Explorer** for `tail -f`-style streaming and viewing surrounding log lines in context.
- Start with **pre-built module dashboards**, then add custom **Kibana Lens** panels (including error-rate formulas) tailored to your SLAs.
- Pair entity-centric **Transform** indices with raw log panels on the same dashboard to jump from anomalous entities straight to their raw events.

<div class="chapter-nav">
<a class="chapter-nav__item" href="005-installing-filebeat.html"><span>Previous</span><strong>5. Installing FileBeat</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="007-exercise-log-analysis-with-kibana.html"><span>Next</span><strong>7. [Exercise] Log analysis with Kibana</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
