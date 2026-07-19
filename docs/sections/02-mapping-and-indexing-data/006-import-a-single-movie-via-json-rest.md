---
title: "6. Import a Single Movie via JSON / REST"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 6. Import a Single Movie via JSON / REST

Time to put a mapping in place and index a first real document: *Interstellar*, using its actual MovieLens movie ID. Remember, `curl` is used here for illustration — in the real world you would be issuing these same REST requests over HTTP from an application, against your cluster's real endpoint instead of `127.0.0.1:9200`.

## Setup: a curl wrapper that saves typing

Every request with a body needs the `Content-Type: application/json` header. Rather than typing it every time, create a small wrapper script that adds it automatically. SSH into the VM, then:

```bash
mkdir ~/bin
cd ~/bin
nano curl
```

Enter this two-line script:

```bash
#!/bin/bash
/usr/bin/curl -H "Content-Type: application/json" "$@"
```

Save (++ctrl+o++, Enter) and exit (++ctrl+x++), then make it executable and activate it:

```bash
chmod a+x curl
cd ~
source .profile
which curl        # → /home/student/bin/curl
```

Your `~/.profile` puts `~/bin` at the front of `PATH`, so this wrapper now takes precedence over the system curl — every `curl` command below sends the JSON header automatically, and this survives reboots.

## Step 1 — Create the index with a mapping

Tell Elasticsearch that `year` is a date, not just a number:

```bash
curl -XPUT 127.0.0.1:9200/movies -d '
{
  "mappings": {
    "properties": {
      "year": { "type": "date" }
    }
  }
}'
```

The response `{"acknowledged":true,...}` confirms it. Verify the mapping took:

```bash
curl -XGET 127.0.0.1:9200/movies/_mapping
```

## Step 2 — Index the document

```bash
curl -XPUT '127.0.0.1:9200/movies/_doc/109487?pretty' -d '
{
  "genre": ["IMAX", "Sci-Fi"],
  "title": "Interstellar",
  "year": 2014
}'
```

Reading the pieces:

- `PUT` vs `POST`: both are legal, but since we specify the document ID ourselves (109487 — Interstellar's MovieLens ID) instead of asking Elasticsearch to generate one, `PUT` is the better choice.
- `_doc` is a holdover from the older API — a named *type* used to sit in that URL position, but mapping types no longer exist.
- `?pretty` formats the response for human eyes.
- `genre` is a JSON list: comma-separated quoted strings in square brackets.
- Thanks to the mapping, `2014` is stored as a date, not a bare number.

A successful response reports `"result" : "created"` with one successful shard.

## Step 3 — Search it back

Ask for everything in the index:

```bash
curl -XGET '127.0.0.1:9200/movies/_search?pretty'
```

The result comes back with one hit — ID 109487, genres IMAX and Sci-Fi, title *Interstellar*, year 2014. That's a working Elasticsearch index with a mapping and a document in it: you are actually using Elasticsearch now.

## Key takeaways

- A wrapper script in `~/bin` can inject the mandatory `Content-Type` header into every curl call.
- Create the index and its mapping *before* indexing documents that need explicit typing (like dates).
- Use `PUT` with an explicit document ID; `_doc` is the fixed endpoint where legacy types used to go.
- `GET /index/_mapping` and `GET /index/_search?pretty` are your quickest verification tools.

<div class="chapter-nav">
<a class="chapter-nav__item" href="005-a-note-on-entering-curl-commands.html"><span>Previous</span><strong>5. A Note on Entering curl Commands</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="007-insert-many-movies-at-once-with-the-bulk-api.html"><span>Next</span><strong>7. Insert Many Movies at Once with the Bulk API</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
