---
title: "42. N-Grams, Part 1"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03</div>

# 42. N-Grams, Part 1

Instead of scanning the term dictionary for prefixes on every keystroke, you can precompute word prefixes **when a document is indexed** using **n-grams** and **edge n-grams**. At query time, autocomplete becomes a single, blazing-fast inverted-index lookup.

## What are `ngram` and `edge_ngram`?

An **n-gram** is a contiguous sequence of `N` characters from a token. For the word `"star"` with `min_gram: 2` and `max_gram: 3`:

| Tokenizer / Filter | Output tokens for `"star"` | Use case |
| :--- | :--- | :--- |
| `ngram` (`2`–`3`) | `st`, `ta`, `ar`, `sta`, `tar` | Substring matching anywhere in a word (e.g., product SKUs) |
| `edge_ngram` (`2`–`4`) | `st`, `sta`, `star` | Prefix / autocomplete matching from the start of each word |

For movie title autocomplete, **`edge_ngram`** is almost always what you want: it generates every prefix starting from the left edge of each word, keeping index size much smaller than full `ngram`.

## Testing an `edge_ngram` analyzer with `_analyze`

Before modifying any index, you can define a custom analyzer in a test index and inspect its output using the `_analyze` API:

```bash
curl -s -X PUT "http://127.0.0.1:9200/movies_ngram_test?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "analysis": {
        "filter": {
          "autocomplete_filter": {
            "type": "edge_ngram",
            "min_gram": 2,
            "max_gram": 10
          }
        },
        "analyzer": {
          "autocomplete_index": {
            "type": "custom",
            "tokenizer": "standard",
            "filter": [
              "lowercase",
              "autocomplete_filter"
            ]
          }
        }
      }
    }
  }'
```

Now test how `"Star Wars"` is tokenized:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies_ngram_test/_analyze?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "analyzer": "autocomplete_index",
    "text": "Star Wars"
  }'
```

Elasticsearch emits: `st`, `sta`, `star`, `wa`, `war`, `wars`.

## The subtle trap: using `edge_ngram` at query time

If you assign `autocomplete_index` as the **only** analyzer on `title`, Elasticsearch uses it both at **index time** and at **query time**. Look what happens when a user searches `"sta"`:
- Query `"sta"` is analyzed into `["st", "sta"]`.
- Because `match` defaults to `operator: "or"`, `"st"` matches `"Star Wars"`, `"Star Trek"`, `"Stand by Me"`, `"Stargate"`, and `"Stranger Things"`—polluting results with 2-letter prefix matches even though the user typed `"sta"`!

How you fix that by separating `analyzer` (index time) from `search_analyzer` (query time) is the focus of Part 2.

## Key takeaways

- `ngram` generates sliding character windows across a word; `edge_ngram` generates prefixes anchored at the start of each word.
- `edge_ngram` shifts prefix-matching work from query time to index time, trading slightly larger indices for sub-millisecond lookups.
- Never use an `edge_ngram` analyzer at query time—otherwise short n-grams from the user's input will match unrelated words.

<div class="chapter-nav">
<a class="chapter-nav__item" href="041-query-time-search-as-you-type.html"><span>Previous</span><strong>41. Query-time Search As You Type</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="043-n-grams-part-2.html"><span>Next</span><strong>43. N-Grams, Part 2</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
