---
title: "7. Insert Many Movies at Once with the Bulk API"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 7. Insert Many Movies at Once with the Bulk API

Importing one document at a time is fine, but real work usually means importing an existing data set — many documents at once. That is what the **`_bulk` API** is for.

## The bulk format

A bulk request is sent to the `_bulk` endpoint, and its body pairs an **action line** with a **document line** for every document:

```json
{ "create" : { "_index" : "movies", "_id" : "135569" } }
{ "id": "135569", "title" : "Star Trek Beyond", "year":2016 , "genre":["Action", "Adventure", "Sci-Fi"] }
{ "create" : { "_index" : "movies", "_id" : "122886" } }
{ "id": "122886", "title" : "Star Wars: Episode VII - The Force Awakens", "year":2015 , "genre":["Action", "Adventure", "Fantasy", "Sci-Fi", "IMAX"] }
{ "create" : { "_index" : "movies", "_id" : "109487" } }
{ "id": "109487", "title" : "Interstellar", "year":2014 , "genre":["Sci-Fi", "IMAX"] }
{ "create" : { "_index" : "movies", "_id" : "58559" } }
{ "id": "58559", "title" : "Dark Knight, The", "year":2008 , "genre":["Action", "Crime", "Drama", "IMAX"] }
{ "create" : { "_index" : "movies", "_id" : "1924" } }
{ "id": "1924", "title" : "Plan 9 from Outer Space", "year":1959 , "genre":["Horror", "Sci-Fi"] }
```

Each `create` line names the target index and document ID; the following line is the document itself.

### Why this odd line-by-line format?

The Elasticsearch documentation itself calls it a funny format, but there's a good reason for it. Remember that **every document is hashed to a particular shard**. The node receiving a bulk request must process each document individually anyway: look at the ID, work out which shard owns it, and hand that document off to the right shard on the right node. A newline-delimited format lets the server stream through the request one document at a time and route each line where it belongs — instead of parsing one giant nested JSON structure first.

## Running the import

Download a prepared bulk file rather than typing it by hand:

```bash
wget http://media.sundog-soft.com/es9/movies.json
cat movies.json
```

Then import it. One catch: bulk data is **NDJSON** (newline-delimited JSON), so the wrapper script's `application/json` header is wrong here — this is the one case where the header must be specified explicitly, using the system curl:

```bash
/usr/bin/curl -H "Content-Type: application/x-ndjson" -XPUT '127.0.0.1:9200/_bulk?pretty' --data-binary @movies.json
```

`--data-binary @movies.json` sends the file as-is, preserving the newlines that the format depends on.

## Reading the results

The response lists a result per document — a series of `"created"` entries, and one **version-conflict error for Interstellar**. That's expected: Interstellar was already inserted in the previous chapter, and `create` refuses to overwrite an existing document. (Updating existing documents is the next chapter's topic.)

Verify everything landed with an empty search — "give me back everything":

```bash
curl -XGET '127.0.0.1:9200/movies/_search?pretty'
```

All five movies come back: *Plan 9 from Outer Space*, *The Dark Knight*, *Star Wars: Episode VII*, *Interstellar*, and *Star Trek Beyond*.

## Key takeaways

- `_bulk` indexes many documents in one request using paired action/document lines in NDJSON.
- The line-oriented format exists so the receiving node can route each document to its owning shard as it streams through the request.
- Send bulk bodies with `Content-Type: application/x-ndjson` and `--data-binary` (never `-d`, which mangles newlines).
- `create` fails with a version conflict if the ID already exists — a feature, not a bug.
- Bulk files don't have to be hand-written: scripts can generate them from source data, which is how full data sets get imported later.

<div class="chapter-nav">
<a class="chapter-nav__item" href="006-import-a-single-movie-via-json-rest.html"><span>Previous</span><strong>6. Import a Single Movie via JSON / REST</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="008-updating-data-in-elasticsearch.html"><span>Next</span><strong>8. Updating Data in Elasticsearch</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
