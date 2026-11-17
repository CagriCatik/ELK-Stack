# Architecture & Data Modeling — XML Insight Lab

This document provides a deep-dive reference into the **system architecture**, **ingestion & validation pipeline**, **Elasticsearch data model**, **normalization rules**, and **Kibana analytics hierarchy** of **XML Insight Lab**.

---

## 1. End-to-End System Architecture

```mermaid
flowchart LR
  XML["Synthetic report XML Files"]
  PLAN["Campaign Plan YAML"]
  CLI["Python CLI (tools container)"]
  LS_IN["Logstash HTTP Input (:8080)"]
  LS_XML["Logstash XML Filter"]
  LS_RB["Ruby Normalizer (normalize_report.rb)"]
  ES_OK[("Elasticsearch: Data & Plan Indices")]
  ES_ERR[("Elasticsearch: xml-insight-errors-v1")]
  REC["Plan Reconciler (reconciler.py)"]
  KB["Kibana (:5601) — 10 Dashboards"]

  XML -->|"1. Full XML + SHA-256 JSON envelope"| CLI
  CLI -->|"2. HTTP POST with retry/backoff"| LS_IN
  LS_IN -->|"3. Size & DTD guard"| LS_XML
  LS_XML -->|"4. Parsed XML tree"| LS_RB
  LS_RB -->|"5a. Valid: split into 5 indices"| ES_OK
  LS_RB -->|"5b. Invalid: reject whole report"| ES_ERR
  PLAN -->|"6. Expected slots & suites"| REC
  ES_OK <-->|"7. Match runs & compute error_trend"| REC
  ES_ERR -->|"7b. Flag INVALID receipts"| REC
  ES_OK --> KB
  ES_ERR --> KB
```

### End-to-End Execution Sequence

```mermaid
sequenceDiagram
  autonumber
  participant U as Python Uploader
  participant L as Logstash (:8080)
  participant R as normalize_report.rb
  participant E as Elasticsearch (:9200)
  participant C as Reconciler CLI
  participant K as Kibana (:5601)

  U->>U: Read full XML bytes, compute SHA-256, strip local path
  U->>L: POST JSON envelope (raw_xml, source_file, file_sha256)
  L-->>U: HTTP 200 (envelope accepted, not yet indexed)
  L->>L: Check raw_xml presence & reject DOCTYPE/ENTITY
  L->>R: Parse XML with remove_namespaces=true, force_array=false
  alt Report is valid
    R->>E: Index 1 Run + N Suites + M TestCases + K Steps + P Messages
  else Parse, DTD, timestamp, or validation error
    R->>E: Index 1 Error doc in xml-insight-errors-v1 (0 partial docs)
  end
  C->>E: Read campaign-plan.yaml, query runs & errors
  C->>E: Upsert xml-insight-plan-status-v1 & update error_trend
  K->>E: Query 7 Data Views across 10 Dashboards
```

### Key Architectural Principles

1. **No Line-Based XML Tailing:** Multi-line XML files are read completely by `uploader.py` and sent as a single JSON envelope so Logstash never splits one XML report into multiple unrelated events.
2. **Logstash Owns Parsing & Domain Normalization:** The uploader never converts XML into Elasticsearch documents; it only handles transport, SHA-256 hashing, and bounded retries.
3. **Atomic Validation Before Splitting:** `normalize_report.rb` validates the entire `<report>` before emitting any child events. An invalid report never leaves partial suites or test cases in Elasticsearch.
4. **Stateless Multi-Worker Safety:** `normalize_report.rb` uses zero mutable global state and immutable `TZInfo::Timezone` objects, making it safe across multiple Logstash pipeline workers.
5. **Local-Only Exposure:** Host ports are bound strictly to `127.0.0.1` (`9200`, `5601`, `8080`). `xpack.security.enabled=false` is used exclusively for local development convenience.

---

## 2. Logstash Validation & Routing Pipeline

```mermaid
flowchart TD
  IN["Incoming JSON Envelope"] --> C1{"raw_xml present<br/>and <= 5 MiB?"}
  C1 -- "No" --> ERR1["xml-insight-errors-v1<br/>(MISSING_RAW_XML / XML_TOO_LARGE)"]
  C1 -- "Yes" --> C2{"Contains DOCTYPE<br/>or ENTITY?"}
  C2 -- "Yes" --> ERR2["xml-insight-errors-v1<br/>(DTD_OR_ENTITY_FORBIDDEN)"]
  C2 -- "No" --> XMLF["Logstash xml filter<br/>(store_xml=true, force_array=false)"]
  XMLF --> C3{"_xmlparsefailure?"}
  C3 -- "Yes" --> ERR3["xml-insight-errors-v1<br/>(MALFORMED_XML)"]
  C3 -- "No" --> C4{"Required metadata,<br/>valid TZ/DST & end >= start?"}
  C4 -- "No" --> ERR4["xml-insight-errors-v1<br/>(MISSING_REPORT_METADATA / INVALID_REPORT_TIMESTAMP)"]
  C4 -- "Yes" --> SPLIT["Split into Run, Suites, TestCases, Steps, Messages"]
```

