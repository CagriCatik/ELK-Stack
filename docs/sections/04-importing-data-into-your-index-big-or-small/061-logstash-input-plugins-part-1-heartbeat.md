---
title: "61. Logstash Input Plugins, Part 1: Heartbeat"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 61. Logstash Input Plugins, Part 1: Heartbeat



When an ingestion pipeline goes quiet, how do you know whether your applications stopped logging or Logstash stopped shipping? The Logstash `heartbeat` input plugin solves this by emitting a lightweight synthetic event on a fixed schedule.

## Why Use the `heartbeat` Input?

- **Pipeline liveness monitoring:** Alert in Kibana if no heartbeat event arrives from a Logstash node within the expected window.
- **End-to-end latency checks:** Compare the event's `@timestamp` (when Logstash generated it) with an ingest-time timestamp or Kibana query time to spot queueing delays.
- **Zero-dependency smoke testing:** Verify connectivity, TLS, authentication, and index permissions to Elasticsearch without needing live application traffic.

## Configuration Example

The following pipeline emits a heartbeat every 10 seconds and writes it to an `elk-heartbeats` index (or data stream):

```ruby
input {
  heartbeat {
    message  => "epoch"
    interval => 10
    type     => "logstash-heartbeat"
    add_field => {
      "pipeline_name" => "main-ingest"
      "environment"   => "production"
    }
  }
}

filter {
  mutate {
    add_field => { "logstash_host" => "%{[host][name]}" }
  }
}

output {
  elasticsearch {
    hosts => ["http://127.0.0.1:9200"]
    index => "logstash-heartbeat-%{+YYYY.MM.dd}"
  }
}
```

### Key `heartbeat` Options

| Option | Default | Description |
| :--- | :--- | :--- |
| `message` | `"ok"` | Static string, `"epoch"` (Unix seconds), or `"sequence"` (incrementing counter) |
| `interval` | `60` | Seconds between generated events |
| `count` | `-1` | Total events to emit before stopping (`-1` means run indefinitely) |
| `threads` | `1` | Number of concurrent emitter threads |

Using `message => "sequence"` is especially useful during failover testing: any gap in the sequence numbers immediately reveals dropped events.

## Logstash `heartbeat` vs. Elastic Uptime / Synthetics

Don't confuse the **Logstash `heartbeat` input plugin** with **Elastic Heartbeat** (or Elastic Synthetics):

- **Logstash `heartbeat` input** runs *inside* Logstash to prove the Logstash → Elasticsearch pipeline is alive.
- **Elastic Heartbeat / Synthetics** is a standalone shipper/monitor that probes external HTTP, TCP, and ICMP endpoints to measure service availability.

## Key takeaways

- The `heartbeat` input plugin generates periodic synthetic events to verify that a Logstash pipeline is running and able to write to Elasticsearch.
- Setting `message => "sequence"` or `"epoch"` helps detect dropped events and measure ingestion lag.
- Keep `interval` reasonable (e.g., `10`–`60` seconds) so liveness checks add negligible index overhead.

<div class="chapter-nav">
<a class="chapter-nav__item" href="060-logstash-grok-examples-for-common-log-formats.html"><span>Previous</span><strong>60. Logstash Grok Examples for Common Log Formats</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="062-logstash-input-plugins-part-2-generator-input-and-dead-letter-queue.html"><span>Next</span><strong>62. Logstash Input Plugins, Part 2: Generator Input and Dead Letter Queue</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
