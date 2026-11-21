---
title: "4. Config-Driven Error Mapping Engine (error_mapping.yaml)"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 05</div>

# 4. Config-Driven Error Mapping Engine (error_mapping.yaml)

Hardcoding error categories inside a parser script makes maintenance difficult as soon as new test benches, error codes, or firmware warnings appear. In `project/logstash/ruby/error_mapping.rb` and `project/config/error_mapping.yaml`, Logstash uses a modular, configuration-driven **Error Mapping Engine**.

## Clean Module Boundaries in `error_mapping.rb`

The Ruby implementation strictly separates responsibilities into four classes:

1. **`ConfigurationLoader` (`XmlInsightErrorMapping::ConfigurationLoader`)**
   - Loads `project/config/error_mapping.yaml` at Logstash startup.
   - Validates `defaults` and every rule (`id`, `priority`, `match.type`, `patterns`/`values`, optional `scope`, and `classification`).
   - Rejects duplicate rule IDs, invalid regular expressions, or unsupported matching types with a clear `ConfigurationError` (never silently falling back to legacy behavior on a broken config).
   - Sorts and freezes the validated `Rule` collection.
2. **`ErrorMatcher` (`XmlInsightErrorMapping::ErrorMatcher`)**
   - Pure matching logic with zero Elasticsearch or Logstash dependencies.
   - Evaluates extracted error codes, message text, and optional context scope (`phase`, `suite`, `test_case`, `component`) against all enabled rules.
3. **`ErrorClassifier` (`XmlInsightErrorMapping::ErrorClassifier`)**
   - Produces the structured `error_mapping` classification object (`rule_id`, `matched`, `matched_rule_ids`, `category`, `severity`, `disposition`, `root_cause`, `owner`, `mapping_version`).
   - Applies configured `defaults` (`UNKNOWN` / `MEDIUM` / `UNCLASSIFIED`) when an error does not match any rule.
4. **`Engine` (`XmlInsightErrorMapping::Engine`)**
   - Facade initialized once in `normalize_report.rb#register` and invoked for every message, step, and test case.

## Structure of `project/config/error_mapping.yaml`

```yaml
version: "1.0"

defaults:
  category: UNKNOWN
  severity: MEDIUM
  disposition: UNCLASSIFIED
  root_cause: UNKNOWN_CAUSE
  owner: UNASSIGNED

rules:
  - id: ERR_UI_TIMEOUT
    enabled: true
    priority: 100
    description: UI response or acknowledgement timeout by explicit error code
    match:
      type: error_code
      values:
        - UI_TIMEOUT
        - SYN_TIMEOUT_001
    classification:
      category: TIMEOUT
      severity: HIGH
      disposition: RELEVANT
      root_cause: UI_COMMUNICATION
      owner: APPLICATION

  - id: ERR_INIT_FAILURE
    enabled: true
    priority: 85
    description: Initialization workspace lock or setup failure
    scope:
      phase:
        - init
    match:
      type: regex
      field: message
      patterns:
        - "(?i).*SYN_INIT_5001.*"
        - "(?i).*workspace lock failed.*"
    classification:
      category: INFRASTRUCTURE
      severity: CRITICAL
      disposition: KNOWN_ISSUE
      root_cause: ENVIRONMENT_SETUP
      owner: TEST_INFRASTRUCTURE

  - id: ERR_EXPECTED_WARNING
    enabled: true
    priority: 50
    description: Non-critical cache warm-up or clock skew environment warning
    match:
      type: contains
      field: message
      values:
        - "Cache warm-up exceeded"
        - "Minor clock drift detected"
    classification:
      category: ENVIRONMENT_WARNING
      severity: LOW
      disposition: IGNORED
      root_cause: EXPECTED_BEHAVIOR
      owner: ENVIRONMENT
```

## Supported Matching Strategies & Priority Resolution

### 1. Four Matching Types (`match.type`)
- **`error_code`**: Matches against explicit `errorCode="..."` attributes or extracted tokens (`UI_TIMEOUT`, `IMG_CAPTURE_FAILED`, `SYN_INIT_5001`, etc.). Case-insensitive by default (`case_sensitive: false`).
- **`exact`**: Case-insensitive (or configurable `case_sensitive: true`) exact string match on the target field (`message`, `error_code`, `step_name`, `test_case_name`, `suite_name`, `component`).
- **`contains`**: Substring match against one or more `values`.
- **`regex`**: Matches one or more pre-compiled regular expressions (`patterns`) against the target field.

### 2. Optional Scope Restrictions (`scope`)
A rule can restrict matching to specific contexts:
- `phase`: e.g. `["init"]`, `["suite"]`, `["deinit"]`
- `suite`: e.g. `["Connectivity", "Workspace"]`
- `test_case`: e.g. `["TC_CONN_Handshake"]`
- `component`: matched against `component`, `group_name`, or `step_name`

### 3. Deterministic Priority & Tie-Breaking
When multiple rules match the same error event:
1. **Highest numerical `priority` wins** (`priority: 100` beats `priority: 95`).
2. **Tie-breaker:** If two rules share the exact same `priority`, the rule defined earlier in `error_mapping.yaml` (`index` order, then alphabetical `id`) wins deterministically.
3. **Full diagnostic trace:** The winning rule sets `error_mapping.rule_id`, while **all** matching rule IDs in priority order are stored in `error_mapping.matched_rule_ids` (e.g. `["ERR_UI_TIMEOUT", "ERR_UI_TIMEOUT_TEXT"]`).


## Official References & Further Reading

- [Logstash Reference — XML Filter Plugin (store_xml, remove_namespaces, xpath)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-xml.html)
- [Logstash Reference — Ruby Filter Plugin (path, script_params, register, filter)](https://www.elastic.co/guide/en/logstash/current/plugins-filters-ruby.html)
- [Logstash Reference — Accessing Event Data and @metadata Fields](https://www.elastic.co/guide/en/logstash/current/event-dependent-configuration.html)
- [Logstash Reference — Elasticsearch Output Plugin (index, document_id, action)](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html)
- [Logstash Reference — Node Stats & Pipeline Monitoring API (:9600)](https://www.elastic.co/guide/en/logstash/current/monitoring-apis.html)

<div class="chapter-nav">
<a class="chapter-nav__item" href="003-xml-parsing-and-ruby-filter-fanout.html"><span>Previous</span><strong>3. XML Parsing & Ruby Filter 1-to-N Event Fan-Out</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="005-idempotent-indexing-and-multi-index-routing.html"><span>Next</span><strong>5. Deterministic Document IDs, Multi-Index Routing & Deduplication</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 5</a></p>
