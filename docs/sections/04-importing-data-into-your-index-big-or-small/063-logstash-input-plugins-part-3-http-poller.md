---
title: "63. Logstash Input Plugins, Part 3: HTTP Poller"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 63. Logstash Input Plugins, Part 3: HTTP Poller



Not every data source pushes logs to you. Many SaaS platforms, status pages, monitoring APIs, and internal microservices expose data only via REST endpoints. The Logstash `http_poller` input plugin periodically sends HTTP requests on a schedule and ingests the responses as Logstash events.

## Configuration Example

Here is a pipeline that polls two JSON endpoints every 60 seconds—one using a simple URL string and another with custom headers, authentication, and a timeout:

```ruby
input {
  http_poller {
    urls => {
      es_cluster_health => "http://127.0.0.1:9200/_cluster/health"
      service_status => {
        method  => get
        url     => "https://api.example.com/v1/status"
        headers => {
          Accept          => "application/json"
          "Authorization" => "Bearer ${API_TOKEN}"
        }
      }
    }
    request_timeout => 15
    schedule        => { every => "60s" }
    codec           => "json"
    metadata_target => "@metadata"
  }
}

filter {
  mutate {
    add_field => {
      "polled_url"  => "%{[@metadata][http_poller_metadata][name]}"
      "http_status" => "%{[@metadata][http_poller_metadata][code]}"
    }
  }
}

output {
  elasticsearch {
    hosts => ["http://127.0.0.1:9200"]
    index => "api-poller-%{+YYYY.MM.dd}"
  }
}
```

> **Tip.** Store secrets like `${API_TOKEN}` in the **Logstash Keystore** (`bin/logstash-keystore`) or environment variables rather than hardcoding tokens in `.conf` files.

## Scheduling Options

The `schedule` parameter accepts `rufus-scheduler` syntax in several forms:

| Schedule Form | Example | Behavior |
| :--- | :--- | :--- |
| `every` | `{ every => "30s" }` | Runs every 30 seconds after the previous run finishes |
| `cron` | `{ cron => "*/5 * * * * UTC" }` | Standard 5-field cron expression |
| `at` | `{ at => "2026-01-01 00:00:00 +0000" }` | One-shot execution at a specific timestamp |
| `in` | `{ in => "10s" }` | One-shot execution after a delay |

## Handling Arrays and Failures

- **JSON arrays:** If an API returns a JSON array (e.g., `[{"id": 1}, {"id": 2}]`), the `json` codec emits each element as a separate Logstash event automatically. If the array is nested under a key like `results`, add a `split { field => "results" }` filter.
- **Request errors:** When an HTTP request fails or times out, `http_poller` attaches a `_http_request_failure` tag and populates `[@metadata][http_poller_metadata][runtime_seconds]` and error details instead of crashing the pipeline.
- **Rate limits & pagination:** `http_poller` is stateless—it does not track `next_page` cursors or `since_id` watermarks across polls. For paginated or stateful APIs, use a dedicated script, Elastic Agent custom integration, or Kafka Connect.

## Key takeaways

- `http_poller` turns any REST/JSON endpoint into a scheduled Logstash input using `every` or `cron` schedules.
- Use `metadata_target => "@metadata"` to inspect response status codes and endpoint names without polluting your indexed document fields.
- Keep `http_poller` for stateless polling (health checks, snapshots, metrics); use stateful connectors when cursor-based pagination is required.

<div class="chapter-nav">
<a class="chapter-nav__item" href="062-logstash-input-plugins-part-2-generator-input-and-dead-letter-queue.html"><span>Previous</span><strong>62. Logstash Input Plugins, Part 2: Generator Input and Dead Letter Queue</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="064-syslog-with-logstash-deep-dive.html"><span>Next</span><strong>64. Syslog with Logstash Deep Dive</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
