---
title: "85. Kibana Management"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 06</div>

# 85. Kibana Management

Beyond search and dashboards, **Stack Management** (under **Management → Stack Management**) is the control plane for administering both Elasticsearch resources and Kibana's own configuration.

## Key areas in Stack Management

| Section | What you manage | Common operational tasks |
| :--- | :--- | :--- |
| **Data → Index Management** | Indices, Data Streams, Index Templates, Component Templates | Inspect shard health/size, freeze/delete stale indices, check template matching |
| **Data → Index Lifecycle Policies** | ILM policies (`hot`, `warm`, `cold`, `delete`) | Configure rollover thresholds (e.g., `50gb` or `30d`) and retention windows |
| **Data → Snapshot and Restore** | Snapshot repositories & SLM policies | Schedule automated backups to S3/GCS/shared FS and restore individual indices |
| **Kibana → Data Views** | Index pattern mappings, field formatters, runtime fields | Refresh field lists after mapping changes, add URL/duration formatters |
| **Kibana → Saved Objects** | Dashboards, visualizations, saved searches, Data Views | Export/import `.ndjson` bundles between staging and production |
| **Security → Users & Roles** | Native users, RBAC roles, API keys | Grant least-privilege read/write access per index and per Kibana Space |

## Index Management and Data Views

In **Index Management**, you can see every index's health (`green`, `yellow`, `red`), primary/replica shard counts, document count, and disk usage—without memorizing `_cat/indices` flags. Clicking an index reveals its **Settings**, **Mappings**, and **Stats**.

When you add new fields to an index mapping (or create a runtime field), remember that **Data Views** cache field metadata. Visit **Stack Management → Data Views** (or use the refresh button in the Data View editor) if a newly indexed field does not show up in Discover or Lens autocomplete.

## Saved Objects: exporting and promoting dashboards

Everything you build in Kibana—Data Views, Discover saved searches, Lens panels, and Dashboards—is stored as a **Saved Object** inside `.kibana_*`.

Under **Stack Management → Saved Objects**, you can:

1. Select a Dashboard and choose **Export** (check **Include related objects** so the underlying Data Views and Lens visualizations are bundled together).
2. Download the resulting `export.ndjson` file and commit it to Git.
3. Import it into another environment (staging or production) via the UI or the Saved Objects API:

   ```bash
   curl -X POST "http://127.0.0.1:5601/api/saved_objects/_import?overwrite=true" \
     -H "kbn-xsrf: true" \
     -F file=@export.ndjson
   ```

> **Tip.** Always include `kbn-xsrf: true` when calling Kibana's HTTP APIs directly; Kibana rejects state-changing requests without this header to prevent cross-site request forgery.

## Security: Roles, Users, and Spaces

Under **Security → Roles**, you define **Role-Based Access Control (RBAC)** in two layers:

- **Elasticsearch index privileges:** Which indices a role can `read`, `write`, or `manage` (for example, `movies` with `read` only, or `logs-app-*` with `read` + `view_index_metadata`).
- **Kibana feature privileges:** Which Kibana **Spaces** (isolated workspaces for different teams) and apps (Discover, Dashboards, Dev Tools, Stack Management) the role can access.

Assigning a read-only analyst role to a dedicated Space prevents accidental deletion of indices or modification of shared production dashboards.

## Key takeaways

- **Stack Management** unifies Elasticsearch administration (Index Management, ILM, Snapshots) and Kibana administration (Data Views, Saved Objects, Spaces, RBAC) in one UI.
- Use **Saved Objects** export/import (`.ndjson` with `kbn-xsrf: true`) to version-control and promote dashboards across environments.
- Always pair index-level RBAC with Kibana **Spaces** and feature privileges so users only see the data and tools they need.

<div class="chapter-nav">
<a class="chapter-nav__item" href="084-kibana-lens.html"><span>Previous</span><strong>84. Kibana Lens</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="086-elasticsearch-sql.html"><span>Next</span><strong>86. Elasticsearch SQL</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 6</a></p>
