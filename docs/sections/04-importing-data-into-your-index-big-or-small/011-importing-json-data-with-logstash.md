---
title: "11. Importing JSON Data with Logstash"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 11. Importing JSON Data with Logstash

Modern applications increasingly emit structured JSON logs (one JSON object per line, also called **JSON Lines** or **NDJSON**). Logstash can parse JSON in two places: at the **input** stage using the `json` codec, or in the **filter** stage using the `json` filter plugin.

## Approach 1: `codec => "json"` on the input

When every line in a file or stream is a standalone JSON object:

```json
{"id": 1, "title": "Toy Story", "year": 1995, "genre": ["Animation", "Comedy"], "created_at": "2026-11-17T10:15:00Z"}
{"id": 2, "title": "Jumanji", "year": 1995, "genre": ["Adventure", "Fantasy"], "created_at": "2026-11-17T10:16:00Z"}
```

Using `codec => "json"` decodes each line directly into top-level Logstash event fields before any filters run:

```ruby
input {
  file {
    path => "/data/movies.jsonl"
    start_position => "beginning"
    sincedb_path => "/dev/null"
    codec => "json"
  }
}

filter {
  date {
    match => ["created_at", "ISO8601"]
    target => "@timestamp"
    remove_field => ["created_at"]
  }
}

output {
  elasticsearch {
    hosts => ["https://127.0.0.1:9200"]
    user => "elastic"
    password => "changeme"
    ssl_certificate_authorities => ["/etc/elasticsearch/certs/http_ca.crt"]
    index => "movies"
    document_id => "%{id}"
  }
}
```

## Approach 2: The `json` filter plugin

Sometimes JSON is *not* the entire input—for example, a log file mixes plain-text startup lines with JSON request logs, or an HTTP/syslog wrapper contains a JSON payload inside `message`. In that case, ingest as plain text and use the `json` filter conditionally:

```ruby
filter {
  if [message] =~ /^\s*\{/ {
    json {
      source => "message"
      target => "payload"      # Optional: nest parsed fields under [payload]
      skip_on_invalid_json => true
      remove_field => ["message"]
    }
  }
}
```

- Omitting `target` merges the JSON keys directly into the root of the event.
- Setting `target => "payload"` prevents key collisions with Logstash's built-in fields (`host`, `event`, `tags`).

## Handling pretty-printed (multi-line) JSON

Logstash's `file` input reads line by line. If your input file contains pretty-printed JSON objects spanning multiple lines, `codec => "json"` will fail on every line. Either compact the file to JSON Lines with `jq -c '.[]' input.json > output.jsonl`, or use a `multiline` codec on the input to join lines between `{` and `}` before applying the `json` filter.

## Key takeaways

- Use `codec => "json"` on the input for clean JSON Lines (NDJSON) files.
- Use the `json` filter when JSON is embedded in a field or mixed with non-JSON lines, and set `target` to avoid overwriting metadata fields.
- Pair JSON parsing with the `date` filter so `@timestamp` reflects the event's original timestamp rather than ingestion time.

<div class="chapter-nav">
<a class="chapter-nav__item" href="010-importing-csv-data-with-logstash.html"><span>Previous</span><strong>10. Importing CSV Data with Logstash</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="012-logstash-and-s3.html"><span>Next</span><strong>12. Logstash and S3</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
