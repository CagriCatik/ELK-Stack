---
title: "7. Nested Aggregations, Part 2"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 06</div>

# 7. Nested Aggregations, Part 2



"Nested aggregations" in Elasticsearch can mean two different things: **sub-aggregations** (Part 1) and aggregating over **`nested` field types** (this chapter). When your documents contain arrays of objects, standard `terms` or `avg` aggregations will silently produce wrong results unless the field is mapped as `nested`.

## Why arrays of objects break standard aggregations

By default, Lucene flattens arrays of JSON objects into parallel arrays of values. Consider a `movies` document with a `cast` array:

```json
{
  "title": "Toy Story",
  "year": 1995,
  "cast": [
    { "actor": "Tom Hanks", "salary_m": 15 },
    { "actor": "Tim Allen", "salary_m": 5 }
  ]
}
```

Internally, Elasticsearch stores this as:
- `cast.actor`: `["Tom Hanks", "Tim Allen"]`
- `cast.salary_m`: `[15, 5]`

The link between `"Tom Hanks"` and `15` is lost. If you run a `terms` aggregation on `cast.actor.keyword` with a sub-aggregation `avg` on `cast.salary_m`, `"Tim Allen"` will also be credited with `15`—corrupting the average.

## Mapping and indexing a `nested` field

To preserve object boundaries, declare `"type": "nested"` in the index mapping. Elasticsearch then indexes each object in the array as a hidden, separate Lucene document:

```bash
curl -s -X PUT "http://127.0.0.1:9200/movies_nested" \
  -H "Content-Type: application/json" -d '
{
  "mappings": {
    "properties": {
      "title": { "type": "text" },
      "year": { "type": "integer" },
      "cast": {
        "type": "nested",
        "properties": {
          "actor": { "type": "keyword" },
          "salary_m": { "type": "float" }
        }
      }
    }
  }
}'
```

## Aggregating with the `nested` aggregation

To aggregate fields inside `cast`, you must first enter the nested context with a **`nested`** bucket aggregation specifying `"path": "cast"`:

```bash
curl -s -X GET "http://127.0.0.1:9200/movies_nested/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "aggs": {
    "cast_members": {
      "nested": { "path": "cast" },
      "aggs": {
        "by_actor": {
          "terms": { "field": "cast.actor", "size": 10 },
          "aggs": {
            "avg_salary": {
              "avg": { "field": "cast.salary_m" }
            }
          }
        }
      }
    }
  }
}'
```

Now `"Tom Hanks"` only averages `15`, and `"Tim Allen"` only averages `5`.

## Stepping back up with `reverse_nested`

Once you are inside a `nested` aggregation, you cannot directly access root-level fields like `year`—unless you use **`reverse_nested`** to jump back up to the parent document context:

```bash
curl -s -X GET "http://127.0.0.1:9200/movies_nested/_search" \
  -H "Content-Type: application/json" -d '
{
  "size": 0,
  "aggs": {
    "cast_members": {
      "nested": { "path": "cast" },
      "aggs": {
        "by_actor": {
          "terms": { "field": "cast.actor", "size": 10 },
          "aggs": {
            "parent_movies": {
              "reverse_nested": {},
              "aggs": {
                "avg_movie_year": {
                  "avg": { "field": "year" }
                }
              }
            }
          }
        }
      }
    }
  }
}'
```

> **Performance note.** Because each `nested` array element is indexed as a separate hidden document, updating a single parent document reindexes all of its nested children, and `nested` queries/aggregations are more expensive than flat fields. Keep `nested` arrays reasonably sized (Elasticsearch caps `index.mapping.nested_fields.limit` at `50` and `index.mapping.nested_objects.limit` at `10000` by default).

## Key takeaways

- Standard object arrays flatten fields and lose per-element correlation in aggregations.
- Map arrays of objects as `"type": "nested"` when you need accurate per-object filtering or aggregation.
- Wrap sub-aggregations in `"nested": { "path": "..." }` to enter the nested context, and use `"reverse_nested": {}` to step back up to parent fields.

<div class="chapter-nav">
<a class="chapter-nav__item" href="006-nested-aggregations-part-1.html"><span>Previous</span><strong>6. Nested Aggregations, Part 1</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="008-section-6-wrapup.html"><span>Next</span><strong>8. Section 6 Wrapup</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 6</a></p>
