---
title: "1. Section 8 Intro"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 1. Section 8 Intro



Up to this point, you have worked primarily with pre-loaded datasets and explored them manually in Elasticsearch and Kibana. In production, however, log data arrives continuously from web servers, containers, firewalls, and application hosts—and it needs to be shipped reliably, parsed into structured fields, secured in transit and at rest, and summarized so operators can spot incidents in seconds rather than hours.

This section takes you through the complete Elastic Stack log-analytics lifecycle, from raw log files on disk to entity-centric summaries and interactive Kibana dashboards.

## What this section covers

1. **Data Frame Transforms (`_transform`)**: Reshaping high-volume, event-centric log indices into compact, entity-centric indices (such as per-IP, per-user, or per-host summaries) using pivot and latest transforms.
2. **Filebeat and Elastic Stack architecture**: Comparing direct `Filebeat → Elasticsearch (Ingest Pipelines)` topologies against `Filebeat → Logstash → Elasticsearch`, plus where Elastic Agent and Fleet fit in modern deployments.
3. **X-Pack Security**: Securing cluster communication and client access with TLS encryption, built-in system users, role-based access control (RBAC), and scoped API keys.
4. **Installing and configuring Filebeat**: Setting up `filebeat.yml` with the modern `filestream` input, enabling modules like `nginx` and `system`, running `filebeat setup`, and verifying ingestion.
5. **Analyzing logs with Kibana**: Using Discover, KQL, Logs Explorer, pre-built module dashboards, and custom Lens visualizations to investigate errors, latency spikes, and traffic anomalies.
6. **Hands-on exercise**: Putting transforms, KQL filtering, and Kibana log analysis together to isolate suspicious traffic patterns.

> **Note on Elastic Stack versions.** Examples in this section target Elastic Stack 8.x/9.x defaults—where X-Pack Security and TLS are enabled out of the box, `_doc` is the single mapping type, and `filestream` replaces the legacy `log` input in Filebeat. Where 7.x commands differ (such as password setup tools), both are noted.

<div class="chapter-nav">
<a class="chapter-nav__item" href="../07-using-kibana/008-section-7-wrapup.html"><span>Previous</span><strong>8. Section 7 Wrapup</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="002-data-frame-transforms.html"><span>Next</span><strong>2. Data Frame Transforms</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
