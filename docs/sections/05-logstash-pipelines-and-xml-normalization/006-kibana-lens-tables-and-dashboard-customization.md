---
title: "6. Kibana Data Views, Lens Data Tables (lnsDatatable) & Customization"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 05</div>

# 6. Kibana Data Views, Lens Data Tables (lnsDatatable) & Customization

Once Logstash has normalized and routed our XML test reports into the 7 Elasticsearch index families, **Kibana** visualizes them across 11 dashboards provisioned from `project/kibana/provisioning/xml-insight-dashboard.ndjson`.

This chapter explains the official Kibana terminology, why **Lens Data Tables (`lnsDatatable`)** are used instead of raw **Discover Saved Searches (`type: "search"`)**, and how you can customize tables and dashboards yourself.

## 1. Official Kibana Terminology: Saved Search vs. Lens Data Table

In Kibana, there are two fundamentally different ways to display a table on a dashboard:

| Feature | 1. Discover Saved Search (`type: "search"`) | 2. Lens Data Table (`type: "lens"`, `visualizationType: "lnsDatatable"`) |
| :--- | :--- | :--- |
| **Official UI Name** | **Discover** / **Saved Search** | **Lens → Table** (`lnsDatatable`) |
| **What does 1 row represent?** | **One single raw JSON document** in Elasticsearch | **An aggregated group** (e.g. grouped by `Bench`, `Suite`, `Category`, `Rule ID`) |
| **`@timestamp` column** | Forced on the left with an expand toggle (`>`) | **No `@timestamp` clutter** — only the columns you explicitly configure |
| **Column Headers** | Raw field names (`test_case.name`) + type icons (`k`, `t`, `#`) | Clean custom headers (`customLabel: true`, e.g. `TestCase`, `Failures`) |
| **Metrics & Formulas** | **None** (cannot sum, count, or group) | **Full aggregations** (`Count`, `Sum`, `Unique count`, filtered metrics) |
| **When to use** | Ad-hoc raw document inspection in *Discover* | **All dashboard tables** across our 11 dashboards |

## 2. Field Cheat Sheet Across All 7 Data Views

When editing or creating a visualization in Kibana Lens, always select the **Data View** that matches the granularity of the question you are asking:

| Data View (`index-pattern`) | Key Grouping Dimensions (`Rows` / `terms`) | Key Metrics (`Metrics` / `count`, `sum`, `unique_count`) |
| :--- | :--- | :--- |
| **`xml-insight-runs-v1*`** | `run.id`, `campaign.id`, `test_bench.id`, `software.version`, `normalized_result`, `init_normalized_result`, `deinit_normalized_result`, `data_quality_issues` | `suite_count`, `regular_tc_total`, `regular_tc_passed`, `regular_tc_failed`, `regular_tc_error`, `deinit_tc_total`, `deinit_tc_failed` |
| **`xml-insight-suites-v1*`** | `run.id`, `test_bench.id`, `software.version`, `suite.name`, `normalized_result` | `tc_total`, `tc_passed`, `tc_failed`, `tc_error`, `tc_skipped` |
| **`xml-insight-testcases-v1*`** | `run.id`, `test_bench.id`, `software.version`, `phase` (`suite`/`deinit`), `suite.name`, `test_case.name`, `normalized_result`, `error_mapping.category`, `error_mapping.rule_id`, `error_mapping.root_cause`, `error_mapping.disposition`, `error_mapping.owner`, `error_mapping.severity`, `extracted_error_codes` | `step_count`, `failed_step_count`, `fault_count`, `error_msg_count` |
| **`xml-insight-steps-v1*`** | `run.id`, `test_bench.id`, `suite.name`, `test_case.name`, `step.name`, `normalized_result`, `error_mapping.category`, `error_mapping.rule_id`, `extracted_error_codes` | `step.sequence` |
| **`xml-insight-messages-v1*`** | `run.id`, `phase`, `origin_context` (`group_msg`/`step_msg`/`errors_block`), `test_case.name`, `level` (`info`/`warning`/`error`), `original_text.keyword`, `error_mapping.category`, `error_mapping.rule_id` | `position` |
| **`xml-insight-errors-v1*`** | `source_file`, `error_type`, `error_message`, `campaign.id` | `count` |
| **`xml-insight-plan-status-v1*`** | `campaign.id`, `test_bench.id`, `receipt_status`, `suite_completeness`, `missing_suites`, `run_result` | `is_late` |

## 3. Two Ways to Customize Dashboards and Tables Yourself

### Method A: Directly in the Kibana Web UI (Point & Click)
1. Open `http://127.0.0.1:5601/app/dashboards` and select any dashboard.
2. Click **Edit** in the top-right corner.
3. On any table or chart panel, click the **gear icon → Edit visualization** to open the **Kibana Lens** editor.
4. In the Lens editor:
   - Choose the **Data View** on the left (e.g. `xml-insight-testcases-v1*`).
   - Drag fields into **Rows** (grouping columns) or **Metrics** (calculated numbers).
   - Click any row or metric → enable **Custom label** to set a clean column header.
   - Under **Advanced → Include missing values** (`missingBucket: true`), enable showing rows where an optional field (such as `error_mapping.category` on passed steps) is empty.
5. Click **Save and return**, then **Save** on the dashboard.
6. To persist UI edits back into Git, export them under **Stack Management → Saved Objects → Export** as `.ndjson`.

### Method B: Editing `project/kibana/provisioning/xml-insight-dashboard.ndjson`
All 109 saved objects (7 Data Views, 11 Dashboards, and all Lens panels) live in `project/kibana/provisioning/xml-insight-dashboard.ndjson` (one JSON object per line). After modifying a column label, field, or query in that file, apply your changes to Kibana without losing any Elasticsearch data:

```bash
cd project
docker compose run --rm tools provision-kibana
```


## Official References & Further Reading

- [Logstash Reference — XML Filter Plugin (store_xml, remove_namespaces, xpath)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-xml.html)
- [Logstash Reference — Ruby Filter Plugin (path, script_params, register, filter)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-ruby.html)
- [Logstash Reference — Accessing Event Data and @metadata Fields](https://www.elastic.co/guide/en/logstash/current/event-dependent-configuration.html)
- [Logstash Reference — Elasticsearch Output Plugin (index, document_id, action)](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html)
- [Logstash Reference — Node Stats & Pipeline Monitoring API (:9600)](https://www.elastic.co/guide/en/logstash/current/monitoring-apis.html)

<div class="chapter-nav">
<a class="chapter-nav__item" href="005-idempotent-indexing-and-multi-index-routing.html"><span>Previous</span><strong>5. Deterministic Document IDs, Multi-Index Routing & Deduplication</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="007-testing-debugging-and-historical-reprocessing.html"><span>Next</span><strong>7. Testing Ruby Filters, Debugging Pipelines & Historical Reprocessing</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 5</a></p>
