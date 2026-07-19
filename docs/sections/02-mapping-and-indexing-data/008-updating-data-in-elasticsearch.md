---
title: "8. Updating Data in Elasticsearch"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 8. Updating Data in Elasticsearch

The bulk import hit a version conflict when it tried to insert Interstellar a second time. So how do you *change* a document that has already been indexed?

## Documents are immutable — versions are the workaround

In Elasticsearch, **documents cannot be changed once written**. Instead, every document carries an automatically maintained `_version` field, and an "update" really means:

1. A **new copy** of the document is written with an incremented `_version`.
2. The old copy is **marked for deletion**.
3. Elasticsearch reclaims the space in a later cleanup pass, whenever it sees fit.

What matters is that document ID + version together are unique; Elasticsearch always serves the most recent version.

## Full update: PUT the whole document again

Re-indexing a document at an existing ID, specifying every field, is treated as an update:

```bash
curl -XPUT '127.0.0.1:9200/movies/_doc/109487?pretty' -d '
{
  "genres": ["IMAX", "Sci-Fi"],
  "title": "Interstellar Foo",
  "year": 2014
}'
```

The response reports `"result" : "updated"` and `"_version" : 2` — version 1 (with the original title) is now marked for deletion. Confirm with a direct document GET:

```bash
curl -XGET '127.0.0.1:9200/movies/_doc/109487?pretty'
```

## Partial update: POST to `_update`

To change only some fields and carry everything else over from the current version, use the `_update` endpoint with a `doc` block:

```bash
curl -XPOST '127.0.0.1:9200/movies/_update/109487?pretty' -d '
{
  "doc": {
    "title": "Interstellar"
  }
}'
```

Only `title` is replaced; all other fields are copied from the previous version into a new document — now `_version` 3. Versions 1 and 2 are both awaiting cleanup, but every read from now on returns version 3.

## Key takeaways

- Documents are immutable; updates create a new versioned copy and mark the old one for deletion.
- A `PUT` to an existing ID with the full document = full update.
- A `POST` to `/index/_update/id` with a `doc` block = partial update of just the listed fields.
- `_version` increments on every update — a fact that becomes important for concurrency control shortly.

<div class="chapter-nav">
<a class="chapter-nav__item" href="007-insert-many-movies-at-once-with-the-bulk-api.html"><span>Previous</span><strong>7. Insert Many Movies at Once with the Bulk API</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="009-deleting-data-in-elasticsearch.html"><span>Next</span><strong>9. Deleting Data in Elasticsearch</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
