---
title: "2. Data Frame Transforms"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 2. Data Frame Transforms



Log indices are **event-centric**: every HTTP request, login attempt, or system message becomes its own document. That layout is ideal for time-series filtering and full-text search, but awkward when your question is about an **entity** over time—for example, *"Which client IPs generated more than 500 `404` responses in the last hour?"* or *"What is the current status and last-seen timestamp of every host in the fleet?"*

**Transforms** (historically called Data Frame Transforms, exposed under the `_transform` API) solve this by running scheduled aggregations or latest-value lookups against a source index and writing the results into a compact, **entity-centric** destination index.

## Pivot vs. Latest transforms

Elasticsearch supports two transform modes:

| Mode | Purpose | Typical use case |
| :--- | :--- | :--- |
| **`pivot`** | Groups documents by one or more fields (`group_by`) and computes metrics (`aggregations`) | Per-IP request counts, error rates, total bytes, or per-user session summaries |
| **`latest`** | Keeps only the most recent document per unique key (`unique_key` + `sort`) | Current state of a server, latest order status, or most recent device telemetry |

## Batch vs. Continuous transforms

- **Batch (one-shot) transforms** read all matching documents from the source index, write the destination index, and stop. Use them for historical backfills or one-off analysis.
- **Continuous transforms** stay running and periodically check for new documents using a timestamp field (`sync.time.field`, typically `@timestamp`) and a configurable `delay` (for example, `60s`) to tolerate late-arriving logs. Each run updates only the entity buckets affected since the last checkpoint.

## Example: Pivoting Nginx logs by client IP

The following `PUT _transform/nginx_ip_summary` request summarizes raw web logs into one document per `source.ip`:

```json
PUT _transform/nginx_ip_summary
{
  "source": {
    "index": ["filebeat-*"],
    "query": {
      "term": {
        "event.module": "nginx"
      }
    }
  },
  "dest": {
    "index": "nginx-ip-summary"
  },
  "frequency": "1m",
  "sync": {
    "time": {
      "field": "@timestamp",
      "delay": "60s"
    }
  },
  "pivot": {
    "group_by": {
      "client_ip": {
        "terms": {
          "field": "source.ip"
        }
      }
    },
    "aggregations": {
      "total_requests": {
        "value_count": {
          "field": "@timestamp"
        }
      },
      "error_4xx_5xx": {
        "filter": {
          "range": {
            "http.response.status_code": {
              "gte": 400
            }
          }
        }
      },
      "bytes_sent": {
        "sum": {
          "field": "http.response.body.bytes"
        }
      },
      "last_seen": {
        "max": {
          "field": "@timestamp"
        }
      }
    }
  }
}
```

### Managing the transform lifecycle

Before starting a transform in production, preview it, start it, and monitor its checkpoints:

```bash
# Preview the first page of transformed documents without writing an index
curl -k -u elastic:changeme -X POST "https://127.0.0.1:9200/_transform/_preview" \
  -H "Content-Type: application/json" \
  -d '{ ...same transform body... }'

# Start the transform
curl -k -u elastic:changeme -X POST "https://127.0.0.1:9200/_transform/nginx_ip_summary/_start"

# Check progress, checkpoint count, and any search/index errors
curl -k -u elastic:changeme "https://127.0.0.1:9200/_transform/nginx_ip_summary/_stats"

# Stop cleanly when no longer needed
curl -k -u elastic:changeme -X POST "https://127.0.0.1:9200/_transform/nginx_ip_summary/_stop"
```

Once `nginx-ip-summary` is populated, querying for abusive IPs (`error_4xx_5xx.doc_count > 100`) is a simple `range` query on a small index rather than a heavy terms aggregation across millions of raw log lines.

> **Operational caveats.** Continuous transforms use composite aggregations under the hood and page through results (`settings.max_page_search_size`, default `500`). If your `group_by` has millions of unique keys (high cardinality) and your cluster is under memory pressure, lower `max_page_search_size` or add a `date_histogram` to `group_by` so older buckets stop being updated. Also ensure `sync.time.delay` is larger than your maximum ingestion lag so late logs are not missed.

## Key takeaways

- **Transforms** convert event-centric log indices into entity-centric indices for fast entity-level queries, alerting, and machine learning.
- **`pivot`** aggregates metrics per entity key; **`latest`** retains the single most recent document per unique key.
- **Continuous transforms** use `sync.time.field` and `delay` to incrementally update only changed entities, avoiding full re-scans.
- Always `_preview` a transform and verify destination mappings before running it continuously at scale.

<div class="chapter-nav">
<a class="chapter-nav__item" href="001-section-8-intro.html"><span>Previous</span><strong>1. Section 8 Intro</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="003-filebeat-and-the-elastic-stack-architecture.html"><span>Next</span><strong>3. FileBeat and the Elastic Stack Architecture</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
