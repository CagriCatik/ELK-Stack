---
title: "3. XML Parsing & Ruby Filter 1-to-N Event Fan-Out"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 05</div>

# 3. XML Parsing & Ruby Filter 1-to-N Event Fan-Out

The heart of our Logstash pipeline is `project/logstash/ruby/normalize_report.rb`. While standard Logstash filters (`mutate`, `grok`, `date`) transform a single event in place (1-to-1), Logstash's external **Ruby filter script API** supports **1-to-N event fan-out**: consuming one incoming XML report event and emitting dozens of normalized child documents across multiple Elasticsearch indices.

## The Logstash Ruby Script Contract (`register` and `filter`)

An external Ruby script referenced via `ruby { path => "..." }` implements two methods:

```ruby
def register(params)
  # Executed ONCE when Logstash starts the pipeline.
  # Ideal for loading and validating YAML configuration files in memory.
  mapping_path = params["error_mapping_path"] ||
                 ENV["ERROR_MAPPING_PATH"] ||
                 "/usr/share/logstash/config/error_mapping.yaml"
  @error_engine = XmlInsightErrorMapping::Engine.from_file(mapping_path)
end

def filter(event, &new_event_block)
  # Executed for EVERY incoming event across worker threads.
  # Returning [] drops the original raw XML envelope event after
  # all normalized child events have been emitted via yield/new_event_block.
end
```

### Why `register(params)` is critical for performance and safety
1. **Zero file I/O per event:** `error_mapping.yaml` is read, parsed, compiled into regular expressions, and frozen (`freeze`) **once at Logstash startup**.
2. **Fail-fast startup validation:** If `error_mapping.yaml` contains a syntax error, an invalid regex, or duplicate rule IDs, `register` raises a `ConfigurationError` immediately and prevents Logstash from starting with a broken configuration.
3. **Thread safety across Logstash workers:** Because `@error_engine` and its compiled rule list are immutable (`freeze`), multiple Logstash worker threads execute `filter(event)` concurrently without locks or race conditions.

## How 1-to-N Event Fan-Out Works (`emit_doc`)

Inside `normalize_report.rb`, helper `emit_doc` creates a fresh `LogStash::Event` for every normalized entity (`run`, `suite`, `test_case`, `step`, `message`, `error`) and hands it to the Logstash pipeline downstream of the Ruby filter:

```ruby
def emit_doc(doc, target_index, doc_id, out_events, &new_event_block)
  ev = LogStash::Event.new(doc)
  ev.set("[@metadata][target_index]", target_index)
  ev.set("[@metadata][doc_id]", doc_id)
  if block_given? && new_event_block
    new_event_block.call(ev)
  else
    out_events << ev
  end
end
```

At the end of `filter(event, &new_event_block)`, the original raw input event (which still holds the bulky `raw_xml` string and `parsed_xml` hash) is discarded by returning `out_events` (empty array when `new_event_block` is used).

## How 1 XML Report Splits into 6 Document Types

When a valid `<report>` arrives, `normalize_report.rb` walks the XML tree in a single pass and emits:

| Emitted Document Type | Target Elasticsearch Index | Source XML Elements | Key Normalized Fields Added |
| :--- | :--- | :--- | :--- |
| **1. Run (`doc_type: "run"`)** | `xml-insight-runs-v1` | `<report ...>` root attributes + aggregated counters | `run.id`, `test_bench.id`, `software.version`, `normalized_result`, `init_normalized_result`, `deinit_normalized_result`, `regular_tc_total`, `regular_tc_passed`, `regular_tc_failed`, `data_quality_issues` |
| **2. Suite (`doc_type: "suite"`)** | `xml-insight-suites-v1` | Regular `<groups name="...">` blocks | `suite.id`, `suite.name`, `suite.sequence`, `normalized_result`, `tc_total`, `tc_passed`, `tc_failed`, `extracted_error_codes` |
| **3. TestCase (`doc_type: "test_case"`)** | `xml-insight-testcases-v1` | `<testCase>` inside regular suites (`phase: "suite"`) or `<deInitialization>` (`phase: "deinit"`) | `phase`, `test_case.id`, `test_case.name`, `test_case.attempt`, `test_case.is_retry`, `normalized_result`, `step_count`, `failed_step_count`, `fault_count`, `error_mapping.*` |
| **4. Step (`doc_type: "step"`)** | `xml-insight-steps-v1` | `<step>` inside `<testCase>` | `step.id`, `step.name`, `step.sequence`, `normalized_result`, `extracted_error_codes`, `error_mapping.*` |
| **5. Message (`doc_type: "message"`)** | `xml-insight-messages-v1` | `<msg>` in `init`/`group`/`step` and `<errors><msg>` (`origin_context: "errors_block"`) | `phase`, `origin_context`, `position`, `level`, `original_text`, `extracted_error_codes`, `error_mapping.*` |
| **6. Error (`doc_type: "error"`)** | `xml-insight-errors-v1` | Any rejected XML payload (`_missing_raw_xml`, `_dtd_rejected`, `_xmlparsefailure`, missing root) | `error_type`, `error_message`, `raw_xml_excerpt`, `source_file`, `file_sha256` |

## Why `phase: "suite"` vs. `phase: "deinit"` Separation Matters

In test benches, cleanup steps inside `<groups name="deInitialization">` can fail (for example `SYN_DEINIT_6001: temporary spool cleanup timed out`) even when all functional product tests in the regular suites passed.
- `normalize_report.rb` tags functional test cases with `phase: "suite"` and cleanup test cases with `phase: "deinit"`.
- On the Run document (`xml-insight-runs-v1`), functional counters (`regular_tc_total`, `regular_tc_failed`) are tracked completely separately from cleanup counters (`deinit_tc_total`, `deinit_tc_failed`).
- In Kibana, overview failure matrices filter on `phase : "suite"`, while `03. Run Details` provides a dedicated **Separate Deinit Evaluation** Lens table (`phase : "deinit"`).


## Official References & Further Reading

- [Logstash Reference — XML Filter Plugin (store_xml, remove_namespaces, xpath)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-xml.html)
- [Logstash Reference — Ruby Filter Plugin (path, script_params, register, filter)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-ruby.html)
- [Logstash Reference — Accessing Event Data and @metadata Fields](https://www.elastic.co/guide/en/logstash/current/event-dependent-configuration.html)
- [Logstash Reference — Elasticsearch Output Plugin (index, document_id, action)](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html)
- [Logstash Reference — Node Stats & Pipeline Monitoring API (:9600)](https://www.elastic.co/guide/en/logstash/current/monitoring-apis.html)

<div class="chapter-nav">
<a class="chapter-nav__item" href="002-logstash-pipeline-architecture-and-configuration.html"><span>Previous</span><strong>2. Logstash Pipeline Architecture & Configuration</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="004-config-driven-error-mapping-engine.html"><span>Next</span><strong>4. Config-Driven Error Mapping Engine (error_mapping.yaml)</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 5</a></p>
