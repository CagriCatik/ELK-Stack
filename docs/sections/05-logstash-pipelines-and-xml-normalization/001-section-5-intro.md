---
title: "1. Section 5 Intro: Why Logstash Is Central to Our Stack"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 05</div>

# 1. Section 5 Intro: Why Logstash Is Central to Our Stack

In Section 4 we saw how Logstash can import CSV files, poll MySQL via JDBC, or parse flat single-line logs with `grok`. In real engineering and test-automation platforms—such as our **XML Insight Lab** (`project/`)—Logstash plays a far more strategic role: it is the **central normalization, splitting, and rule-based error classification engine** of the entire Elastic Stack.

Without a dedicated Logstash normalization pipeline, complex hierarchical test reports (`<report>` XML files containing `initialization`, multiple `<groups>` suites, `<testCase>` retries, `<step>` executions, `<msg>` logs, `<errors>` blocks, and `deInitialization` steps) would arrive in Elasticsearch as deeply nested, unqueryable documents.

## Why Elasticsearch and Kibana alone are not enough for XML test reports

1. **Hierarchical granularity mismatch:** A single XML test report contains data at **five different levels of granularity** (`run`, `suite`, `test_case`, `step`, `message`). If you index the entire XML file as one Elasticsearch document, Kibana Lens cannot count individual failed test cases, isolate `suite` failures from `deInitialization` cleanup errors, or aggregate root causes per test bench without hitting array flattening traps.
2. **Separation of domain logic from visualization:** Error classification rules (mapping error codes and message patterns to `category`, `severity`, `disposition`, `root_cause`, and `owner`) belong in a deterministic, versioned ingest pipeline—not scattered across dozens of fragile Kibana filters or runtime fields.
3. **Three-way domain separation:** In test analytics, you must preserve three distinct pieces of truth simultaneously:
   - **Original Test Status (`source_result` / `normalized_result`):** What did the test bench actually report (`PASSED`, `FAILED`, `ERROR`)?
   - **Classified Failure Cause (`error_mapping.category` / `root_cause`):** Which known fault pattern occurred (`TIMEOUT`, `CAPTURE_ERROR`, `INFRASTRUCTURE`, `COMMUNICATION`, `DATA_INTEGRITY`)?
   - **Analytical Disposition (`error_mapping.disposition`):** How should engineering treat this fault (`RELEVANT`, `KNOWN_ISSUE`, `INVESTIGATE`, `IGNORED`)?

## End-to-end architecture in `project/`

```text
+-------------------------------------------------------------------+
| 1. XML Test Reports & Python CLI (tools/xml_insight_lab)          |
|    - Reads XML report, computes file_sha256, sends JSON envelope  |
+-------------------------------------------------------------------+
                                  |
                                  v  HTTP POST :8080 (JSON codec)
+-------------------------------------------------------------------+
| 2. Logstash Pipeline (project/logstash/pipeline/xml-insight.conf) |
|    - Stage 1: Security guard (rejects <!DOCTYPE / <!ENTITY XXE)   |
|    - Stage 2: Official Logstash `xml` filter (raw_xml -> hash)    |
|    - Stage 3: Ruby filter (`normalize_report.rb` +                |
|               `error_mapping.rb` + `config/error_mapping.yaml`)   |
|               Splits 1 XML report into N typed documents with     |
|               deterministic [@metadata][target_index] & [doc_id]  |
+-------------------------------------------------------------------+
                                  |
                                  v  Idempotent Bulk Indexing
+-------------------------------------------------------------------+
| 3. Elasticsearch (7 Strict Index Families)                        |
|    - xml-insight-runs-v1*        - xml-insight-steps-v1*          |
|    - xml-insight-suites-v1*      - xml-insight-messages-v1*       |
|    - xml-insight-testcases-v1*   - xml-insight-errors-v1*         |
|    - xml-insight-plan-status-v1*                                  |
+-------------------------------------------------------------------+
                                  |
                                  v  7 Data Views
+-------------------------------------------------------------------+
| 4. Kibana Lens Dashboards (xml-insight-dashboard.ndjson)          |
|    - 11 Dashboards using aggregated Lens Data Tables (lnsDatatable)|
|      KPI Metrics (lnsMetric), Stacked Bars (lnsXY) & Donuts       |
+-------------------------------------------------------------------+
```

## What this section covers

- **2. Logstash Pipeline Architecture & Configuration:** How `logstash.yml`, `xml-insight.conf`, the `http` input, DTD/XXE security guards, the `xml` filter, and `@metadata`-driven `elasticsearch` outputs work together.
- **3. XML Parsing & Ruby Filter 1-to-N Event Fan-Out:** How `normalize_report.rb` validates the parsed XML structure, normalizes timestamps and results, separates `phase: "suite"` from `phase: "deinit"`, and yields multiple child events from a single input event.
- **4. Config-Driven Error Mapping Engine:** How `config/error_mapping.yaml` and `logstash/ruby/error_mapping.rb` (`ConfigurationLoader`, `ErrorMatcher`, `ErrorClassifier`) classify errors at startup without per-event file I/O.
- **5. Deterministic Document IDs, Multi-Index Routing & Deduplication:** How SHA-256 document IDs prevent duplicates on re-ingestion and how faults are deduplicated across Message, Step, and TestCase hierarchy levels.
- **6. Kibana Data Views, Lens Data Tables (`lnsDatatable`) & Customization:** Understanding official Kibana terms (`Saved Search` vs. `Lens Data Table`), field cheat sheets for all 7 Data Views, and how to customize tables in the UI or in `xml-insight-dashboard.ndjson`.
- **7. Testing Ruby Filters, Debugging Pipelines & Historical Reprocessing:** Running Ruby unit tests inside the Logstash container, inspecting the `:9600` monitoring API, and reprocessing historical reports with `./scripts/reprocess.sh`.
- **8. Section 5 Wrapup:** Complete architectural summary and quick reference commands.


## Official References & Further Reading

- [Logstash Reference — XML Filter Plugin (store_xml, remove_namespaces, xpath)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-xml.html)
- [Logstash Reference — Ruby Filter Plugin (path, script_params, register, filter)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-ruby.html)
- [Logstash Reference — Accessing Event Data and @metadata Fields](https://www.elastic.co/guide/en/logstash/current/event-dependent-configuration.html)
- [Logstash Reference — Elasticsearch Output Plugin (index, document_id, action)](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html)
- [Logstash Reference — Node Stats & Pipeline Monitoring API (:9600)](https://www.elastic.co/guide/en/logstash/current/monitoring-apis.html)

<div class="chapter-nav">
<a class="chapter-nav__item" href="../04-importing-data-into-your-index-big-or-small/026-section-4-wrapup.html"><span>Previous</span><strong>26. Section 4 Wrapup</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="002-logstash-pipeline-architecture-and-configuration.html"><span>Next</span><strong>2. Logstash Pipeline Architecture & Configuration</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 5</a></p>
