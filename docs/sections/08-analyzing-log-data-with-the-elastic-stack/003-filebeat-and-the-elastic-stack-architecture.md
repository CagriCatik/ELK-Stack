---
title: "3. FileBeat and the Elastic Stack Architecture"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 3. FileBeat and the Elastic Stack Architecture



Running Logstash on every application server just to tail log files is heavy: Logstash runs on the JVM, consumes hundreds of megabytes of RAM, and is overkill when all you need is reliable file tailing. **Filebeat** solves that problem. Written in Go as a lightweight, single-binary shipper, Filebeat tails log files with minimal CPU and memory overhead, tracks exact byte offsets in a local registry so restarts neither drop nor duplicate lines, and applies backpressure awareness when downstream systems slow down.

## Two primary ingestion architectures

Depending on your parsing, buffering, and routing requirements, Filebeat fits into the Elastic Stack in one of two ways:

### 1. Filebeat → Elasticsearch (Ingest Pipelines)

```text
[Log Files] ──▶ [Filebeat] ──(HTTPS + Bulk API)──▶ [Elasticsearch Ingest Node] ──▶ [Index / Data Stream]
```

In this architecture, Filebeat ships raw log lines directly to Elasticsearch **Ingest Nodes**, which run Grok, Dissect, GeoIP, and Date processors inside an **Ingest Pipeline** before indexing. Filebeat modules (such as `nginx`, `system`, `postgresql`, or `mysql`) bundle these ingest pipelines, index templates, and Kibana dashboards out of the box.

### 2. Filebeat → Logstash → Elasticsearch

```text
[Log Files] ──▶ [Filebeat] ──(Lumberjack / Beats protocol :5044)──▶ [Logstash] ──▶ [Elasticsearch]
```

Here, Filebeat forwards events to Logstash's `beats` input plugin (port `5044` by default). Logstash handles heavy parsing, multi-source enrichment (JDBC lookups, memcached, custom Ruby filters), persistent disk queuing, or fan-out to multiple destinations (Elasticsearch, S3, Kafka).

### Architecture comparison

| Dimension | Filebeat → Elasticsearch | Filebeat → Logstash → Elasticsearch |
| :--- | :--- | :--- |
| **Operational footprint** | Minimal; no Logstash tier to manage | Higher; requires sizing and monitoring Logstash nodes |
| **Parsing & enrichment** | Ingest Node processors (Grok, Dissect, GeoIP, Script) | Full Logstash filter ecosystem + external lookups |
| **Buffering & backpressure** | Filebeat memory/spooler + ES bulk queue | Dedicated Logstash persistent queues (or Kafka/Redis) |
| **Routing & fan-out** | Single Elastic cluster | Multiple outputs (ES, S3, SIEM, webhooks) |
| **Setup speed** | Fast (`filebeat setup` loads everything) | Requires coordinating Logstash pipelines + ES templates |

## Connecting Filebeat to Logstash

When routing through Logstash, configure `output.logstash` in `filebeat.yml` and a matching `beats` input on Logstash:

```yaml
# /etc/filebeat/filebeat.yml
output.logstash:
  hosts: ["logstash.internal:5044"]
  ssl.certificate_authorities: ["/etc/filebeat/ca.crt"]
```

```ruby
# /etc/logstash/conf.d/01-beats-input.conf
input {
  beats {
    port => 5044
    ssl_enabled => true
    ssl_certificate => "/etc/logstash/certs/logstash.crt"
    ssl_key => "/etc/logstash/certs/logstash.key"
  }
}
```

> **Note on Elastic Agent and Fleet.** Elastic also offers **Elastic Agent** managed centrally via **Fleet** in Kibana. Elastic Agent unifies logs, metrics, and security telemetry under a single agent and policy UI. However, standalone **Filebeat** remains widely deployed in Kubernetes (`DaemonSet`), legacy Linux hosts, and environments that prefer declarative `filebeat.yml` configuration-as-code or direct Logstash integration.

## Key takeaways

- **Filebeat** is a lightweight Go-based log shipper that tracks file offsets in a registry and respects downstream backpressure.
- Use **Filebeat → Elasticsearch Ingest Pipelines** when you want low operational overhead and built-in module parsing.
- Add **Logstash** in the middle when you need persistent disk buffering, complex enrichment, or routing to multiple destinations.
- **Elastic Agent + Fleet** provides centralized UI-driven management, while standalone Filebeat remains ideal for config-file-driven and container deployments.

<div class="chapter-nav">
<a class="chapter-nav__item" href="002-data-frame-transforms.html"><span>Previous</span><strong>2. Data Frame Transforms</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="004-x-pack-security.html"><span>Next</span><strong>4. X-Pack Security</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
