---
title: "21. Elasticsearch and Kafka, Part 2"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 21. Elasticsearch and Kafka, Part 2



With the architecture clear, let's configure both sides of a Kafka-backed Logstash pipeline: shipping events **into** Kafka (with Beats or the Logstash `kafka` output) and consuming events **from** Kafka into Elasticsearch (with the Logstash `kafka` input).

## 1. Producing to Kafka (`kafka` Output Plugin)

If you use Logstash at the edge—or Filebeat directly with `output.kafka`—you can publish JSON events to a Kafka topic:

```ruby
input {
  beats {
    port => 5044
  }
}

output {
  kafka {
    bootstrap_servers => "kafka-1:9092,kafka-2:9092"
    topic_id          => "app-logs"
    codec             => "json"
    compression_type  => "snappy"
    acks              => "1"
  }
}
```

- `compression_type => "snappy"` (or `"lz4"`) dramatically reduces network bandwidth and Kafka disk usage for repetitive JSON logs.
- `acks => "1"` balances durability and throughput; use `acks => "all"` for critical audit/financial events.

## 2. Consuming from Kafka (`kafka` Input Plugin)

On the indexing tier, Logstash reads from Kafka using the `kafka` input plugin, applies filters, and bulk-indexes into Elasticsearch:

```ruby
input {
  kafka {
    bootstrap_servers => "kafka-1:9092,kafka-2:9092"
    topics            => ["app-logs"]
    group_id          => "logstash-es-indexer"
    consumer_threads  => 3
    auto_offset_reset => "latest"
    codec             => "json"
    decorate_events   => "basic"
  }
}

filter {
  if [log][level] == "debug" {
    drop { }
  }
}

output {
  elasticsearch {
    hosts => ["http://127.0.0.1:9200"]
    index => "app-logs-%{+YYYY.MM.dd}"
  }
}
```

### Important `kafka` Input Settings

| Setting | Purpose |
| :--- | :--- |
| `group_id` | Identifies the consumer group; all Logstash nodes with the same `group_id` share partitions |
| `consumer_threads` | Number of threads per Logstash node; keep total threads across nodes `<=` topic partitions |
| `auto_offset_reset` | `"earliest"` (read from start if no committed offset exists) or `"latest"` (only new messages) |
| `decorate_events` | `"basic"` or `"extended"` adds Kafka metadata (`[@metadata][kafka][topic]`, `partition`, `offset`) |
| `max_poll_records` | Max records fetched per `poll()`; lower this if heavy Grok filters cause `session_timeout_ms` rebalances |

## Avoiding Consumer Rebalance Storms

If Logstash takes longer to process a batch of `max_poll_records` than `max_poll_interval_ms` (default 5 minutes), Kafka assumes the consumer is dead and triggers a **consumer group rebalance**, pausing consumption across the group. Watch for this in Logstash logs and either increase `pipeline.workers`, optimize slow Grok patterns, or lower `max_poll_records` (e.g., from `500` to `200`).

## Key takeaways

- Use `compression_type => "snappy"` or `"lz4"` on the `kafka` output to cut network and broker storage overhead.
- Set `group_id` consistently across Logstash indexer nodes and match total `consumer_threads` to the topic's partition count.
- Tune `max_poll_records` and `decorate_events` so heavy filtering never triggers unnecessary Kafka consumer rebalances.

<div class="chapter-nav">
<a class="chapter-nav__item" href="020-elasticsearch-and-kafka-part-1.html"><span>Previous</span><strong>20. Elasticsearch and Kafka, Part 1</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="022-elasticsearch-and-apache-spark-part-1.html"><span>Next</span><strong>22. Elasticsearch and Apache Spark, Part 1</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
