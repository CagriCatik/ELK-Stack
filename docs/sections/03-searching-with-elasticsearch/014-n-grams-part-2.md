---
title: "43. N-Grams, Part 2"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03</div>

# 43. N-Grams, Part 2

In Part 1, you saw that applying `edge_ngram` at query time breaks relevance by breaking the user's search input into tiny fragments. The solution is to configure **two different analyzers** on the same field:

- **`analyzer`** (index time): uses `edge_ngram` so `"Star Wars"` indexes `st`, `sta`, `star`, `wa`, `war`, `wars`.
- **`search_analyzer`** (query time): uses `standard` (lowercased, no n-grams) so a query for `"sta"` searches for the single exact token `"sta"`.

## Mapping a field with separate index and search analyzers

Add a `.autocomplete` multi-field (or dedicated field) to your index mapping so you keep standard `title` search intact while enabling instant prefix lookups:

```bash
curl -s -X PUT "http://127.0.0.1:9200/movies_autocomplete?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "settings": {
      "analysis": {
        "filter": {
          "autocomplete_filter": {
            "type": "edge_ngram",
            "min_gram": 2,
            "max_gram": 15
          }
        },
        "analyzer": {
          "autocomplete_index": {
            "type": "custom",
            "tokenizer": "standard",
            "filter": ["lowercase", "autocomplete_filter"]
          }
        }
      }
    },
    "mappings": {
      "properties": {
        "title": {
          "type": "text",
          "fields": {
            "autocomplete": {
              "type": "text",
              "analyzer": "autocomplete_index",
              "search_analyzer": "standard"
            }
          }
        },
        "genre": { "type": "keyword" },
        "year": { "type": "integer" }
      }
    }
  }'
```

Index a couple of sample movies and test it:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies_autocomplete/_doc/1?pretty" \
  -H "Content-Type: application/json" \
  -d '{ "title": "Star Wars: A New Hope", "genre": "Sci-Fi", "year": 1977 }'

curl -s -X POST "http://127.0.0.1:9200/movies_autocomplete/_doc/2?refresh=true&pretty" \
  -H "Content-Type: application/json" \
  -d '{ "title": "Stand by Me", "genre": "Drama", "year": 1986 }'
```

Now query `title.autocomplete` with `"star wa"`:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies_autocomplete/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match": {
        "title.autocomplete": {
          "query": "star wa",
          "operator": "and"
        }
      }
    }
  }'
```

- `"star wa"` is analyzed by `standard` into `["star", "wa"]`.
- `operator: "and"` requires **both** `"star"` and `"wa"` to exist in `title.autocomplete`.
- `"Star Wars: A New Hope"` matches; `"Stand by Me"` does not!

## Trade-offs to keep in mind

- **Index size:** Storing `min_gram: 2, max_gram: 15` multiplies the number of indexed terms per word, increasing disk usage and indexing CPU. Keep `max_gram` reasonable (10–15) and only apply it to short fields like `title`, never long article bodies.
- **Words longer than `max_gram`:** If a word is 20 characters long and `max_gram` is `15`, typing the 16th character won't match `title.autocomplete` unless you also query the standard `title` field in a `should` or `multi_match` clause.

> **Tip.** In Elasticsearch 7.2+, you often do not need to hand-craft `edge_ngram` analyzers at all—the built-in **`search_as_you_type`** field type automates this pattern for you, as you will see next.

## Key takeaways

- Pair an `edge_ngram` index `analyzer` with a `standard` `search_analyzer` so user input is not fragmented into short n-grams.
- Use `operator: "and"` in `match` so multi-word autocomplete queries require every typed prefix to match.
- Apply `edge_ngram` only to short, high-value fields (like `title`) to control index size.

<div class="chapter-nav">
<a class="chapter-nav__item" href="042-n-grams-part-1.html"><span>Previous</span><strong>42. N-Grams, Part 1</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="044-search-as-you-type-field-type.html"><span>Next</span><strong>44. "Search as you Type" Field Type</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
