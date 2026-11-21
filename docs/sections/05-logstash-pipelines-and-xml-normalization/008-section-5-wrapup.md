---
title: "8. Section 5 Wrapup"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 05</div>

# 8. Section 5 Wrapup

You have completed **Section 5: Logstash Deep Dive, XML Pipelines & Error Mapping**.

## What this section covered

- **Why Logstash is central to XML Insight Lab (Chapter 1):** How Logstash bridges deeply nested `<report>` XML files and Elasticsearch/Kibana by splitting reports into 6 document granularities and separating **Original Test Status (`normalized_result`)**, **Classified Failure Cause (`error_mapping.category` / `root_cause`)**, and **Analytical Disposition (`error_mapping.disposition`)**.
- **Pipeline Architecture & Security Guards (Chapter 2):** Configuring `logstash.yml` and `xml-insight.conf` with an HTTP JSON input (`:8080`), DTD/XXE pre-checks, the official `xml` filter, the external `ruby` normalizer, and dynamic `[@metadata][target_index]` / `[@metadata][doc_id]` routing.
- **1-to-N Event Fan-Out in Ruby (Chapter 3):** Loading immutable configuration once in `register(params)` and yielding normalized `run`, `suite`, `test_case` (`phase: "suite"` vs. `phase: "deinit"`), `step`, `message`, and `error` events via `new_event_block.call(ev)`.
- **Config-Driven Error Mapping Engine (Chapter 4):** Designing `project/config/error_mapping.yaml` and `project/logstash/ruby/error_mapping.rb` (`ConfigurationLoader`, `ErrorMatcher`, `ErrorClassifier`) with `error_code`, `regex`, `contains`, and `exact` matchers, priority sorting, deterministic tie-breaking, and scope constraints.
- **Idempotency & Fault Deduplication (Chapter 5):** Computing deterministic SHA-256 document IDs from `file_sha256` and hierarchical coordinates so re-imports never duplicate data, and deduplicating fault counts across Message, Step, and TestCase levels.
- **Kibana Lens Data Tables & Customization (Chapter 6):** Replacing raw Discover Saved Searches (`type: "search"`) with aggregated **Lens Data Tables (`lnsDatatable`)**, understanding which fields live in which of the 7 Data Views, and customizing dashboards via the Kibana UI or `xml-insight-dashboard.ndjson`.
- **Testing, Monitoring & Reprocessing (Chapter 7):** Running `test_error_mapping.rb` inside the Logstash container, checking pipeline stats on `:9600`, and re-classifying historical reports with `./scripts/reprocess.sh`.

## Quick Reference Commands

```bash
cd project

# 1. Run Logstash Ruby unit tests + Python test suite + index verification
./scripts/verify.sh

# 2. Re-apply Kibana dashboards & Lens tables after editing xml-insight-dashboard.ndjson
docker compose run --rm tools provision-kibana

# 3. Reprocess all XML reports after editing config/error_mapping.yaml
./scripts/reprocess.sh
```


## Official References & Further Reading

- [Logstash Reference — XML Filter Plugin (store_xml, remove_namespaces, xpath)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-xml.html)
- [Logstash Reference — Ruby Filter Plugin (path, script_params, register, filter)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-ruby.html)
- [Logstash Reference — Accessing Event Data and @metadata Fields](https://www.elastic.co/guide/en/logstash/current/event-dependent-configuration.html)
- [Logstash Reference — Elasticsearch Output Plugin (index, document_id, action)](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html)
- [Logstash Reference — Node Stats & Pipeline Monitoring API (:9600)](https://www.elastic.co/guide/en/logstash/current/monitoring-apis.html)

<div class="chapter-nav">
<a class="chapter-nav__item" href="007-testing-debugging-and-historical-reprocessing.html"><span>Previous</span><strong>7. Testing Ruby Filters, Debugging Pipelines & Historical Reprocessing</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="../06-aggregation/001-section-6-intro.html"><span>Next</span><strong>1. Section 6 Intro</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 5</a></p>
