---
title: "50. Introducing Logstash"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 50. Introducing Logstash

Custom scripts are ideal for one-off imports, but production data pipelines rarely run once and stop. You need a tool that continuously polls databases, tails rotating files, consumes Kafka topics, parses messy log lines, enriches events with GeoIP or lookup tables, buffers spikes, and retries when Elasticsearch is temporarily busy. That is the role of **Logstash**, the "L" in the ELK Stack.

## The three-stage pipeline architecture

Every Logstash pipeline follows a declarative three-stage model:

```text
  +----------+       +-----------+       +------------+
  |  INPUTS  | ----> |  FILTERS  | ----> |  OUTPUTS   |
  +----------+       +-----------+       +------------+
   - file             - grok              - elasticsearch
   - jdbc             - mutate            - kafka
   - s3               - date              - s3
   - beats            - json / csv        - stdout
   - kafka            - geoip             - file
```

1. **Inputs** ingest data from a source and emit internal Logstash **events** (hash maps of fields plus `@timestamp` and `@metadata`).
2. **Filters** (optional) transform, parse, enrich, or drop events in order. Common filters include `grok`, `dissect`, `mutate`, `date`, `json`, `csv`, and `geoip`.
3. **Outputs** send processed events to one or more destinations—typically Elasticsearch, though you can fan out to S3, Kafka, or `stdout` for debugging at the same time.

In configuration syntax, a pipeline looks like this:

```ruby
input {
  # Where events come from
}

filter {
  # How events are parsed, enriched, or dropped
}

output {
  # Where events are sent
}
```

## Codecs, queues, and reliability

- **Codecs** (`json`, `plain`, `multiline`, `rubydebug`) run inside inputs and outputs to encode or decode data at the boundary—for example, joining Java stack traces with `multiline` before filters ever see the event.
- **In-memory vs. Persistent Queues**: By default, Logstash buffers events in memory. Enabling `queue.type: persisted` in `logstash.yml` writes events to disk between the input and filter stages so an unexpected Logstash restart does not lose in-flight events.
- **Backpressure**: If Elasticsearch slows down and responds with `429`, Logstash's output worker slows down, which fills the internal queue and naturally throttles the input stage rather than dropping data.
- **Dead Letter Queue (DLQ)**: Events that Elasticsearch rejects with permanent `400` mapping errors can be routed to an on-disk DLQ (`dead_letter_queue.enable: true`) for later inspection instead of blocking the pipeline.

## Logstash vs. Beats vs. Ingest Pipelines

| Feature | Logstash | Beats / Elastic Agent | ES Ingest Pipelines |
| :--- | :--- | :--- | :--- |
| **Primary role** | Heavy ETL & multi-source aggregation | Lightweight edge shipping | Cluster-side field transforms |
| **Footprint** | JVM (~1–4 GB RAM) | Go binary (~50–150 MB RAM) | Runs inside ES ingest nodes |
| **Sources** | JDBC, S3, Kafka, HTTP, Beats, Files | Files, Metrics, Packet, Audit | Receives HTTP/Bulk requests |
| **Complex parsing** | Full `grok`, Ruby filter, external lookups | Basic multiline & processors | `grok`, `dissect`, `script` |

In many architectures, **Filebeat** runs on application servers to tail logs with minimal overhead and forwards them to a central **Logstash** tier for heavy parsing, enrichment, and routing into Elasticsearch.

## Key takeaways

- Logstash is a JVM-based ETL engine organized into **input**, **filter**, and **output** stages.
- Codecs handle serialization/deserialization (such as `json` or `multiline`) at the input/output edges.
- Persistent queues and Dead Letter Queues protect against data loss during restarts and mapping errors.

<div class="chapter-nav">
<a class="chapter-nav__item" href="049-exercise-importing-with-a-script.html"><span>Previous</span><strong>49. [Exercise] Importing with a Script</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="051-installing-logstash.html"><span>Next</span><strong>51. Installing Logstash</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
