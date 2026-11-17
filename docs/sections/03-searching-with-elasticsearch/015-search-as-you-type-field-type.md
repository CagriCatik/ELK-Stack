---
title: "44. \"Search as you Type\" Field Type"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 03</div>

# 44. "Search as you Type" Field Type

Hand-rolling `edge_ngram` analyzers works well, but it requires boilerplate settings and still misses phrase-order signals unless you add extra sub-fields. Elasticsearch provides a dedicated **`search_as_you_type`** field type that sets up the right sub-fields automatically.

## What `search_as_you_type` creates under the hood

When you map a field as `"type": "search_as_you_type"`, Elasticsearch indexes the root field as `text` and automatically creates three hidden sub-fields (with `max_shingle_size` defaulting to `3`):

| Sub-field | What it indexes | Example for `"Star Wars Hope"` |
| :--- | :--- | :--- |
| `title` (root) | Standard analyzed terms | `star`, `wars`, `hope` |
| `title._2gram` | 2-word shingles | `star wars`, `wars hope` |
| `title._3gram` | 3-word shingles | `star wars hope` |
| `title._index_prefix` | `edge_ngram` prefixes of shingles | `s`, `st`, `sta`, ..., `star wars`, `star wars h`, ... |

Because `title._index_prefix` indexes prefixes of word shingles, it supports both **infix** and **prefix** autocomplete out of the box—no custom analyzer JSON required.

## Mapping and querying `search_as_you_type`

Create an index with `title` mapped as `search_as_you_type`:

```bash
curl -s -X PUT "http://127.0.0.1:9200/movies_sayt?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "mappings": {
      "properties": {
        "title": {
          "type": "search_as_you_type"
        },
        "genre": { "type": "keyword" },
        "year": { "type": "integer" }
      }
    }
  }'
```

Index a few movies:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies_sayt/_bulk?refresh=true&pretty" \
  -H "Content-Type: application/x-ndjson" \
  -d '
{ "index": { "_id": "1" } }
{ "title": "Star Wars: A New Hope", "genre": "Sci-Fi", "year": 1977 }
{ "index": { "_id": "2" } }
{ "title": "Star Trek: The Motion Picture", "genre": "Sci-Fi", "year": 1979 }
{ "index": { "_id": "3" } }
{ "title": "The Empire Strikes Back", "genre": "Sci-Fi", "year": 1980 }
'
```

Query it using **`multi_match`** with `"type": "bool_prefix"`, targeting the root field and its `_2gram` and `_3gram` sub-fields:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies_sayt/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "multi_match": {
        "query": "star wa",
        "type": "bool_prefix",
        "fields": [
          "title",
          "title._2gram",
          "title._3gram"
        ]
      }
    }
  }'
```

### How `bool_prefix` scores results

`bool_prefix` treats all words except the last as standard term queries and treats the **last word** (`"wa"`) as a prefix query against `title._index_prefix` (and the shingles). Unlike `match_phrase_prefix`, `bool_prefix` does **not** require words to be in strict order—so `"wars st"` can still match `"Star Wars"`, while `"Star Wars"` ranks highest because it also matches `title._2gram`.

## Comparing the three autocomplete approaches

| Approach | Mapping changes? | Query speed | Order flexibility | Best for |
| :--- | :--- | :--- | :--- | :--- |
| `match_phrase_prefix` | None | Slower (runtime expansion) | Strict phrase order | Prototypes, small indices |
| Custom `edge_ngram` | Custom analyzer | Very fast | Any word order | Full control over `min_gram`/`max_gram` |
| `search_as_you_type` | Single field type | Very fast | Flexible + shingle boost | Production autocomplete with minimal config |

## Key takeaways

- `search_as_you_type` automatically creates `_2gram`, `_3gram`, and `_index_prefix` sub-fields for fast index-time autocomplete.
- Query it with `multi_match` using `"type": "bool_prefix"` across `field`, `field._2gram`, and `field._3gram`.
- For most production search boxes, `search_as_you_type` gives you better relevance than raw `edge_ngram` with far less configuration.

<div class="chapter-nav">
<a class="chapter-nav__item" href="043-n-grams-part-2.html"><span>Previous</span><strong>43. N-Grams, Part 2</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="045-section-3-wrapup.html"><span>Next</span><strong>45. Section 3 Wrapup</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 3</a></p>
