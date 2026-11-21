# Configurable Error Mapping Engine

XML Insight Lab separates **raw XML test outcomes** from **rule-based error classification** and **analytical disposition**. All classification rules live in [`config/error_mapping.yaml`](../config/error_mapping.yaml) and are loaded once when Logstash starts.

## Architecture & Module Boundaries

1. **Configuration Loader (`logstash/ruby/error_mapping/config_loader.rb`):**
 - Loads `config/error_mapping.yaml`during Logstash `register(params)`(no per-event file I/O).
 - Validates `version`, `defaults`, unique rule IDs, integer `priority`, supported `match.type`(`exact`, `contains`, `regex`, `error_code`), valid `severity`and `disposition`, and pre-compiles all regexes.
 - Invalid configurations raise `ErrorMapping::ConfigurationError`at startup and **fail fast** instead of silently falling back to defaults.
2. **Error Matcher (`logstash/ruby/error_mapping/matcher.rb`):**
 - Pure Ruby matcher with zero Logstash/Elasticsearch dependencies.
 - Evaluates enabled rules matching optional `scope`constraints (`phases`, `suites`, `test_cases`, `components`).
3. **Error Classifier (`logstash/ruby/error_mapping/classifier.rb`):**
 - Builds the immutable `error_mapping`payload and aggregates multiple matched rules deterministically.
4. **XML Normalizer (`logstash/ruby/normalize_report.rb`):**
 - Extracts context and messages, invokes the matcher/classifier, and attaches `error_mapping`to `xml-insight-messages-v1`, `xml-insight-steps-v1`, and `xml-insight-testcases-v1`.

## Rule Priority & Tie-Breaking

Rules are sorted once at startup by `[-priority, config_index, id]`:
- **Higher numeric `priority`wins.**
- **Tie-breaker:** Earlier rule definition in `error_mapping.yaml`, then lexical `id`.
- All matching rule IDs are preserved in `error_mapping.matched_rule_ids`for diagnostics.

## Supported Matching Types

| `match.type`| Behavior | Default Case Sensitivity |
| --- | --- | --- |
| `error_code`| Matches extracted or explicit `errorCode`tokens against `values`| Case-insensitive (`case_sensitive: true`optional) |
| `exact`| Exact string equality on `match.field`(default `message`) | Case-insensitive |
| `contains`| Substring match on `match.field`| Case-insensitive |
| `regex`| Pre-compiled Ruby `Regexp`match against `patterns`| Case-insensitive (`Regexp::IGNORECASE`) |

## Original Status vs. Classification & Disposition

XML files **never** contain pre-classified results. `source_result`and `normalized_result`(`PASSED`, `FAILED`, `ERROR`, `SKIPPED`, `UNKNOWN`) are never overwritten by `error_mapping`:

- **`RELEVANT`**: Actionable application/test failure counted in relevant-failure KPIs.
- **`KNOWN_ISSUE`**: Known infrastructure/environment issue (e.g., `ERR_INIT_FAILURE`) tracked separately without hiding the `FAILED`/`ERROR`test result.
- **`IGNORED`**: Benign expected warning (e.g., `ERR_EXPECTED_WARNING`) that does not inflate failure metrics.
- **`UNCLASSIFIED`**: Fallback when no enabled rule matches (`matched: false`, `category: "UNKNOWN"`).

## Elasticsearch Fields & Fault Deduplication

Added to `xml-insight-testcases-v1`, `xml-insight-steps-v1`, and `xml-insight-messages-v1`(with `"dynamic": "strict"`):

```json
{
 "error_mapping": {
 "matched": true,
 "rule_id": "ERR_UI_TIMEOUT",
 "matched_rule_ids": ["ERR_UI_TIMEOUT"],
 "category": "TIMEOUT",
 "severity": "HIGH",
 "disposition": "RELEVANT",
 "root_cause": "UI_COMMUNICATION",
 "owner": "APPLICATION",
 "mapping_version": "1.0"
 }
}
```

- **Deduplication across `<step><msg>`and `<errors><msg>`:** Every XML `<msg>`remains an individual document in `xml-insight-messages-v1`, while `xml-insight-testcases-v1`deduplicates **winning primary fault causes** across steps and `<errors>`(`fault_count`). Even if a single `UI_TIMEOUT`message matches both `ERR_UI_TIMEOUT`and `ERR_UI_TIMEOUT_TEXT`and appears in both `<step><msg>`and `<errors><msg>`, it counts as **1** unique fault (`fault_count`) while `error_mapping.matched_rule_ids`preserves all matching rule IDs for diagnostics.
- **Hierarchy Counting Levels:**
 - `xml-insight-testcases-v1`: counts **affected TestCases** (1 doc = 1 TestCase execution; `sum(fault_count)`= unique fault causes per TestCase).
 - `xml-insight-steps-v1`: counts **individual `<step>`executions**.
 - `xml-insight-messages-v1`: counts **individual `<msg>`/ `<errors><msg>`entries**.
- Backward-compatible fields `error_category`and `analysis_classification`are populated from `error_mapping.category`and `error_mapping.disposition`.
- Note: `xml-insight-errors-v1`remains strictly reserved for ingestion/XML validation errors.

## Kibana Dashboard

The **Error Classification & Root Cause Analysis** dashboard (`/app/dashboards#/view/xml-insight-error-classification`) visualizes:
- Errors by Category & Severity, Dispositions (`RELEVANT`/ `KNOWN_ISSUE`/ `IGNORED`/ `UNCLASSIFIED`), Error Trend Over Time, Top Mapping Rules, Bench/Suite/TestCase breakdowns, Unclassified Errors, Recurring Errors by Software Version, Retry outcomes, and Drilldown to original XML messages.

## Adding Custom Rules & Reprocessing

1. Edit [`config/error_mapping.yaml`](../config/error_mapping.yaml) and add a new rule with a unique `id`and `priority`.
2. Run [`./scripts/reprocess.sh`](../scripts/reprocess.sh) to restart Logstash (validating the new rules), re-ingest existing XML reports without creating duplicates (deterministic `_id`s), and re-run plan reconciliation.
3. Run `./scripts/verify.sh`to validate Ruby unit tests, YAML schema, and E2E indexing.
