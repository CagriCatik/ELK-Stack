---
title: "108. Snapshot Lifecycle Management"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 108. Snapshot Lifecycle Management



Manual snapshots are easy to forget. **Snapshot Lifecycle Management (SLM)** is the backup counterpart to ILM: it runs scheduled snapshots automatically inside Elasticsearch and prunes expired snapshots according to your retention rules.

## Creating an SLM Policy (`_slm/policy`)

The following policy takes a nightly snapshot at **01:30 UTC** (`0 30 1 * * ?`), names each snapshot using date math (`<nightly-snap-{now/d}>`), stores it in `s3_backups`, and retains snapshots for **30 days** while always keeping at least **5** and at most **50** snapshots:

```bash
curl -X PUT "http://127.0.0.1:9200/_slm/policy/nightly-snapshots" \
  -H "Content-Type: application/json" \
  -d '{
  "schedule": "0 30 1 * * ?",
  "name": "<nightly-snap-{now/d}>",
  "repository": "s3_backups",
  "config": {
    "indices": ["movies", "logs-*"],
    "ignore_unavailable": true,
    "include_global_state": true
  },
  "retention": {
    "expire_after": "30d",
    "min_count": 5,
    "max_count": 50
  }
}'
```

| Field | Purpose |
| --- | --- |
| `schedule` | Quartz cron expression (UTC) triggering the snapshot |
| `name` | Snapshot name prefix; date math ensures unique, sortable names |
| `include_global_state` | Backs up cluster settings, index templates, ILM/SLM policies, and Kibana saved objects (`.kibana*` if included) |
| `retention` | Automated cleanup: `expire_after`, `min_count` (safety floor), and `max_count` (storage cap) |

> **Tip.** Always include `min_count` in `retention`. If a repository is unreachable or snapshots fail for 30 days, `min_count` guarantees SLM will never delete your last known good backups just because they aged past `expire_after`.

## Testing and Monitoring SLM

Never wait until 01:30 UTC to discover a permissions typo. Trigger the policy immediately and inspect its status:

```bash
# Trigger the policy on demand
curl -X POST "http://127.0.0.1:9200/_slm/policy/nightly-snapshots/_execute"

# Check execution history, failures, and retention stats
curl -s "http://127.0.0.1:9200/_slm/policy/nightly-snapshots?pretty"
curl -s "http://127.0.0.1:9200/_slm/stats?pretty"
```

You can also force retention cleanup immediately with `POST /_slm/_execute_retention`, and pair SLM with **ILM's `wait_for_snapshot`** action in the `delete` phase so ILM never deletes an index before SLM has safely backed it up.

## Key takeaways

- **SLM** (`_slm/policy`) automates scheduled snapshots and retention pruning without external cron scripts.
- Use **date math** (`<nightly-snap-{now/d}>`) for snapshot names and **`include_global_state: true`** to protect templates and cluster settings.
- Set **`min_count`** alongside `expire_after` so failed backup runs never leave you with zero snapshots.
- Test new policies immediately with `POST /_slm/policy/<id>/_execute` and monitor `GET /_slm/stats`.

<div class="chapter-nav">
<a class="chapter-nav__item" href="107-snapshots.html"><span>Previous</span><strong>107. Snapshots</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="109-rolling-restarts.html"><span>Next</span><strong>109. Rolling Restarts</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