---

## 3. Logical Domain Hierarchy & XML-to-Elasticsearch Mapping

### Entity-Relationship Overview

```mermaid
erDiagram
  CAMPAIGN ||--o{ PLAN_SLOT : "schedules"
  PLAN_SLOT ||--o| RUN : "execution_slot_id"
  RUN ||--o{ SUITE : "regular suites"
  RUN ||--o{ TESTCASE : "deinit testCases (phase=deinit)"
  SUITE ||--o{ TESTCASE : "regular testCases (phase=suite)"
  TESTCASE ||--o{ STEP : "ordered by step.sequence"
  TESTCASE ||--o{ MESSAGE : "testcase_msg & errors_block"
  STEP ||--o{ MESSAGE : "step_msg"
```

### How One `<report>` Splits Across the 5 Data Indices

```mermaid
flowchart LR
  REP["<report bench='lab-01' project='SampleProject'>"]
  INIT["<groups name='initialization'>"]
  SUITE["<groups name='Workspace'>"]
  TC["<testCase name='TC_WORKSPACE_002' result='FAILED'>"]
  ST1["<step name='Emit_Signal' result='PASSED'>"]
  ST2["<step name='Emit_Signal' result='FAILED'>"]
  ERRB["<errors><msg>UI_TIMEOUT...</msg></errors>"]
  DEINIT["<groups name='deInitialization'>"]
  DTC["<testCase name='TC_DEINIT_CLEANUP' result='PASSED'>"]

  REP --> INIT
  REP --> SUITE --> TC
  TC --> ST1
  TC --> ST2
  TC --> ERRB
  REP --> DEINIT --> DTC

  REP -.->|"1 doc (_id = run.id)"| IDX_RUN["xml-insight-runs-v1"]
  SUITE -.->|"1 doc per regular suite"| IDX_SUITE["xml-insight-suites-v1"]
  TC -.->|"phase = suite"| IDX_TC["xml-insight-testcases-v1"]
  DTC -.->|"phase = deinit"| IDX_TC
  ST1 -.->|"sequence = 1"| IDX_STEP["xml-insight-steps-v1"]
  ST2 -.->|"sequence = 2"| IDX_STEP
  ERRB -.->|"origin_context = errors_block"| IDX_MSG["xml-insight-messages-v1"]
```

### Index Family Contracts (`"dynamic": "strict"`)

| Index Name | Counting Level | Deterministic `_id` | Key Fields & Purpose |
| --- | --- | --- | --- |
| `xml-insight-runs-v1` | 1 doc per `<report>` | `run.id` (or `imp-<sha256[:16]>`) | Run metadata, `init_normalized_result`, `deinit_normalized_result`, `suite_count`, `regular_tc_*`, `deinit_tc_*`, `init_params` (`nested`) |
| `xml-insight-suites-v1` | 1 doc per regular suite | `<run.id>::suite::<seq>::<suite.id>` | Suite name/version, `normalized_result`, `tc_total`, `tc_passed`, `tc_failed`, `tc_skipped` |
| `xml-insight-testcases-v1` | 1 doc per `<testCase>` | `<run.id>::<phase>::<suite_seq>::<exec_id>::<attempt>` | `phase` (`suite` \| `deinit`), `attempt`, `is_first_attempt`, `is_final_attempt`, `is_retry`, `error_category`, `error_trend`, `duration_ms` |
| `xml-insight-steps-v1` | 1 doc per `<step>` | `<run.id>::<phase>::<suite_seq>::<exec_id>::<attempt>::<step_seq>` | Preserves `step.sequence` and repeated same-named steps (e.g., two `Emit_Signal` steps), `assertions` (`nested`), `artifact_paths` |
| `xml-insight-messages-v1` | 1 doc per `<msg>` | `sha256(<composite_key>)[:32]` | `origin_context` (`group_msg`, `step_msg`, `testcase_msg`, `errors_block`), `position`, `level` (omitted if absent), `original_text`, `extracted_error_codes` |
| `xml-insight-errors-v1` | 1 doc per rejected XML | `<file_sha256>::<error_code>` | `error_stage`, `error_code`, `error_message`, `source_file` |
| `xml-insight-plan-status-v1` | 1 doc per planned slot | `<campaign.id>::<execution_slot_id>` | `receipt_status`, `suite_completeness`, `missing_suites`, `report_validity`, `is_late` |

### Why Denormalization Matters

Elasticsearch does not support SQL-style runtime joins across indices. Therefore, every child document (`suites`, `testcases`, `steps`, `messages`) carries denormalized parent context (`campaign.id`, `run.id`, `test_bench.id`, `project`, `software.version`, `suite.name`) so Kibana filters and Lens Data Tables slice any level directly without joins.

