---
title: "35. Pagination"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03</div>

# 35. Pagination

By default, Elasticsearch returns only the top **10** hits (`size: 10`, `from: 0`). Moving through pages of search results seems simple until you hit deep pagination—where naive `from`/`size` offsets can overload a distributed cluster.

## Shallow pagination with `from` and `size`

For the first few pages of a UI, pass `from` (the 0-based offset) and `size` (the number of hits per page):

```bash
# Page 3 (10 results per page -> skip first 20)
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "from": 20,
    "size": 10,
    "query": {
      "match": { "genre": "Action" }
    }
  }'
```

### Why deep `from`/`size` is expensive

Suppose your `movies` index has 5 primary shards and you request `from: 9990, size: 10`. Because each shard only knows its own local documents, the coordinating node must ask **every** shard for its top `10,000` hits (`from + size`), merge and sort `5 × 10,000 = 50,000` hits in memory, and discard the first `9,990`.

To protect clusters from out-of-memory errors, Elasticsearch enforces **`index.max_result_window`**, which defaults to **`10,000`**. Any request where `from + size > 10000` fails with a `Result window is too large` error.

## Deep pagination with `search_after`

When you need to page past 10,000 results (or build an "infinite scroll" feed), use **`search_after`** instead of `from`. Rather than counting and discarding `N` documents, `search_after` uses the sort values of the **last hit on the current page** as a cursor to jump directly to the next page.

Every `search_after` query **must** include a deterministic, unique tie-breaker in `sort` (such as `_shard_doc` or a unique `id` field):

```bash
# Step 1: Fetch the first page sorted by year desc, then id asc
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 5,
    "query": { "match_all": {} },
    "sort": [
      { "year": "desc" },
      { "id": "asc" }
    ]
  }'
```

Suppose the last hit in the response includes `"sort": [2018, 193586]`. Pass that exact array into `search_after` for the next page:

```bash
# Step 2: Fetch the next page starting after [2018, 193586]
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 5,
    "query": { "match_all": {} },
    "sort": [
      { "year": "desc" },
      { "id": "asc" }
    ],
    "search_after": [2018, 193586]
  }'
```

> **Tip.** If documents are being indexed or updated while a user paginates with `search_after`, combine it with a **Point in Time (`_pit`)** so the underlying index view stays frozen across pages.

## What about the `scroll` API?

Older tutorials often recommend the **`scroll`** API (`?scroll=1m`) for deep pagination or bulk exports. In modern Elasticsearch (8.x/9.x), `scroll` is **no longer recommended** for deep pagination because it pins old Lucene segments on disk and consumes heap for long-lived search contexts. Use `search_after` with `_pit` instead.

## Key takeaways

- `from` and `size` work well for shallow UI pages, up to `index.max_result_window` (default `10,000`).
- Deep `from` values multiply memory and CPU across every shard because `from + size` hits must be sorted on each shard.
- Use `search_after` (with a unique sort tie-breaker, and `_pit` if consistency across writes matters) for deep pagination and infinite scroll.
- Avoid `scroll` for user-facing pagination; reserve it only for legacy bulk-export tooling.

<div class="chapter-nav">
<a class="chapter-nav__item" href="034-exercise-querying-in-different-ways.html"><span>Previous</span><strong>34. [Exercise] Querying in Different Ways</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="036-sorting.html"><span>Next</span><strong>36. Sorting</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
