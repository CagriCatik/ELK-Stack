# Kibana Dashboards & Drilldown Guide

XML Insight Lab provisions **10 Kibana dashboards** (55 panels across Lens Data Tables, Heatmaps, Donut/Pie charts, Line/Area/Bar trends, and focused Saved Search tables) backed by **7 Data Views**.

## Provisioned Dashboards

| # | Dashboard | URL | Focus |
| --- | --- | --- | --- |
| 1 | **Nightly Overview** | `/app/dashboards#/view/xml-insight-nightly-overview` | Expected/received/missing/partial/invalid reports, duration & testcase trends, plan & error tables |
| 2 | **Suite Overview** | `/app/dashboards#/view/xml-insight-suite-overview` | Suites per bench, regular testcase results (`phase: "suite"`), new/recurring/fixed errors, P95 durations |
| 3 | **Run Details** | `/app/dashboards#/view/xml-insight-run-details` | Report metadata, included suites, and separate `deInitialization` testcases (`phase: "deinit"`) |
| 4 | **Test Details** | `/app/dashboards#/view/xml-insight-test-details` | Steps in original `step.sequence` order and messages / explicit `<errors>` entries |
| 5 | **Bench Comparison & Heatmaps** | `/app/dashboards#/view/xml-insight-bench-comparison` | Bench × Suite heatmaps (P95 & failures), donut/pie shares, bench duration trend |
| 6 | **Error & Retry Analytics** | `/app/dashboards#/view/xml-insight-error-analytics` | Error categories, `NEW`/`RECURRING`/`FIXED` trends, horizontal error codes, retry recovery |
| 7 | **Software Version & Regression Lab** | `/app/dashboards#/view/xml-insight-version-regression` | SoftwareVersion × TestCase heatmaps, suite completeness, data quality flags |
| 8 | **Bench & Suite Failure Matrix** | `/app/dashboards#/view/xml-insight-bench-suite-matrix` | Aggregated Lens Data Tables (`lnsDatatable`) & sunburst per Bench × Suite |
| 9 | **TestCase & Error Matrix (Data Tables)** | `/app/dashboards#/view/xml-insight-testcase-matrix` | Aggregated `lnsDatatable` views for software regressions, error codes, retries, and message origins |
| 10 | **Campaign & Bench Health Matrix (Data Tables)** | `/app/dashboards#/view/xml-insight-campaign-matrix` | Aggregated `lnsDatatable` views for campaign runs, plan completeness, suites, and import errors |

## Recommended Analysis Path

1. Start in **Nightly Overview** or **Campaign & Bench Health Matrix** to spot missing/partial reports or bench-level anomalies.
2. Open **Bench & Suite Failure Matrix** or **TestCase & Error Matrix** to see aggregated counts by `test_bench.id` × `suite.name` × `test_case.name` × `extracted_error_codes`.
3. Copy a failing `run.id` into **Run Details** and **Test Details** (keep time range at **Last 7 days**) to inspect `init` → `suite` → `deinit` steps and exact messages in order.
