---
title: "65. Elasticsearch and Kafka, Part 1"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 65. Elasticsearch and Kafka, Part 1



In a small deployment, Beats or Elastic Agent ship logs straight to Logstash or Elasticsearch. At scale, however, direct connections create tight coupling: if Elasticsearch slows down during a shard rebalance or Logstash restarts for a config change, upstream shippers back up and may drop events when local spool buffers fill.

Putting **Apache Kafka** in front of Logstash turns your ingestion tier into a durable, replayable buffer.

## The Buffered ELK Architecture

```text
+-------------------+      +--------------------+      +------------------+      +-----------------+
| Beats / Apps /    | ---> |   Apache Kafka     | ---> | Logstash         | ---> | Elasticsearch   |
| Elastic Agent     |      | (Topics/Partitions)|      | (kafka input)    |      | Cluster         |
+-------------------+      +--------------------+      +------------------+      +-----------------+
                                    |
                                    +---> Other Consumers (SIEM, S3 Data Lake, Flink)
```

## Why Introduce Kafka?

1. **Absorbs traffic spikes:** Kafka writes sequentially to disk at very high throughput. Even if Elasticsearch indexing slows down during a traffic surge or maintenance window, Kafka retains hours or days of events safely until Logstash catches up.
2. **Decouples producers from consumers:** Producers (Beats, microservices, Fluent Bit) only need to know about Kafka brokers—not Logstash hostnames, Elasticsearch mappings, or pipeline restarts.
3. **Multi-consumer fan-out:** Multiple independent consumer groups can read the exact same topic simultaneously—one Logstash group indexes into Elasticsearch, while another archives raw logs to Amazon S3 or feeds a real-time alerting engine.
4. **Replayability:** Because Kafka retains messages based on time or size (`retention.ms`, `retention.bytes`) rather than deleting on read, you can reset a consumer group's offset to replay and re-parse historical events after fixing a Grok bug.

## Kafka Concepts Mapped to ELK Scaling

| Kafka Concept | Role in an ELK Pipeline |
| :--- | :--- |
| **Topic** | Logical stream of events (e.g., `app-logs`, `nginx-access`, `audit-events`) |
| **Partition** | Ordered, append-only shard of a topic; determines maximum consumer parallelism |
| **Consumer Group (`group_id`)** | A set of Logstash instances sharing the work of reading a topic; each partition is read by one consumer thread in the group |
| **Offset** | Bookmark tracking how far a consumer group has read in each partition |

> **Design rule.** If a topic has **6 partitions**, you can run up to **6 consumer threads** in the same `group_id` (for example, 2 Logstash nodes with `consumer_threads => 3` each). Adding a 7th thread leaves that thread idle.

## Key takeaways

- Kafka acts as a durable shock absorber between log producers and Elasticsearch, preventing data loss during traffic spikes or cluster maintenance.
- Topics and partitions let you scale Logstash ingestion horizontally by matching `consumer_threads` to partition counts.
- Kafka's retention and offset model enables multi-consumer fan-out and event replay without re-collecting logs from source hosts.

<div class="chapter-nav">
<a class="chapter-nav__item" href="064-syslog-with-logstash-deep-dive.html"><span>Previous</span><strong>64. Syslog with Logstash Deep Dive</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="066-elasticsearch-and-kafka-part-2.html"><span>Next</span><strong>66. Elasticsearch and Kafka, Part 2</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
