---
title: "14. Data Modeling and Parent/Child Relationships, Part 2"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 14. Data Modeling and Parent/Child Relationships, Part 2

Time to set up a real parent/child mapping: a new `series` index that relates film documents to the franchise they belong to, using Star Wars as the guinea pig.

## Step 1 — Create the index with a `join` mapping

The relationship is declared in the mapping as a **`join` type field**, naming the parent and its children:

```bash
curl -XPUT '127.0.0.1:9200/series' -d '
{
  "mappings": {
    "properties": {
      "film_to_franchise": {
        "type": "join",
        "relations": { "franchise": "film" }
      }
    }
  }
}'
```

`"franchise": "film"` reads as: *franchise is the parent, film is the child*.

## Step 2 — Insert parents and children

Download the prepared bulk file and inspect it:

```bash
wget http://media.sundog-soft.com/es9/series.json
less series.json
```

It's the familiar bulk format, with two interesting details. The **franchise document** (the parent) declares its role by name:

```json
{ "create" : { "_index" : "series", "_id" : "1", "routing" : 1} }
{ "id": "1", "film_to_franchise": {"name": "franchise"}, "title" : "Star Wars" }
```

And each **film document** declares itself a child of parent ID 1:

```json
{ "create" : { "_index" : "series", "_id" : "260", "routing" : 1} }
{ "id": "260", "film_to_franchise": {"name": "film", "parent": "1"},
  "title" : "Star Wars: Episode IV - A New Hope", "year":"1977", "genre":["Action", "Adventure", "Sci-Fi"] }
```

The `"parent": "1"` field is what ties each film back to the Star Wars franchise. Import it:

```bash
/usr/bin/curl -H "Content-Type: application/x-ndjson" -XPUT '127.0.0.1:9200/_bulk?pretty' --data-binary @series.json
```

> **Note:** the `routing` value ensures parents and children land on the same shard — a requirement of the join datatype.

## Step 3 — Query the relationship in both directions

**All films belonging to a franchise** — a `has_parent` query wrapping a subquery on the parent:

```bash
curl -XGET '127.0.0.1:9200/series/_search?pretty' -d '
{
  "query": {
    "has_parent": {
      "parent_type": "franchise",
      "query": { "match": { "title": "Star Wars" } }
    }
  }
}'
```

Back come all the episodes — IV, V, VI, VII (and yes, the prequels too).

**The franchise a given film belongs to** — flip it with `has_child`:

```bash
curl -XGET '127.0.0.1:9200/series/_search?pretty' -d '
{
  "query": {
    "has_child": {
      "type": "film",
      "query": { "match": { "title": "The Force Awakens" } }
    }
  }
}'
```

Result: the *Star Wars* franchise document.

## Key takeaways

- A `join`-type field in the mapping defines parent/child relations; documents then declare their role (and children their parent) in that field.
- `has_parent` finds children by querying their parent; `has_child` finds parents by querying their children.
- Parents and children must share a shard (routing), which is why the bulk file pins routing values.
- This gives a relational, structured flavor inside a NoSQL store — against the grain of typical distributed data modeling, but there when you need it.

<div class="chapter-nav">
<a class="chapter-nav__item" href="013-data-modeling-and-parent-child-relationships-part-1.html"><span>Previous</span><strong>13. Data Modeling and Parent/Child Relationships, Part 1</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="015-flattened-datatype.html"><span>Next</span><strong>15. Flattened Datatype</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
