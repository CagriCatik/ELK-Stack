---
title: "13. Parsing and Filtering Logstash with Grok"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 13. Parsing and Filtering Logstash with Grok

Most legacy web servers, firewalls, and system daemons write unstructured text lines rather than JSON. If you index an Apache access log as a single `message` string, you cannot filter by HTTP status code `>= 500`, aggregate top requested URLs, or compute average response bytes.

The **`grok` filter** solves this by matching raw text against named regular-expression patterns and extracting structured fields.

## Grok syntax

A Grok pattern has the form:

```text
%{SYNTAX:SEMANTIC}
```

- `SYNTAX`: The name of a built-in (or custom) regex pattern, such as `IP`, `NUMBER`, `WORD`, `DATA`, or `COMBINEDAPACHELOG`.
- `SEMANTIC`: The field name to assign to the matched text.
- Optional type conversion: `%{NUMBER:bytes:int}` or `%{NUMBER:latency:float}` casts the extracted string directly to an integer or float.

## Parsing an Apache combined access log

Consider a standard Apache log line:

```text
83.149.9.216 - - [17/May/2025:10:05:03 +0000] "GET /presentations/logstash.pdf HTTP/1.1" 200 48921 "https://example.com/" "Mozilla/5.0"
```

Logstash ships with over 120 built-in patterns, including `COMBINEDAPACHELOG`, which matches this entire format out of the box. Pair `grok` with `date` (to parse the log timestamp) and `geoip` (to enrich the client IP with country/city/coordinates):

```ruby
input {
  file {
    path => "/var/log/apache2/access.log"
    start_position => "beginning"
  }
}

filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }

  date {
    match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
    target => "@timestamp"
    remove_field => ["timestamp"]
  }

  geoip {
    source => "[source][address]"
  }

  if "_grokparsefailure" in [tags] {
    # Optional: route unparsed lines to a separate debug index or drop
    mutate { add_field => { "parse_status" => "failed" } }
  }
}

output {
  elasticsearch {
    hosts => ["https://127.0.0.1:9200"]
    user => "elastic"
    password => "changeme"
    ssl_certificate_authorities => ["/etc/elasticsearch/certs/http_ca.crt"]
    index => "apache-logs-%{+YYYY.MM.dd}"
  }
}
```

> **Note.** Depending on whether `ecs_compatibility` is enabled (the default in Logstash 8.x+), `COMBINEDAPACHELOG` writes fields using Elastic Common Schema names (such as `[source][address]`, `[http][response][status_code]`) rather than legacy flat names (`clientip`, `response`). Always check the actual output with `stdout { codec => rubydebug }` before referencing extracted fields in downstream `date` or `geoip` filters.

## Writing custom Grok patterns and avoiding pitfalls

When no built-in pattern fits your custom application log:

```text
2026-11-17 18:45:12 ERROR [OrderService] Failed order_id=98421 duration_ms=312
```

Match it with:

```ruby
grok {
  match => {
    "message" => "%{TIMESTAMP_ISO8601:log_time} %{LOGLEVEL:level} \[%{DATA:service}\] Failed order_id=%{INT:order_id:int} duration_ms=%{NUMBER:duration_ms:int}"
  }
}
```

1. **Test patterns interactively**: Use Kibana's **Dev Tools -> Grok Debugger** to iterate on patterns against sample lines before editing `.conf` files.
2. **Anchor patterns when possible**: Starting a pattern with `^` prevents regex backtracking across the entire line when a line does not match.
3. **Prefer `dissect` for fixed delimiters**: If every field is separated by predictable delimiters (spaces, pipes, brackets) without optional parts, Logstash's `dissect` filter is significantly faster than regex-based `grok`.

## Key takeaways

- `grok` turns unstructured log lines into typed, queryable fields using `%{PATTERN:field:type}` expressions.
- Built-in composite patterns like `COMBINEDAPACHELOG` parse common web server formats immediately.
- Always pair `grok` with `date` so `@timestamp` reflects when the event occurred, and monitor `_grokparsefailure` tags to catch format drift.

<div class="chapter-nav">
<a class="chapter-nav__item" href="012-logstash-and-s3.html"><span>Previous</span><strong>12. Logstash and S3</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="014-workaround-if-the-grok-debugger-app-in-the-next-lecture-is-down.html"><span>Next</span><strong>14. Workaround if the Grok Debugger app in the next lecture is down...</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
