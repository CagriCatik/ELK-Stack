---
title: "59. Workaround if the Grok Debugger app in the next lecture is down..."
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04 · NOTE</div>

# 59. Workaround if the Grok Debugger app in the next lecture is down...



Writing Grok expressions from scratch against raw log lines is an iterative process. Historically, many tutorials pointed to third-party web apps (such as `grokdebug.herokuapp.com`) to test patterns interactively. Those public apps occasionally go offline, lag behind Elastic's built-in pattern library, or shouldn't be used with sensitive production logs anyway.

You have three reliable, built-in alternatives that run directly inside your own Elastic Stack environment.

## Option 1: Kibana Dev Tools Grok Debugger

Kibana ships with an interactive **Grok Debugger** UI that uses the exact same Oniguruma regex engine and built-in pattern library as Elasticsearch and Logstash.

1. Open Kibana (`http://localhost:5601`).
2. Navigate to **Management → Dev Tools → Grok Debugger** (in the left sidebar under **Dev Tools**).
3. Paste a representative log line into **Sample Data**.
4. Enter your Grok expression in **Grok Pattern** (for example, `%{COMBINEDAPACHELOG}`).
5. Optionally expand **Custom Patterns** to define project-specific patterns (one per line, `NAME REGEX`).
6. Click **Simulate** to inspect the structured JSON output immediately.

> **Tip.** Because Kibana's Grok Debugger runs against your own Elasticsearch cluster, your sample logs never leave your network.

## Option 2: Elasticsearch `_ingest/pipeline/_simulate` API

If Kibana isn't running—or if you prefer working from the terminal or version-controlling your tests—you can test any Grok pattern directly against Elasticsearch's Ingest Node simulation endpoint:

```bash
curl -s -X POST "http://127.0.0.1:9200/_ingest/pipeline/_simulate" \
  -H "Content-Type: application/json" \
  -d '{
  "pipeline": {
    "processors": [
      {
        "grok": {
          "field": "message",
          "patterns": [
            "%{IPORHOST:clientip} %{USER:ident} %{USER:auth} \\[%{HTTPDATE:timestamp}\\] \"%{WORD:verb} %{DATA:request} HTTP/%{NUMBER:httpversion}\" %{NUMBER:response:int} (?:%{NUMBER:bytes:int}|-)"
          ],
          "pattern_definitions": {
            "CUSTOM_ID": "[A-Z]{2}-[0-9]{6}"
          }
        }
      }
    ]
  },
  "docs": [
    {
      "_source": {
        "message": "127.0.0.1 - frank [10/Oct/2025:13:55:36 -0700] \"GET /apache_pb.gif HTTP/1.0\" 200 2326"
      }
    }
  ]
}' | jq .
```

The response returns the parsed `doc._source` fields—or an explicit error message if the pattern fails to match—without creating any index or writing any data.

## Option 3: Local Logstash Dry-Run

When you want to test Logstash-specific filter chains (`grok` followed by `date`, `mutate`, or `geoip`), run Logstash with `stdin` input and `rubydebug` output:

```bash
bin/logstash -e '
  input { stdin {} }
  filter {
    grok {
      match => { "message" => "%{COMBINEDAPACHELOG}" }
    }
  }
  output { stdout { codec => rubydebug } }
'
```

Paste a sample log line into your terminal and press Enter. Logstash prints the full parsed event, including any `_grokparsefailure` tag if the pattern did not match.

## Key takeaways

- You never need an external website to debug Grok patterns; **Kibana Dev Tools → Grok Debugger** is built in and keeps sample logs private.
- `POST /_ingest/pipeline/_simulate` lets you test Grok patterns and custom `pattern_definitions` headlessly via `curl` without indexing documents.
- A local `stdin` → `rubydebug` Logstash command verifies both Grok matching and downstream Logstash filters (`date`, `mutate`, `geoip`) together.

<div class="chapter-nav">
<a class="chapter-nav__item" href="058-parsing-and-filtering-logstash-with-grok.html"><span>Previous</span><strong>58. Parsing and Filtering Logstash with Grok</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="060-logstash-grok-examples-for-common-log-formats.html"><span>Next</span><strong>60. Logstash Grok Examples for Common Log Formats</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
