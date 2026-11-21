---
title: "5. Deterministic Document IDs, Multi-Index Routing & Deduplication"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 05</div>

# 5. Deterministic Document IDs, Multi-Index Routing & Deduplication

In production pipelines, the same XML report may be sent to Logstash more than once—for example during network retries, batch re-imports, or after updating `error_mapping.yaml`. If Logstash allowed Elasticsearch to auto-generate random document IDs, re-ingesting a report would double every KPI counter in Kibana.

## Deterministic SHA-256 Document IDs (`doc_id`)

In `project/logstash/ruby/normalize_report.rb`, every emitted document computes a deterministic SHA-256 primary key based on `file_sha256` (the SHA-256 checksum of the raw XML report) and the hierarchical coordinates of the entity inside that report:

```ruby
def deterministic_id(*parts)
  Digest::SHA256.hexdigest(parts.map(&:to_s).join("|"))
end
```

| Document Type | Target Index | Deterministic `doc_id` Formula |
| :--- | :--- | :--- |
| **Run** | `xml-insight-runs-v1` | `SHA256(file_sha256 \| "run" \| run_id)` |
| **Suite** | `xml-insight-suites-v1` | `SHA256(file_sha256 \| "suite" \| suite_seq \| suite_id)` |
| **TestCase** | `xml-insight-testcases-v1` | `SHA256(file_sha256 \| "tc" \| phase \| suite_seq \| tc_seq \| execution_id \| attempt)` |
| **Step** | `xml-insight-steps-v1` | `SHA256(file_sha256 \| "step" \| phase \| suite_seq \| tc_seq \| step_seq)` |
| **Message** | `xml-insight-messages-v1` | `SHA256(file_sha256 \| "msg" \| phase \| origin_context \| suite_seq \| tc_seq \| step_seq \| msg_pos)` |
| **Error** | `xml-insight-errors-v1` | `SHA256(file_sha256 \| "error" \| error_type)` |

And in `logstash/pipeline/xml-insight.conf`, the `elasticsearch` output uses that exact `doc_id` with `action => "index"`:

```ruby
output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "%{[@metadata][target_index]}"
    document_id => "%{[@metadata][doc_id]}"
    action => "index"
  }
}
```

Because `action => "index"` overwrites an existing document when the `_id` matches, re-ingesting the same XML file **updates all documents in place** with zero duplicates.

## Fault Deduplication & Hierarchy Levels

A critical analytical requirement in XML test reports is avoiding double-counting when the same underlying failure is reported at multiple levels or matched by multiple rules:

1. **Multiple rules matching one message/step are NOT multiple faults:**
   - Suppose a `<msg errorCode="UI_TIMEOUT">Waiting for Output_A acknowledgement.</msg>` matches both `ERR_UI_TIMEOUT` (`priority: 100`, `type: error_code`) and `ERR_UI_TIMEOUT_TEXT` (`priority: 95`, `type: regex`).
   - That is **one single fault event**, not two. `error_mapping.rule_id` records the highest-priority winner (`ERR_UI_TIMEOUT`), while `error_mapping.matched_rule_ids` preserves `["ERR_UI_TIMEOUT", "ERR_UI_TIMEOUT_TEXT"]` purely for rule diagnostics.
2. **Deduplication between Step messages and `<errors>` summary blocks within a TestCase:**
   - Many XML test reports log an error inside `<step><msg errorCode="UI_TIMEOUT">...</msg></step>` and repeat the same error code inside the testCase's `<errors><msg errorCode="UI_TIMEOUT">...</msg></errors>` summary block.
   - When `normalize_report.rb` computes `fault_count` on the `test_case` document, it deduplicates fault events by their winning `rule_id` / error code signature rather than summing raw `matched_rule_ids` array lengths.
3. **Clear index separation in Kibana Dashboards:**
   - **Affected TestCases** are queried on `xml-insight-testcases-v1*` (`phase : "suite"`), where each document represents one testCase execution and receives the highest-priority `error_mapping` classification among its steps/errors.
   - **Failed Steps** are queried on `xml-insight-steps-v1*`.
   - **Individual Diagnostic Messages (`<msg>` / `<errors>`)** are queried on `xml-insight-messages-v1*`.


## Official References & Further Reading

- [Logstash Reference — XML Filter Plugin (store_xml, remove_namespaces, xpath)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-xml.html)
- [Logstash Reference — Ruby Filter Plugin (path, script_params, register, filter)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-ruby.html)
- [Logstash Reference — Accessing Event Data and @metadata Fields](https://www.elastic.co/guide/en/logstash/current/event-dependent-configuration.html)
- [Logstash Reference — Elasticsearch Output Plugin (index, document_id, action)](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html)
- [Logstash Reference — Node Stats & Pipeline Monitoring API (:9600)](https://www.elastic.co/guide/en/logstash/current/monitoring-apis.html)

<div class="chapter-nav">
<a class="chapter-nav__item" href="004-config-driven-error-mapping-engine.html"><span>Previous</span><strong>4. Config-Driven Error Mapping Engine (error_mapping.yaml)</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="006-kibana-lens-tables-and-dashboard-customization.html"><span>Next</span><strong>6. Kibana Data Views, Lens Data Tables (lnsDatatable) & Customization</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 5</a></p>
