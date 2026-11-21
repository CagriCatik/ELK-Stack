---
title: "2. Logstash Pipeline Architecture & Configuration"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 05</div>

# 2. Logstash Pipeline Architecture & Configuration

In our project (`project/logstash/`), Logstash runs as a dedicated service (`xml-insight-logstash`) defined in `project/docker-compose.yml`. Understanding how its configuration files interact makes it easy to tune throughput, add new inputs, or customize filter stages.

## File layout in `project/logstash/`

```text
project/
├── config/
│   └── error_mapping.yaml              # Central error classification rules
└── logstash/
    ├── config/
    │   └── logstash.yml                # Node-level settings (HTTP API, workers)
    ├── pipeline/
    │   └── xml-insight.conf            # The 3-stage pipeline (input/filter/output)
    └── ruby/
        ├── error_mapping.rb            # Config loader, matcher & classifier
        ├── normalize_report.rb         # XML normalizer & 1-to-N event splitter
        └── test_error_mapping.rb       # Unit test suite for the Ruby engine
```

## 1. Node configuration (`logstash/config/logstash.yml`)

`logstash.yml` controls the Logstash runtime itself:

```yaml
http.host: "0.0.0.0"
http.port: 9600
pipeline.ecs_compatibility: disabled
xpack.monitoring.enabled: false
```

- **`http.port: 9600`** exposes the Logstash Monitoring & Health API (`curl http://127.0.0.1:9600/_node/stats/pipelines`), which our healthcheck and `status.sh` script use to verify that the pipeline is ready.
- **`pipeline.ecs_compatibility: disabled`** prevents built-in plugins from unexpectedly renaming fields to ECS conventions when our strict Elasticsearch index templates expect our exact schema (`run.id`, `test_bench.id`, `error_mapping.*`).

## 2. The Complete Pipeline (`logstash/pipeline/xml-insight.conf`)

Here is the full production pipeline used by XML Insight Lab:

```ruby
input {
  http {
    host => "0.0.0.0"
    port => 8080
    codec => "json"
    max_content_length => 5242880
    response_headers => {
      "Content-Type" => "application/json"
    }
  }
}

filter {
  # Stage 1: Envelope and security pre-checks before XML parsing.
  # Reject DTD/Entity declarations and oversized payloads early.
  if ![raw_xml] or [raw_xml] == "" {
    mutate {
      add_tag => ["_missing_raw_xml"]
    }
  } else if [raw_xml] =~ /<!(?i)(DOCTYPE|ENTITY)/ {
    mutate {
      add_tag => ["_dtd_rejected"]
    }
  } else {
    # Stage 2: Official Logstash XML filter (XML-v1 mapping).
    # remove_namespaces strips XML namespaces cleanly while store_xml builds parsed_xml.
    xml {
      source => "raw_xml"
      target => "parsed_xml"
      store_xml => true
      force_array => false
      remove_namespaces => true
    }
  }

  # Stage 3: Stateless validation, normalization, and config-driven error mapping.
  ruby {
    path => "/usr/share/logstash/ruby/normalize_report.rb"
    script_params => {
      "error_mapping_path" => "/usr/share/logstash/config/error_mapping.yaml"
    }
  }

  # Remove Logstash's internal @version field so strict ES mappings stay clean.
  mutate {
    remove_field => ["@version"]
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "%{[@metadata][target_index]}"
    document_id => "%{[@metadata][doc_id]}"
    action => "index"
  }
}
```

## Stage-by-stage breakdown

### Input Stage: HTTP JSON Envelope (`:8080`)
Instead of relying on Logstash's `file` input with brittle `multiline` regexes to detect where a large `<report>...</report>` XML file starts and ends, the Python ingestion CLI (`tools/xml_insight_lab/ingester.py`) reads each complete XML file, calculates its `file_sha256` hash, and sends a clean JSON payload to `http://logstash:8080`:

```json
{
  "source_file": "run-lab-01-20261118-002.xml",
  "file_sha256": "a6c75948ae7b2d3fe01e3ee27de51a1791926c4cd1c2e477721de50a7016471e",
  "ingested_at": "2026-11-21T10:28:49.170Z",
  "campaign_id": "nightly-20261118",
  "raw_xml": "<report schemaVersion=\"1.0\" ...>...</report>"
}
```

### Filter Stage 1: Security Pre-Checks (XXE / DTD Guard)
Before the XML parser touches `[raw_xml]`, Logstash inspects the payload:
- If `[raw_xml]` is missing or empty, it tags the event with `_missing_raw_xml`.
- If `[raw_xml]` contains `<!DOCTYPE` or `<!ENTITY`, it tags the event with `_dtd_rejected` and **skips the XML parser**. This prevents XML External Entity (XXE) and Billion Laughs entity-expansion attacks at the pipeline boundary.

### Filter Stage 2: Official `xml` Filter
When the payload is safe, the built-in `xml` filter parses `source => "raw_xml"` into a Ruby hash under `target => "parsed_xml"`:
- `store_xml => true` automatically converts XML attributes and nested elements into a structured hash tree.
- `remove_namespaces => true` strips namespace prefixes (`ns:report` → `report`) so downstream field paths remain consistent.
- `force_array => false` keeps single-element nodes readable while `normalize_report.rb` normalizes repeatable elements (`groups`, `group`, `testCase`, `step`, `msg`) into arrays via a helper function `arrayify()`.

### Filter Stage 3: Ruby Normalizer & `@version` Cleanup
- The `ruby` filter loads `/usr/share/logstash/ruby/normalize_report.rb` and passes `error_mapping_path => "/usr/share/logstash/config/error_mapping.yaml"` via `script_params`.
- Finally, `mutate { remove_field => ["@version"] }` strips Logstash's internal `@version` metadata field so Elasticsearch's `strict` index templates (`"dynamic": "strict"`) never reject documents for unexpected root fields.

### Output Stage: Dynamic `@metadata` Routing
Notice how the `elasticsearch` output routes documents dynamically:
```ruby
index => "%{[@metadata][target_index]}"
document_id => "%{[@metadata][doc_id]}"
```
Fields stored inside `[@metadata]` exist **only in Logstash memory** during pipeline execution and are **never serialized into the Elasticsearch document `_source`**. That lets the Ruby filter steer each emitted child event into its exact target index (`xml-insight-runs-v1`, `xml-insight-testcases-v1`, etc.) with a deterministic primary key (`doc_id`).


## Official References & Further Reading

- [Logstash Reference — XML Filter Plugin (store_xml, remove_namespaces, xpath)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-xml.html)
- [Logstash Reference — Ruby Filter Plugin (path, script_params, register, filter)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-ruby.html)
- [Logstash Reference — Accessing Event Data and @metadata Fields](https://www.elastic.co/guide/en/logstash/current/event-dependent-configuration.html)
- [Logstash Reference — Elasticsearch Output Plugin (index, document_id, action)](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html)
- [Logstash Reference — Node Stats & Pipeline Monitoring API (:9600)](https://www.elastic.co/guide/en/logstash/current/monitoring-apis.html)

<div class="chapter-nav">
<a class="chapter-nav__item" href="001-section-5-intro.html"><span>Previous</span><strong>1. Section 5 Intro: Why Logstash Is Central to Our Stack</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="003-xml-parsing-and-ruby-filter-fanout.html"><span>Next</span><strong>3. XML Parsing & Ruby Filter 1-to-N Event Fan-Out</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 5</a></p>
