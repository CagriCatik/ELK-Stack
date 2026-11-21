# Synthetic `<report>`XML Format (v1.0)

This document defines the binding `<report>`XML structure and its backwards-compatible optional extensions for **XML Insight Lab**.

> **Synthetic Data Notice:** All projects (`SampleProject`), benches (`lab-01`–`lab-03`), suites (`Workspace`, `Content`, `Settings`), components (`Output_A`, `Output_B`, `CaptureService`, `InteractionService`, `Connectivity`), and messages are 100% synthetic.

## Base Structure (No Extra Mandatory Attributes)

```xml
<report bench="lab-01" project="SampleProject"
 startTime="2026-11-17T01:00:00" endTime="2026-11-17T01:12:45" result="FAILED">
 <groups name="initialization">
 <group name="SystemSetup">
 <param name="SoftwareVersion" value="1.4.0"/>
 <msg level="info">Bench initialized.</msg>
 </group>
 </groups>
 <groups name="Workspace">
 <testCase name="TC_WORKSPACE_001" result="PASSED" duration="12.5">
 <step name="Open_Workspace" result="PASSED"><msg level="info">OK</msg></step>
 </testCase>
 </groups>
 <groups name="deInitialization" result="PASSED">
 <testCase name="TC_DEINIT_CLEANUP" result="PASSED" duration="4.0"/>
 </groups>
</report>
```

- **Phases:** `initialization`→ `init`; `deInitialization`→ `deinit`; any other `<groups>`containing `<testCase>`→ `suite`; any `<groups>`without `<testCase>`→ `extra_group`.
- **Duration unit assumption:** `duration`attributes are explicitly interpreted as **seconds** and normalized to integer `duration_ms`. Missing `duration`stays `null`(never invented).
- **Timezone assumption:** Timestamps without UTC offset are interpreted using `SOURCE_TIMEZONE`(default `Europe/Berlin`), normalized to UTC (`started_at`, `ended_at`), and tagged with `timezone_assumed`and `timezone_status`. Original strings are preserved in `source_start_time`/ `source_end_time`.
- **Results:** `source_result`is preserved verbatim; `normalized_result`maps missing results to `UNKNOWN`(never invented). Warnings do not force `FAILED`.
- **No pre-classified results in XML:** XML reports contain only raw test results, optional `errorCode`attributes, and original messages. Rule-based classification (`error_mapping`) is applied downstream by Logstash using [`config/error_mapping.yaml`](../config/error_mapping.yaml) (see [`docs/error-mapping.md`](error-mapping.md)).

## Backwards-Compatible Optional Extensions

The base XML imports without any additional attributes. Optional attributes/elements supported by the parser:
- `schemaVersion`, `synthetic`, `id`, `campaignId`, `executionSlotId`on `<report>`
- `id`, `version`, `duration`, `result`on `<groups>`
- `id`, `executionId`, `attempt`, `startTime`, `endTime`on `<testCase>`
- `id`, `duration`, `startTime`, `endTime`, `<assertion>`, `<artifact>`on `<step>`
- `errorCode`on `<msg>`

When stable IDs (`id`) are omitted, deterministic import IDs are derived from `file_sha256`and structural position, and `comparability_limited: true`is recorded.
