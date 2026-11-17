---
title: "94. [Exercise] Log analysis with Kibana"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 07 · EXERCISE</div>

# 94. [Exercise] Log analysis with Kibana



In this exercise, you will combine **KQL filtering**, a **pivot Transform**, and **Kibana** to identify client IPs generating excessive `404` and `5xx` errors against an Nginx web server.

## Your task

1. **Seed or verify sample web logs**: Ensure you have an index (`web-logs-sample`) with Nginx-style documents containing `@timestamp`, `source.ip`, `http.request.method`, `url.path`, `http.response.status_code`, and `http.response.body.bytes`. (If you don't have Filebeat running against live Nginx logs, bulk-index the sample documents provided in the walkthrough.)
2. **Filter errors with KQL**: In Kibana **Discover**, create a Data View for `web-logs-sample` and write a KQL query that isolates all `404` and `5xx` responses.
3. **Create a pivot Transform**: In Kibana **Dev Tools** (or via `curl`), create a transform named `web_ip_error_summary` that groups by `source.ip` and calculates:
   - `total_requests` (`value_count` on `@timestamp`)
   - `error_requests` (`filter` aggregation for `http.response.status_code >= 400`)
   - `bytes_sent` (`sum` on `http.response.body.bytes`)
4. **Preview, start, and query the transform**: Run `_preview` first, start the transform, and query `web-ip-error-summary` sorted by `error_requests.doc_count` descending to identify the top offending IP.
5. **Inspect in Kibana**: Filter `web-logs-sample` in Discover by the offending `source.ip` to see which paths it requested.

## Walkthrough

<details>
<summary>Show solution</summary>

### Step 1: Bulk-index sample web logs (if needed)

Run this in **Kibana Dev Tools** (or via `curl -k -u elastic:<password> -X POST "https://127.0.0.1:9200/_bulk"`):

```json
POST _bulk
{ "index": { "_index": "web-logs-sample" } }
{ "@timestamp": "2026-11-17T10:00:01Z", "source": { "ip": "203.0.113.10" }, "http": { "request": { "method": "GET" }, "response": { "status_code": 200, "body": { "bytes": 4520 } } }, "url": { "path": "/index.html" } }
{ "index": { "_index": "web-logs-sample" } }
{ "@timestamp": "2026-11-17T10:00:05Z", "source": { "ip": "198.51.100.42" }, "http": { "request": { "method": "GET" }, "response": { "status_code": 404, "body": { "bytes": 162 } } }, "url": { "path": "/wp-login.php" } }
{ "index": { "_index": "web-logs-sample" } }
{ "@timestamp": "2026-11-17T10:00:06Z", "source": { "ip": "198.51.100.42" }, "http": { "request": { "method": "GET" }, "response": { "status_code": 404, "body": { "bytes": 162 } } }, "url": { "path": "/.env" } }
{ "index": { "_index": "web-logs-sample" } }
{ "@timestamp": "2026-11-17T10:00:07Z", "source": { "ip": "198.51.100.42" }, "http": { "request": { "method": "POST" }, "response": { "status_code": 500, "body": { "bytes": 320 } } }, "url": { "path": "/api/v1/login" } }
{ "index": { "_index": "web-logs-sample" } }
{ "@timestamp": "2026-11-17T10:01:00Z", "source": { "ip": "203.0.113.10" }, "http": { "request": { "method": "GET" }, "response": { "status_code": 200, "body": { "bytes": 12800 } } }, "url": { "path": "/assets/app.js" } }
```

### Step 2: Filter errors in Discover with KQL

```text
http.response.status_code : 404 or http.response.status_code >= 500
```

### Step 3: Create and preview the pivot Transform

```json
POST _transform/_preview
{
  "source": {
    "index": ["web-logs-sample"]
  },
  "dest": {
    "index": "web-ip-error-summary"
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
      "error_requests": {
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
      }
    }
  }
}
```

Once the preview looks right, create and start the transform:

```json
PUT _transform/web_ip_error_summary
{
  "source": {
    "index": ["web-logs-sample"]
  },
  "dest": {
    "index": "web-ip-error-summary"
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
      "error_requests": {
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
      }
    }
  }
}

POST _transform/web_ip_error_summary/_start
```

### Step 4: Query the entity-centric index

```json
GET web-ip-error-summary/_search
{
  "sort": [
    { "error_requests.doc_count": { "order": "desc" } }
  ]
}
```

You will see `198.51.100.42` at the top with `total_requests: 3` and `error_requests.doc_count: 3`.

### Step 5: Inspect the offending IP in Discover

Filter `web-logs-sample` with:

```text
source.ip : "198.51.100.42"
```

This reveals the exact probed paths (`/wp-login.php`, `/.env`, `/api/v1/login`), confirming automated scanning behavior.

</details>

## Why this matters

In production, raw web log indices can hold billions of events. Running entity-level sorting or alerting directly on raw logs is expensive; pivoting into a compact entity-centric index lets you rank offending IPs in milliseconds and then pivot back to Kibana Discover for the forensic details.

<div class="chapter-nav">
<a class="chapter-nav__item" href="093-analyzing-logs-with-kibana-dashboards.html"><span>Previous</span><strong>93. Analyzing Logs with Kibana Dashboards</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="095-section-7-wrapup.html"><span>Next</span><strong>95. Section 7 Wrapup</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 7</a></p>
