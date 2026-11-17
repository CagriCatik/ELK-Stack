---
title: "82. Playing with Kibana"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 06</div>

# 82. Playing with Kibana

Once Kibana is running at `http://127.0.0.1:5601`, three core areas cover 90% of day-to-day work: **Data Views**, **Discover** (with KQL), and **Dev Tools Console**.

## 1. Data Views (formerly Index Patterns)

Before Discover or Lens can read an index, Kibana needs a **Data View** (renamed from *Index Pattern* in 8.x). A Data View tells Kibana:

- Which index or wildcard pattern to query (e.g., `movies`, `logs-*`, or `metrics-*`).
- Which field—if any—acts as the primary `@timestamp` field for the global time picker.

Create one in **Stack Management → Data Views → Create data view** (or directly from the prompt when opening **Discover**). For the `movies` index, set:

- **Name:** `movies`
- **Index pattern:** `movies`
- **Timestamp field:** *I don't want to use the time filter* (since `movies` has `year` as an integer rather than a date timestamp).

> **Why Data Views exist.** A Data View also caches field mappings and lets you attach runtime fields or custom URL/number formatters without modifying the underlying Elasticsearch index mapping.

## 2. Discover and KQL (Kibana Query Language)

**Discover** is the document-level search and inspection view. You can pick columns to display, expand individual JSON documents, view field value distributions in the left sidebar, and filter results using **KQL**.

KQL is a clean, autocomplete-friendly query syntax designed for human analysts (it is *not* full Query DSL, though Kibana translates KQL into Query DSL behind the scenes):

| Goal | KQL Expression |
| :--- | :--- |
| Exact or full-text match on a field | `title: "Star Wars"` |
| Boolean combination | `genre: Sci-Fi and year >= 1990` |
| Negation | `not genre: Horror` |
| Range query | `year >= 1980 and year < 1990` |
| Wildcard match | `title: Star*` |
| Field existence check | `director: *` |
| Grouping with parentheses | `(genre: Action or genre: Adventure) and year >= 2000` |

> **KQL vs. Lucene syntax.** In the Discover search bar, KQL is the default. You can switch to legacy Lucene syntax from the `KQL` toggle inside the search bar if you need regular expressions (`/pattern/`) or fuzzy syntax (`~`), though KQL handles almost all interactive filtering more safely.

## 3. Dev Tools Console

**Management → Dev Tools → Console** gives you an interactive HTTP client inside Kibana with:

- Syntax highlighting and JSON auto-formatting.
- Context-aware autocomplete for Elasticsearch endpoints, query clauses, and field names.
- Automatic authentication using your logged-in Kibana session (no need to paste `curl -u ... --cacert ...` every time).
- A **"Copy as cURL"** action in the wrench menu when you need to export a working request to a shell script.

For example, in Console you can type:

```json
GET movies/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "genre": "Sci-Fi" } }
      ],
      "filter": [
        { "range": { "year": { "gte": 1990 } } }
      ]
    }
  }
}
```

Press `Cmd+Enter` (macOS) or `Ctrl+Enter` (Linux/Windows) to execute the request and inspect the JSON response side-by-side.

## Key takeaways

- A **Data View** maps one or more Elasticsearch indices (and an optional timestamp field) into Kibana's Discover and Lens UIs.
- **Discover** pairs a document table and field-level statistics with **KQL**, an intuitive filter language that supports boolean operators, ranges, wildcards, and existence checks.
- **Dev Tools Console** is the fastest way to prototype Query DSL, mappings, and aggregations against a secured cluster.

<div class="chapter-nav">
<a class="chapter-nav__item" href="081-installing-kibana.html"><span>Previous</span><strong>81. Installing Kibana</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="083-exercise-exploring-data-with-kibana.html"><span>Next</span><strong>83. [Exercise] Exploring Data with Kibana</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 6</a></p>
