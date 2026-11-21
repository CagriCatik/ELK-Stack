---
title: "11. Partial Matching"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03</div>

# 11. Partial Matching

Sometimes you need to match part of a word—either the beginning (`"star"` matching `"stargate"` and `"starship"`), a glob pattern, or a regular expression. Elasticsearch provides term-level partial-matching queries for this, though they come with important performance caveats.

## `prefix` query

The `prefix` query matches documents whose indexed term starts with a given string:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "prefix": {
        "title": {
          "value": "inter"
        }
      }
    }
  }'
```

Because `prefix` is a **term-level** query, it is not analyzed. Against `title` (analyzed `text`), `"inter"` matches `"interstellar"`, `"interview"`, etc. Against `title.keyword`, `"inter"` would match nothing because the stored keyword starts with an uppercase `"I"` (`"Interstellar"`).

## `wildcard` and `regexp` queries

When you need arbitrary patterns inside a token, Elasticsearch supports `wildcard` (`*` for zero or more characters, `?` for a single character) and `regexp`:

```bash
# Wildcard: titles containing a token starting with "star" and ending with "s"
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "wildcard": {
        "title": {
          "value": "star*s"
        }
      }
    }
  }'

# Regexp: titles with a 4-digit year-like token starting with 199
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "regexp": {
        "title": "199[0-9]"
      }
    }
  }'
```

> **Warning.** Leading wildcards (`"*wars"`, `"?at"`) and broad `regexp` patterns force Elasticsearch to scan the **entire** term dictionary for that field on every shard. On large indices, they can spike CPU and latency. In fact, `search.allow_expensive_queries: false` blocks `wildcard` and `regexp` queries by default in hardened clusters.

## `match_phrase_prefix` for multi-word prefixes

If a user types `"star w"`, a single-term `prefix` query cannot span two words. **`match_phrase_prefix`** treats all words except the last as an exact `match_phrase`, and treats the last word as a prefix:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match_phrase_prefix": {
        "title": {
          "query": "star w",
          "max_expansions": 50
        }
      }
    }
  }'
```

This matches `"Star Wars"`, `"Star Wreck"`, and `"Star Watcher"`, while capping prefix expansion to `max_expansions` terms per shard.

## Key takeaways

- `prefix`, `wildcard`, and `regexp` are unanalyzed term-level queries; match their casing to the target field (`text` vs. `keyword`).
- Avoid leading wildcards (`*foo`) on large datasets because they scan the entire term dictionary.
- Use `match_phrase_prefix` when you need multi-word prefix matching at query time without changing index mappings.

<div class="chapter-nav">
<a class="chapter-nav__item" href="010-fuzzy-queries.html"><span>Previous</span><strong>10. Fuzzy Queries</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="012-query-time-search-as-you-type.html"><span>Next</span><strong>12. Query-time Search As You Type</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
