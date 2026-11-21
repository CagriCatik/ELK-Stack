---
title: "2. \"Query Lite\" interface"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03</div>

# 2. "Query Lite" interface

Elasticsearch offers two ways to express a search: a compact **URI search** (often called "Query Lite") that passes query parameters in the URL, and the full **JSON Query DSL** sent in the request body. URI search is great for quick ad-hoc debugging from `curl` or a browser, while Query DSL is what you use in real applications.

## Basic URI search syntax

With URI search, you pass your query expression in the `q` parameter against `/_search`:

```bash
curl -s -X GET "http://127.0.0.1:9200/movies/_search?q=title:star&pretty"
```

Under the hood, Elasticsearch parses the `q` parameter using the **query string query** syntax. You can target specific fields, combine clauses with Boolean operators (`AND`, `OR`, `NOT` — must be uppercase), and group expressions with parentheses:

```bash
# Movies with "star" in the title AND released in 1977
curl -s -X GET "http://127.0.0.1:9200/movies/_search?q=title:star+AND+year:1977&pretty"

# Movies with "star" or "trek" in the title, excluding Sci-Fi
curl -s -X GET "http://127.0.0.1:9200/movies/_search?q=title:(star+OR+trek)+AND+NOT+genre:Sci-Fi&pretty"
```

> **Note.** In `curl` URLs, spaces must be URL-encoded as `+` or `%20`. If you forget, `curl` will fail or send a malformed request.

## Useful URI parameters

You can combine `q` with other query-string parameters to control paging, sorting, and default field behavior:

| Parameter | Purpose | Example |
| :--- | :--- | :--- |
| `q` | Query string expression | `q=title:matrix` |
| `df` | Default field when no field is specified in `q` | `q=matrix&df=title` |
| `default_operator` | Default Boolean operator (`OR` or `AND`) | `q=star+wars&default_operator=AND` |
| `size` / `from` | Number of hits to return and offset | `size=5&from=10` |
| `sort` | Sort field and direction | `sort=year:desc` |

```bash
curl -s -X GET "http://127.0.0.1:9200/movies/_search?q=star+wars&df=title&default_operator=AND&sort=year:desc&size=5&pretty"
```

## Why you outgrow Query Lite quickly

URI search is convenient at the terminal, but it has sharp edges in production:

- **URL encoding & length limits** — complex nested logic quickly becomes unreadable and can hit HTTP URL length limits.
- **No filter context separation** — everything runs as a scored query string, missing out on filter caching.
- **Strict syntax errors** — an unescaped special character (like `/`, `:`, or unbalanced `(`) in user input throws a `400 Bad Request` parsing exception.
- **Limited feature set** — advanced features like `search_after`, aggregations, highlighting, and `bool` boosts are awkward or unavailable in URI syntax.

> **Tip.** Treat URI search as a diagnostic tool for quick spot-checks in `curl`. For any application code or reusable search logic, use the JSON Query DSL covered in the next chapter.

## Key takeaways

- URI search (`?q=...`) is a concise shorthand backed by Elasticsearch's query string parser.
- Boolean operators (`AND`, `OR`, `NOT`) in `q` are case-sensitive and must be uppercase.
- Use `df`, `default_operator`, `size`, `from`, and `sort` to refine URI searches.
- Avoid exposing raw `?q=` syntax to end users; prefer JSON Query DSL for safety, readability, and full feature support.

<div class="chapter-nav">
<a class="chapter-nav__item" href="001-intro.html"><span>Previous</span><strong>1. Section 3 Intro</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="003-json-search-in-depth.html"><span>Next</span><strong>3. JSON Search In-Depth</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
