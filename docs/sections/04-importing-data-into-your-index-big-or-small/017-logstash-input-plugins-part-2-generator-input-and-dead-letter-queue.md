---
title: "17. Logstash Input Plugins, Part 2: Generator Input and Dead Letter Queue"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 17. Logstash Input Plugins, Part 2: Generator Input and Dead Letter Queue



Testing throughput and handling malformed documents are two sides of running Logstash in production. This chapter covers two closely related tools: the `generator` input plugin for synthetic load generation, and the **Dead Letter Queue (DLQ)** for safely capturing documents that Elasticsearch rejects.

## 1. Load Testing with the `generator` Input Plugin

The `generator` input creates synthetic events in memory as fast as Logstash can process them. Unlike `heartbeat`, it is built for **benchmarking filters, sizing worker threads, and stress-testing Elasticsearch bulk indexing**.

```ruby
input {
  generator {
    lines => [
      '127.0.0.1 - frank [10/Oct/2025:13:55:36 -0700] "GET /index.html HTTP/1.1" 200 1024',
      '10.0.0.42 - alice [10/Oct/2025:13:55:37 -0700] "POST /api/login HTTP/1.1" 401 318'
    ]
    count   => 10000
    threads => 2
  }
}

filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }
}

output {
  elasticsearch {
    hosts => ["http://127.0.0.1:9200"]
    index => "perf-test-logs"
  }
}
```

- `count => 10000` emits 10,000 events *per thread* (20,000 total with `threads => 2`), then stops cleanly.
- Omit `count` (or set `count => 0`) for an infinite stream during sustained soak tests.

## 2. Why You Need a Dead Letter Queue (DLQ)

When Elasticsearch returns a transient error (`429 Too Many Requests` or `503 Service Unavailable`), Logstash retries automatically. However, when Elasticsearch returns a **permanent** `400` or `404` error—most commonly a `mapper_parsing_exception` because a field contains `"N/A"` where the index mapping expects an `integer`—retrying will never succeed.

Without a Dead Letter Queue, Logstash logs a warning and **drops the rejected event** so the pipeline doesn't stall. With DLQ enabled, Logstash writes those failed events to disk for inspection and later replay.

### Enabling DLQ in `logstash.yml`

```yaml
dead_letter_queue.enable: true
path.dead_letter_queue: /var/lib/logstash/dead_letter_queue
dead_letter_queue.max_bytes: 1073741824  # 1 GB per pipeline
dead_letter_queue.storage_policy: drop_newer
```

> **Warning.** `drop_newer` stops writing new DLQ entries once `max_bytes` is reached, protecting your disk from filling up. Use `drop_older` if keeping the most recent failures is more important.

## 3. Reprocessing Failed Events with `dead_letter_queue` Input

Once you've identified why documents failed (for example, an unexpected string in a numeric field), you can spin up a dedicated recovery pipeline using the `dead_letter_queue` input plugin:

```ruby
input {
  dead_letter_queue {
    path           => "/var/lib/logstash/dead_letter_queue"
    pipeline_id    => "main"
    commit_offsets => true
  }
}

filter {
  # Fix the bad field that caused mapper_parsing_exception
  if [bytes] == "-" or [bytes] == "N/A" {
    mutate {
      replace => { "bytes" => "0" }
    }
  }
  mutate {
    add_field => {
      "dlq_reason" => "%{[@metadata][dead_letter_queue][reason]}"
    }
  }
}

output {
  elasticsearch {
    hosts => ["http://127.0.0.1:9200"]
    index => "recovered-logs-%{+YYYY.MM.dd}"
  }
}
```

`[@metadata][dead_letter_queue][reason]` contains the exact Elasticsearch rejection message, making it easy to audit and fix root causes.

## Key takeaways

- Use the `generator` input plugin to benchmark Grok/filter CPU cost and Elasticsearch indexing throughput without external dependencies.
- Enable `dead_letter_queue.enable: true` in `logstash.yml` so permanent `400` mapping/type errors are saved to disk instead of silently dropped.
- Use the `dead_letter_queue` input plugin in a recovery pipeline to inspect `[@metadata][dead_letter_queue][reason]`, clean bad fields, and re-index failed events.

<div class="chapter-nav">
<a class="chapter-nav__item" href="016-logstash-input-plugins-part-1-heartbeat.html"><span>Previous</span><strong>16. Logstash Input Plugins, Part 1: Heartbeat</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="018-logstash-input-plugins-part-3-http-poller.html"><span>Next</span><strong>18. Logstash Input Plugins, Part 3: HTTP Poller</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
