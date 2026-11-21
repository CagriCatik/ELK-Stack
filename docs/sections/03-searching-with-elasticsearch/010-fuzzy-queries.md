---
title: "10. Fuzzy Queries"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03</div>

# 10. Fuzzy Queries

Users make typos. Searching for `"interstelar"` or `"matrx"` with a standard `match` query returns zero hits because those exact tokens do not exist in the inverted index. **Fuzzy queries** solve this by matching terms within a small **Damerau–Levenshtein edit distance** (single-character insertions, deletions, substitutions, or adjacent transpositions).

## Using `fuzziness` in a `match` query

The easiest way to enable typo tolerance is adding `"fuzziness": "AUTO"` to a `match` query:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match": {
        "title": {
          "query": "interstelar",
          "fuzziness": "AUTO"
        }
      }
    }
  }'
```

### How `AUTO` chooses edit distance

Rather than using a fixed edit distance for every word length, `AUTO` scales with the length of the search term:

| Term length | Allowed edit distance |
| :--- | :--- |
| 1–2 characters | `0` (exact match only) |
| 3–5 characters | `1` edit |
| 6+ characters | `2` edits |

You can also set `fuzziness` explicitly to `0`, `1`, or `2`. Avoid setting `2` on short words—at edit distance 2, `"cat"` matches `"dog"`? No, 3 edits, but `"car"` matches `"bar"`, `"far"`, `"cat"`, `"ear"`, `"jar"`, `"tar"`, `"bat"`, flooding your results with noise.

## Controlling cost with `prefix_length` and `max_expansions`

Fuzzy matching is more expensive than exact lookup because Elasticsearch must scan the term dictionary (FST) for candidate terms within the edit distance. Two parameters keep this bounded:

- **`prefix_length`** (default `0`) — number of leading characters that **must** match exactly before fuzzy edits are considered. Setting `prefix_length: 1` (since typos rarely happen on the very first letter) dramatically shrinks the search space.
- **`max_expansions`** (default `50`) — maximum number of term variations a fuzzy query expands to per shard.

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "fuzzy": {
        "title": {
          "value": "matrx",
          "fuzziness": "AUTO",
          "prefix_length": 1,
          "max_expansions": 50
        }
      }
    }
  }'
```

> **Note.** Unlike `match`, the standalone `fuzzy` query is a term-level query and is **not** analyzed. Prefer `match` with `"fuzziness": "AUTO"` for multi-word or mixed-case user input.

## Key takeaways

- Fuzzy matching uses Damerau–Levenshtein edit distance to tolerate insertions, deletions, substitutions, and transpositions.
- `fuzziness: "AUTO"` scales edit distance safely by term length (0, 1, or 2 edits).
- Use `prefix_length: 1` and `max_expansions` to keep term-dictionary expansion fast and relevant.
- Prefer `match` with `fuzziness` over raw `fuzzy` queries for analyzed `text` fields.

<div class="chapter-nav">
<a class="chapter-nav__item" href="009-exercise-using-filters.html"><span>Previous</span><strong>9. [Exercise] Using Filters</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="011-partial-matching.html"><span>Next</span><strong>11. Partial Matching</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
