---
title: "10. Insert, Update and Delete a Movie"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02 · EXERCISE</div>

# 10.  Insert, Update and Delete a Movie

Time for the first hands-on challenge of your own. You now know how to insert, update, and delete documents — so prove it before looking at the walkthrough.

## Your task

1. **Insert** a movie you make up yourself into the `movies` index — any title, genres, and release year you like. Pick a document ID that doesn't already exist.
2. **Update** it: change one field (for example the title) and confirm the change actually took.
3. **Delete** it and clean up your mess, confirming it's gone.

Try it on your own first — that's how this material sticks. The walkthrough below shows one way to do it.

## Walkthrough

<details>
<summary>Show solution</summary>

**Insert** a fictitious movie with a made-up ID (any unused number works — here, 200000):

```bash
curl -XPUT '127.0.0.1:9200/movies/_doc/200000?pretty' -d '
{
  "title": "Franks Adventures in Elasticsearch",
  "genre": ["Documentary"],
  "year": 2019
}'
```

Confirm it landed:

```bash
curl -XGET '127.0.0.1:9200/movies/_doc/200000?pretty'
```

**Update** it with a partial update — add a second genre using the `_update` endpoint and a `doc` block:

```bash
curl -XPOST '127.0.0.1:9200/movies/_update/200000?pretty' -d '
{
  "doc": {
    "genre": ["Documentary", "Comedy"]
  }
}'
```

Fetch the document again and both genres are there.

**Delete** it:

```bash
curl -XDELETE '127.0.0.1:9200/movies/_doc/200000?pretty'
```

A final GET confirms movie 200000 no longer exists.

</details>

## Why this matters

Insert, update, delete — these are the most basic operations of any data management system, and everything ahead builds on them. The easy part is now behind you; the material gets more challenging from here.

<div class="chapter-nav">
<a class="chapter-nav__item" href="009-deleting-data-in-elasticsearch.html"><span>Previous</span><strong>9. Deleting Data in Elasticsearch</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="011-dealing-with-concurrency.html"><span>Next</span><strong>11. Dealing with Concurrency</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
