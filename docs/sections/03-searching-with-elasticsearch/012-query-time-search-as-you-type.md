---
title: "41. Query-time Search As You Type"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03</div>

# 41. Query-time Search As You Type

Every modern search bar shows suggestions as the user types each keystroke: `"s"` → `"st"` → `"sta"` → `"star"` → `"star w"` → `"star wa"`. You can implement this **purely at query time** (without reindexing) using `match_phrase_prefix`, or you can precompute prefixes at **index time** (covered in the next three chapters).

## Implementing query-time autocomplete with `match_phrase_prefix`

Suppose a user has typed `"the mat"` into a movie search box. Sending a `match_phrase_prefix` query on `title` immediately returns `"The Matrix"`, `"The Matchmaker"`, and `"The Matador"`:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 5,
    "query": {
      "match_phrase_prefix": {
        "title": {
          "query": "the mat",
          "max_expansions": 20
        }
      }
    }
  }'
```

### How it works under the hood

1. `"the mat"` is analyzed into `["the", "mat"]`.
2. `"the"` must match at position `N`.
3. `"mat"` is expanded against the inverted index's term dictionary into up to `max_expansions` terms starting with `"mat"` (e.g., `"matador"`, `"match"`, `"matrix"`) at position `N + 1`.

## Limitations of the query-time approach

While `match_phrase_prefix` requires zero mapping changes, it has three notable drawbacks at scale:

1. **`max_expansions` is arbitrary and per-shard.** If the user types a short prefix like `"the a"` and `max_expansions` is `20`, Elasticsearch takes the **first 20** matching terms in lexicographical order (`"a"`, `"aardvark"`, `"abandoned"`, ...) and stops—so `"The Avengers"` might be missed completely!
2. **Latency scales with keystrokes.** Every keystroke triggers a term-dictionary scan and multi-term phrase query across every shard.
3. **Strict word order.** Typing `"matrix the"` will not match `"The Matrix"` because `match_phrase_prefix` enforces phrase order.

> **Tip.** Query-time `match_phrase_prefix` is a great quick win for small-to-medium indices or prototypes, especially if you debounce requests in the UI (e.g., wait 150 ms or require at least 3 characters). For high-traffic, low-latency autocomplete, move the work to **index time** with `edge_ngram` or the `search_as_you_type` field type.

## Key takeaways

- `match_phrase_prefix` lets you build search-as-you-type without modifying your index mappings.
- `max_expansions` caps how many prefix completions are checked per shard, which can cause surprising misses on short prefixes.
- Query-time prefix expansion trades index simplicity for higher query CPU and latency under heavy autocomplete traffic.

<div class="chapter-nav">
<a class="chapter-nav__item" href="040-partial-matching.html"><span>Previous</span><strong>40. Partial Matching</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="042-n-grams-part-1.html"><span>Next</span><strong>42. N-Grams, Part 1</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
