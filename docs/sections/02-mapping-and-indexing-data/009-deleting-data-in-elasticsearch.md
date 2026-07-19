---
title: "9. Deleting Data in Elasticsearch"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 9. Deleting Data in Elasticsearch

Insert and update are covered — for completeness, deletion. It could not be easier: HTTP has a `DELETE` verb, and that is the whole story.

```bash
curl -XDELETE '127.0.0.1:9200/movies/_doc/58559?pretty'
```

## The realistic two-step flow

In practice you usually don't know a document's ID off the top of your head, so deletion tends to be a two-step operation: **find the ID, then delete it**. Say *The Dark Knight* has to go. First find it with a quick query-string search:

```bash
curl -XGET '127.0.0.1:9200/movies/_search?q=dark'
```

The results show *The Dark Knight* is document ID **58559**. With the ID in hand:

```bash
curl -XDELETE '127.0.0.1:9200/movies/_doc/58559?pretty'
```

The response reports `"result" : "deleted"`. Searching for it again returns no hits — it's gone.

## Key takeaways

- Deleting a document is a single `DELETE` request to `/index/_doc/id`.
- The common pattern is search-then-delete: find the ID with a query, then issue the delete.
- `?q=term` is a handy quick-and-dirty query-string search for exactly this kind of lookup (much more on search syntax in Section 3).

<div class="chapter-nav">
<a class="chapter-nav__item" href="008-updating-data-in-elasticsearch.html"><span>Previous</span><strong>8. Updating Data in Elasticsearch</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="010-exercise-insert-update-and-delete-a-movie.html"><span>Next</span><strong>10. Insert, Update and Delete a Movie</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
