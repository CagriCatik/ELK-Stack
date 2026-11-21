# Elasticsearch Data Model & Counting Levels

XML Insight Lab separates every level of the hierarchy into **seven explicitly mapped (`dynamic: "strict"`) index families**:

| Index Name | Counting Level | Key Rules |
| --- | --- | --- |
| `xml-insight-runs-v1`| 1 doc per `<report>`| Holds `init_normalized_result`, `deinit_normalized_result`, `suite_count`, `regular_tc_*`, `deinit_tc_*`, `init_params`(`nested`) |
| `xml-insight-suites-v1`| 1 doc per regular suite `<groups>`| Excludes `initialization`, `deInitialization`, and `extra_group`|
| `xml-insight-testcases-v1`| 1 doc per `<testCase>`| `phase: "suite"`vs `phase: "deinit"`; `error_trend`(`NEW`, `RECURRING`, `FIXED`, `NONE`) |
| `xml-insight-steps-v1`| 1 doc per `<step>`| Preserves `step.sequence`and repeated same-named steps (e.g., two `Emit_Signal`steps) |
| `xml-insight-messages-v1`| 1 doc per `<msg>`| `origin_context`(`group_msg`, `step_msg`, `testcase_msg`, `errors_block`); `level`omitted when absent |
| `xml-insight-errors-v1`| 1 doc per rejected XML | Parse, DTD, size, or timestamp validation errors |
| `xml-insight-plan-status-v1`| 1 doc per planned slot | Tracks both `receipt_status`(`RECEIVED`/`MISSING`/`PENDING`) and `suite_completeness`(`COMPLETE`/`PARTIAL`/`NONE`) |