---

## 4. Timezone, Duration & Result Normalization

### Timezone Conversion Flow (`SOURCE_TIMEZONE` → UTC)

```mermaid
flowchart TD
  TS["Raw Timestamp String"] --> HAS_OFF{"Has explicit Z or<br/>UTC offset?"}
  HAS_OFF -- "Yes" --> PARSE_UTC["Parse directly as UTC<br/>timezone_status = explicit_utc"]
  HAS_OFF -- "No" --> TZ["Apply SOURCE_TIMEZONE<br/>(default: Europe/Berlin via TZInfo)"]
  TZ --> VALID_LOCAL{"Valid local time?"}
  VALID_LOCAL -- "Ambiguous DST fall-back" --> AMB["Convert first occurrence to UTC<br/>timezone_status = ambiguous_dst"]
  VALID_LOCAL -- "Non-existent DST spring-forward" --> REJ["Reject to xml-insight-errors-v1<br/>(INVALID_REPORT_TIMESTAMP)"]
  VALID_LOCAL -- "Unambiguous local time" --> OK_UTC["Convert to UTC ISO-8601<br/>timezone_status = assumed_local"]
```

### Status & Duration Rules

- **Preserving Reported vs. Derived Results:** `source_result` stores the exact XML string. `normalized_result` maps missing values to `UNKNOWN` (e.g., `<groups name="initialization">` without `result` never invents `PASSED` or `FAILED`).
- **Warnings & Errors Separation:** A `<msg level="warning">` never turns `PASSED` into `FAILED`. Multiple `<errors><msg>` entries inside a single `<testCase>` create multiple documents in `xml-insight-messages-v1` while counting as **one** failed test case in `xml-insight-testcases-v1`.
- **Duration Assumption:** `duration` attributes are explicitly interpreted as **seconds** and converted to integer `duration_ms`. Missing `duration` leaves `duration_ms` absent (`null`), and report duration is never assumed to equal the sum of test case durations.
- **No Dynamic Field Explosion:** Unknown `<param name="..." value="..."/>` elements are stored as `nested` `{name, value}` objects in `init_params`, while `SoftwareVersion` is explicitly mapped to `software.version`.

---

## 5. Campaign Plan Reconciliation & Error Trends

```mermaid
stateDiagram-v2
  [*] --> PENDING: "Before deadline_at, no report yet"
  PENDING --> MISSING: "evaluated_at > deadline_at, no report"
  PENDING --> RECEIVED_VALID: "Valid report arrives"
  PENDING --> RECEIVED_INVALID: "Invalid report arrives (errors index)"
  RECEIVED_VALID --> COMPLETE: "All expected_suites present"
  RECEIVED_VALID --> PARTIAL: "One or more expected_suites missing"
```

- **Separate Receipt vs. Result:** A `RECEIVED_INVALID` report is recorded with `receipt_status: "RECEIVED"` and `report_validity: "INVALID"`, with `run_result` omitted so an invalid report never counts as `PASSED`.
- **`MISSING` Semantics:** `MISSING` strictly means no matching report arrived before `deadline_at`; it does not claim tests were never executed.
- **Error Trends (`NEW`, `RECURRING`, `FIXED`):** `reconciler.py` sorts regular final-attempt test cases chronologically per `(test_bench.id, suite.name, test_case.name)` and compares each outcome against the previous run:
  - Failed now, passed/absent before → `NEW`
  - Failed now, failed before → `RECURRING`
  - Passed now, failed before → `FIXED`

---

## 6. Kibana Analytics & Drilldown Flow

```mermaid
flowchart LR
  D1["01. Nightly Overview<br/>08. Bench & Suite Matrix<br/>10. Campaign Matrix"] -->|"Spot failing bench, suite, or missing report"| D2["02. Suite Overview<br/>05. Bench Heatmaps<br/>06. Error & Retry Analytics<br/>07. Version Regression Lab<br/>09. TestCase Matrix"]
  D2 -->|"Filter by run.id (Last 7 days)"| D3["03. Run Details<br/>(Metadata, Suites, Deinit)"]
  D3 -->|"Inspect ordered steps & messages"| D4["04. Test Details<br/>(Steps + <errors> messages)"]
```

- **Lens Data Tables (`lnsDatatable`):** Used in Dashboards `08`, `09`, and `10` to aggregate failures, error codes, retries, and P95 durations by `test_bench.id` × `suite.name` × `test_case.name` without scrolling raw document rows.
- **Heatmaps (`lnsHeatmap`), Donuts (`lnsPie`) & Trends (`lnsXY`):** Surface cross-bench hotspots, software version regressions (`1.5.0-rc1` + `TC_CONTENT_Capture`), and multi-night duration creep (`Settings`).
- **Focused Saved Searches:** Used in `Run Details` and `Test Details` with slim 4–7 column layouts for ordered step-by-step and message-level root-cause inspection.
