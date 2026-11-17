---
title: "86. Elasticsearch SQL"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 06</div>

# 86. Elasticsearch SQL

While Elasticsearch's native Query DSL is expressive and powerful, many engineers, data analysts, and BI tools already speak SQL. **Elasticsearch SQL** lets you run `SELECT` queries directly against Elasticsearch indices—via REST (`/_sql`), Kibana Dev Tools, or JDBC/ODBC drivers—and translates them into native Query DSL and aggregations behind the scenes.

## Running SQL queries over REST

Send a `POST` request to `/_sql` with a JSON body containing `"query"`. Adding `?format=txt` renders an ASCII table that is easy to read in a terminal or Dev Tools Console:

```bash
curl -s -X POST "http://127.0.0.1:9200/_sql?format=txt" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "SELECT title, year FROM movies WHERE year >= 1995 ORDER BY year DESC LIMIT 5"
  }'
```

Supported formats include `json` (default), `txt`, `csv`, `tsv`, and `yaml`.

## Aggregations with `GROUP BY`

Elasticsearch SQL translates `GROUP BY`, `COUNT`, `AVG`, `MIN`, `MAX`, and `HAVING` directly into bucket and metric aggregations:

```json
POST _sql?format=txt
{
  "query": "SELECT genre.keyword AS genre, COUNT(*) AS total, MIN(year) AS earliest, MAX(year) AS latest FROM movies GROUP BY genre.keyword ORDER BY total DESC LIMIT 10"
}
```

> **Tip.** Just like in Lens and Query DSL, grouping on a `text` field fails unless you target its `.keyword` subfield (`genre.keyword`) or enclose it in quotes (`"genre.keyword"`).

## Inspecting the generated Query DSL with `/_sql/translate`

One of the best ways to learn complex Elasticsearch aggregations—or to debug why a SQL query behaves unexpectedly—is to ask Elasticsearch to show you the exact Query DSL it compiles using `/_sql/translate`:

```json
POST _sql/translate
{
  "query": "SELECT year, COUNT(*) AS movies_count FROM movies WHERE year >= 1990 GROUP BY year ORDER BY year ASC"
}
```

Elasticsearch returns the equivalent `_search` payload (`"size": 0`, `"query"`, and `"aggregations"`), without executing the search. You can copy that output straight into an application or optimize it further.

## Limitations of Elasticsearch SQL

Elasticsearch SQL is **read-only** (`SELECT`, `SHOW`, `DESCRIBE`)—it does not support `INSERT`, `UPDATE`, `DELETE`, or cross-index `JOIN`s, because distributed joins do not scale across sharded inverted indices.

## Looking ahead: ES|QL (Piped Query Language)

In Elasticsearch 8.11+ and 9.x, Elastic introduced **ES|QL** (`/_query`), a piped query language designed specifically for Elasticsearch's distributed architecture. Unlike SQL, ES|QL supports **inline transformations (`EVAL`)**, **`GROK`/`DISSECT` parsing**, **`ENRICH` lookups**, and **`STATS ... BY`** in a single readable pipeline—and works natively inside Kibana Discover and Lens:

```text
FROM movies
| WHERE year >= 1990
| STATS movie_count = COUNT(*) BY year
| SORT year ASC
| LIMIT 10
```

Use **Elasticsearch SQL** when integrating with existing SQL/JDBC tooling or translating familiar `SELECT ... GROUP BY` queries, and reach for **ES|QL** when you need piped analytics, field extraction, or enrichment at query time.

## Key takeaways

- `/_sql?format=txt` lets you query Elasticsearch indices with familiar `SELECT`, `WHERE`, `GROUP BY`, and `ORDER BY` syntax.
- `/_sql/translate` converts any SQL query into its equivalent Query DSL and aggregation payload without executing it.
- Elasticsearch SQL is read-only and does not support distributed `JOIN`s; for modern piped analytics and inline transformations in 8.x/9.x, use **ES|QL** (`/_query`).

<div class="chapter-nav">
<a class="chapter-nav__item" href="085-kibana-management.html"><span>Previous</span><strong>85. Kibana Management</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="087-section-6-wrapup.html"><span>Next</span><strong>87. Section 6 Wrapup</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 6</a></p>
