---
title: "7. Testing Ruby Filters, Debugging Pipelines & Historical Reprocessing"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 05</div>

# 7. Testing Ruby Filters, Debugging Pipelines & Historical Reprocessing

Because Logstash owns both XML normalization and rule-based error classification, our project includes automated unit tests, live pipeline diagnostics, and a one-command historical reprocessing workflow whenever `project/config/error_mapping.yaml` changes.

## 1. Unit-Testing the Logstash Ruby Engine (`test_error_mapping.rb`)

You do not need to ingest full XML batches through HTTP just to verify a change in `error_mapping.rb` or `error_mapping.yaml`. We can execute the Ruby test suite directly inside the running Logstash container:

```bash
cd project
docker compose exec -T logstash ruby /usr/share/logstash/ruby/test_error_mapping.rb
```

What `test_error_mapping.rb` verifies:
- **`ConfigurationLoader` validation:** Confirms that `error_mapping.yaml` loads cleanly and that duplicate rule IDs, invalid regex patterns, or unknown match types raise `XmlInsightErrorMapping::ConfigurationError`.
- **All 4 matching strategies:** Tests `error_code`, `regex`, `contains`, and `exact` matching (both case-insensitive and case-sensitive).
- **Priority & tie-breaking:** Confirms that higher `priority` rules win and that all matching rule IDs are recorded in `matched_rule_ids`.
- **Scope filtering:** Verifies that `scope.phase`, `scope.suite`, and `scope.test_case` restrict rules to their intended context.
- **Fallback behavior:** Confirms that unknown error codes/messages receive the `defaults` (`UNKNOWN` / `MEDIUM` / `UNCLASSIFIED`).

## 2. Inspecting Logstash Pipeline Health & Throughput (`:9600`)

Logstash exposes a JSON monitoring API on port `9600`. You can query node and pipeline metrics at any time:

```bash
curl -s http://127.0.0.1:9600/_node/stats/pipelines?pretty
```

Key metrics to watch in `pipelines.main.events`:
- **`in`**: Number of raw HTTP XML report envelopes received on port `8080`.
- **`filtered`**: Number of events entering the filter stage.
- **`out`**: Total number of split child documents (`run`, `suite`, `test_case`, `step`, `message`, `error`) emitted by `normalize_report.rb` to Elasticsearch (typically 15–30× higher than `in` due to 1-to-N fan-out!).
- **`duration_in_millis`**: Total processing time spent in filters and outputs.

If a Ruby exception or mapping rejection occurs, inspect the live Logstash container logs:

```bash
cd project
docker compose logs --tail=100 logstash
```

## 3. Historical Reprocessing When `error_mapping.yaml` Changes (`reprocess.sh`)

Because Logstash evaluates `error_mapping.yaml` **at ingest time** (during `register` and `filter`), editing `project/config/error_mapping.yaml` does not automatically mutate historical documents already stored in Elasticsearch.

To apply updated classification rules across all existing XML reports without creating duplicates, run:

```bash
cd project
./scripts/reprocess.sh
```

### What `./scripts/reprocess.sh` does step by step:
1. **Restarts or reloads Logstash** so `normalize_report.rb#register` loads and validates the updated `project/config/error_mapping.yaml` into memory (failing fast if the YAML has any syntax or validation error).
2. **Clears and re-applies the strict Elasticsearch index templates** (`xml-insight-*-v1`) or re-indexes in place using our deterministic SHA-256 `doc_id`s.
3. **Re-ingests all XML test reports** (`examples/` and `data/generated/`) through Logstash (`http://logstash:8080`) and re-evaluates the nightly plan status.
4. **Verifies document counts** across all 7 Elasticsearch index families.


## Official References & Further Reading

- [Logstash Reference — XML Filter Plugin (store_xml, remove_namespaces, xpath)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-xml.html)
- [Logstash Reference — Ruby Filter Plugin (path, script_params, register, filter)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-ruby.html)
- [Logstash Reference — Accessing Event Data and @metadata Fields](https://www.elastic.co/guide/en/logstash/current/event-dependent-configuration.html)
- [Logstash Reference — Elasticsearch Output Plugin (index, document_id, action)](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html)
- [Logstash Reference — Node Stats & Pipeline Monitoring API (:9600)](https://www.elastic.co/guide/en/logstash/current/monitoring-apis.html)

<div class="chapter-nav">
<a class="chapter-nav__item" href="006-kibana-lens-tables-and-dashboard-customization.html"><span>Previous</span><strong>6. Kibana Data Views, Lens Data Tables (lnsDatatable) & Customization</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="008-section-5-wrapup.html"><span>Next</span><strong>8. Section 5 Wrapup</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 5</a></p>
