---
title: "5. Index Lifecycle Management"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 09</div>

# 5. Index Lifecycle Management



Calling `_rollover` via an external cron job works, but **Index Lifecycle Management (ILM)** automates the entire lifespan of an index directly inside Elasticsearch—from high-speed ingestion, through cost-optimized warm/cold storage, all the way to deletion.

## The Five ILM Phases

ILM moves an index sequentially through up to five phases based on its age (measured from creation or from rollover):

| Phase | Purpose | Typical Actions |
| --- | --- | --- |
| **Hot** | Active writes and frequent queries on fast NVMe hardware | `rollover` (`max_primary_shard_size`, `max_age`), `set_priority` |
| **Warm** | No longer written to; still queried regularly | `readonly`, `shrink`, `forcemerge` (`max_num_segments: 1`), `allocate` to warm nodes, reduce replicas |
| **Cold** | Infrequently queried; optimized for storage cost | `allocate` to cold nodes, `searchable_snapshot` (partial/full cache on object storage) |
| **Frozen** | Rarely queried archival data | `searchable_snapshot` mounted directly from S3/GCS/Azure Blob with minimal local disk |
| **Delete** | Retention expired | `delete` (optionally `wait_for_snapshot` first) |

## Creating an ILM Policy (`_ilm/policy`)

The following policy rolls over hot indices at **30 GB** or **7 days**, moves them to warm nodes after **7 days** (merging segments and shrinking to 1 shard), moves them to cold after **30 days**, and deletes them after **90 days**:

```bash
curl -X PUT "http://127.0.0.1:9200/_ilm/policy/logs-retention-90d" \
  -H "Content-Type: application/json" \
  -d '{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_primary_shard_size": "30gb",
            "max_age": "7d"
          },
          "set_priority": { "priority": 100 }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "set_priority": { "priority": 50 },
          "shrink": { "number_of_shards": 1 },
          "forcemerge": { "max_num_segments": 1 }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "set_priority": { "priority": 0 },
          "readonly": {}
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}'
```

> **Note.** `min_age` in `warm`, `cold`, `frozen`, and `delete` is measured **from the time the index rolled over** (not from index creation), which guarantees that an index stays in the warm tier for its full intended duration.

## Attaching the Policy via an Index Template

Link the ILM policy in your index template using `index.lifecycle.name`. If you use a Data Stream, you do **not** need `rollover_alias`—Elasticsearch handles it automatically:

```bash
curl -X PUT "http://127.0.0.1:9200/_index_template/logs-ilm-template" \
  -H "Content-Type: application/json" \
  -d '{
  "index_patterns": ["logs-prod-*"],
  "data_stream": {},
  "template": {
    "settings": {
      "number_of_shards": 2,
      "number_of_replicas": 1,
      "index.lifecycle.name": "logs-retention-90d"
    }
  }
}'
```

## Inspecting ILM Progress (`_ilm/explain`)

When an index is stuck in a phase (for example, `rollover` failed because `rollover_alias` is missing), `_ilm/explain` shows the exact step and error:

```bash
curl -s "http://127.0.0.1:9200/logs-prod-app/_ilm/explain?pretty"
```

```json
{
  "indices": {
    ".ds-logs-prod-app-2026.11.17-000001": {
      "index": ".ds-logs-prod-app-2026.11.17-000001",
      "managed": true,
      "policy": "logs-retention-90d",
      "phase": "hot",
      "action": "rollover",
      "step": "check-rollover-ready"
    }
  }
}
```

## Key takeaways

- **ILM** automates `rollover`, `shrink`, `forcemerge`, tier migration (`hot` → `warm` → `cold` → `frozen`), and `delete` without external scripts.
- Attach policies in an **index template** (`index.lifecycle.name`) so every newly rolled index inherits the lifecycle automatically.
- `forcemerge` and `shrink` belong in the **warm** phase on read-only indices—never run `forcemerge` on an actively written hot index.
- Use `GET /<index>/_ilm/explain` to debug stalled lifecycle transitions.

<div class="chapter-nav">
<a class="chapter-nav__item" href="004-index-alias-rotation.html"><span>Previous</span><strong>4. Index Alias Rotation</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="006-choosing-your-cluster-s-hardware.html"><span>Next</span><strong>6. Choosing your Cluster's Hardware</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 9</a></p>
