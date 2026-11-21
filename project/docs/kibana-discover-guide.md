# Kibana Dashboards & Drilldown Guide

XML Insight Lab provisions **11 Kibana dashboards** using aggregated **Lens Data Tables (`lnsDatatable`)**, **KPI Metrics (`lnsMetric`)**, **Stacked Bar & Line Charts (`lnsXY`)**, and **Donut/Sunburst Charts (`lnsPie`)** backed by **7 Data Views**. All dashboards focus strictly on **errors, test benches, suites, software versions, and root-cause analysis**.

## Provisioned Dashboards

| # | Dashboard | URL | Focus |
| --- | --- | --- | --- |
| 1 | **Nightly Overview** | `/app/dashboards#/view/xml-insight-nightly-overview` | Expected/received/missing/partial/invalid reports, bench results, `init`/`deinit` anomalies, aggregated plan, failure & import-error Lens tables |
| 2 | **Suite Overview** | `/app/dashboards#/view/xml-insight-suite-overview` | Suites per bench, regular testcase results (`phase: "suite"`), `NEW`/`RECURRING`/`FIXED` error trends, top error codes & failed suites Lens table |
| 3 | **Run Details** | `/app/dashboards#/view/xml-insight-run-details` | Report metadata (`init` / `deinit` / `Passed TCs` / `Failed TCs`), included suites, and separate `deInitialization` evaluation (`phase: "deinit"`) via `lnsDatatable` |
| 4 | **Test Details** | `/app/dashboards#/view/xml-insight-test-details` | Step results by TestCase & Step, failed steps with error mapping (`Category`, `Rule ID`), and diagnostic messages / explicit `<errors>` entries via `lnsDatatable` |
| 5 | **Bench Comparison** | `/app/dashboards#/view/xml-insight-bench-comparison` | Cross-bench × suite stacked bar breakdowns (relevant failures & total failures), donut/pie shares, and nightly failure trend by bench |
| 6 | **Error & Retry Analytics** | `/app/dashboards#/view/xml-insight-error-analytics` | Error categories, `NEW`/`RECURRING`/`FIXED` trends, message levels, horizontal error codes, retry recovery, and aggregated failure `lnsDatatable` |
| 7 | **Software Version & Regression Lab** | `/app/dashboards#/view/xml-insight-version-regression` | Version KPIs, failures by Software Version × Suite & Error Category, `Version Health Summary` & `Version x Error Rule Breakdown` Lens tables, completeness & data quality flags |
| 8 | **Bench & Suite Failure Matrix** | `/app/dashboards#/view/xml-insight-bench-suite-matrix` | Aggregated Lens Data Tables (`lnsDatatable`) & sunburst breakdown per Bench × Suite × Error Category |
| 9 | **TestCase & Error Matrix (Data Tables)** | `/app/dashboards#/view/xml-insight-testcase-matrix` | Aggregated `lnsDatatable` matrices for software regressions, error codes, retries, and message origins |
| 10 | **Campaign & Bench Health Matrix (Data Tables)** | `/app/dashboards#/view/xml-insight-campaign-matrix` | Aggregated `lnsDatatable` matrices for campaign runs, plan completeness, suites, and import errors |
| 11 | **Error Classification & Root Cause Analysis** | `/app/dashboards#/view/xml-insight-error-classification` | Config-driven error mapping categories, severities, dispositions (`RELEVANT`/`KNOWN_ISSUE`/`INVESTIGATE`/`IGNORED`), root causes, owners, and message drilldown |

## Recommended Analysis Path

1. Start in **01. Nightly Overview**, **10. Campaign & Bench Health Matrix**, or **11. Error Classification & Root Cause Analysis** to spot missing/partial reports, bench hotspots, or `RELEVANT` vs. `KNOWN_ISSUE` fault dispositions.
2. Open **08. Bench & Suite Failure Matrix**, **09. TestCase & Error Matrix**, or **07. Software Version & Regression Lab** to compare aggregated failure counts across `test_bench.id` × `suite.name` × `software.version` × `error_mapping.rule_id`.
3. Filter by a specific `run.id` or `test_case.name` in **03. Run Details** and **04. Test Details** (keep time range at **Last 7 days**) to inspect `init` → `suite` → `deinit` step outcomes and mapped error messages.
