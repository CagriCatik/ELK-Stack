---
title: "4. Phrase Matching"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03</div>

# 4. Phrase Matching

A standard `match` query with `operator: "and"` checks that all words appear somewhere in the field, regardless of order or distance. Searching for `"star wars"` would match `"Wars of the Star"` just as easily as `"Star Wars"`. When word order and adjacency matter, use **`match_phrase`**.

## How `match_phrase` works

During indexing, Elasticsearch stores not only each token in the inverted index, but also its **position** in the field:

- `"Star Wars: A New Hope"` → `star` (pos 0), `wars` (pos 1), `a` (pos 2), `new` (pos 3), `hope` (pos 4)

A `match_phrase` query requires:
1. All analyzed terms appear in the field.
2. They appear in the **exact same order** and at **consecutive positions** (unless `slop` is specified).

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match_phrase": {
        "title": "star wars"
      }
    }
  }'
```

This matches `"Star Wars: Episode IV - A New Hope"`, but **not** `"The Star of Wars"` because `"of"` sits between `"star"` and `"wars"`.

## Allowing gaps and transposition with `slop`

Exact adjacency is often too strict. What if a user searches `"star hope"` for `"Star Wars: A New Hope"`, or `"new hope"` with an extra word in between? The **`slop`** parameter specifies how many token-position moves are allowed to align the query terms with the document:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match_phrase": {
        "title": {
          "query": "star hope",
          "slop": 3
        }
      }
    }
  }'
```

Here, `"star"` is at position 0 and `"hope"` is at position 4. Moving `"star"` forward by 3 positions (0 → 1 → 2 → 3) puts it right before `"hope"` (pos 4), so `slop: 3` matches.

> **Note.** `slop` can also match words in **reverse order**, though reversing two adjacent words costs `slop: 2` (one move to overlap, one move to pass). Moreover, closer matches still receive a higher `_score` than looser matches, so exact phrases naturally rank at the top.

## Boosting exact phrases inside a `bool` query

A common search pattern combines a broad `match` in `must` (for recall) with a `match_phrase` in `should` (for precision):

```bash
curl -s -X POST "http://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "bool": {
        "must": [
          { "match": { "title": "star wars" } }
        ],
        "should": [
          {
            "match_phrase": {
              "title": {
                "query": "star wars",
                "slop": 1,
                "boost": 3
              }
            }
          }
        ]
      }
    }
  }'
```

Documents containing `"star"` or `"wars"` are still returned, but documents containing the phrase `"star wars"` get a substantial score boost.

## Key takeaways

- `match_phrase` uses token positions recorded at index time to match words in order and next to each other.
- `slop` relaxes positional strictness by allowing a bounded number of intervening or transposed tokens.
- Pairing `match` in `must` with `match_phrase` in `should` gives you both high recall and strong phrase-level ranking.

<div class="chapter-nav">
<a class="chapter-nav__item" href="003-json-search-in-depth.html"><span>Previous</span><strong>3. JSON Search In-Depth</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="005-exercise-querying-in-different-ways.html"><span>Next</span><strong>5. [Exercise] Querying in Different Ways</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
