---
title: "47. Importing Data with a Script"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 47. Importing Data with a Script

When you need to load a dataset once—such as seeding a `movies` catalog from a CSV export or migrating records from a legacy API—writing a short script that emits Newline-Delimited JSON (NDJSON) for Elasticsearch's `_bulk` API is often the fastest path from raw file to searchable index.

## Why `_bulk` instead of per-document `PUT`

Sending one HTTP request per document incurs a TCP/TLS round-trip, request parsing, and cluster coordination overhead on every single record. Indexing 100,000 movies one by one can take tens of minutes; batching them into `_bulk` requests of 1,000–5,000 documents (typically **5–15 MB** per HTTP payload) finishes in seconds.

Every `_bulk` action consists of **two** lines: an action-and-metadata line followed by the document source line (except `delete`, which has no source line):

```json
{ "index": { "_index": "movies", "_id": "1" } }
{ "id": 1, "title": "Toy Story", "year": 1995, "genre": ["Animation", "Children", "Comedy"] }
{ "index": { "_index": "movies", "_id": "2" } }
{ "id": 2, "title": "Jumanji", "year": 1995, "genre": ["Adventure", "Children", "Fantasy"] }
```

> **Warning.** The `_bulk` endpoint requires `Content-Type: application/x-ndjson` and a **trailing newline** (`\n`) after the final line. Without the trailing newline, Elasticsearch returns `400 Bad Request` (`The bulk request must be terminated by a newline`).

## Generating NDJSON from CSV with Python

Suppose you have a MovieLens-style `movies.csv` file:

```csv
movieId,title,genres
1,"Toy Story (1995)",Adventure|Animation|Children|Comedy|Fantasy
2,"Jumanji (1995)",Adventure|Children|Fantasy
3,"Grumpier Old Men (1995)",Comedy|Romance
```

A lightweight generator script transforms each row into clean JSON, extracts the release year from the title, and writes chunked NDJSON files:

```python
import csv
import json
import re

YEAR_RE = re.compile(r"\((\d{4})\)\s*$")

def csv_to_ndjson(csv_path: str, ndjson_path: str, index_name: str = "movies") -> None:
    with open(csv_path, newline="", encoding="utf-8") as src, \
         open(ndjson_path, "w", encoding="utf-8") as dst:
        reader = csv.DictReader(src)
        for row in reader:
            raw_title = row["title"].strip()
            match = YEAR_RE.search(raw_title)
            year = int(match.group(1)) if match else None
            clean_title = YEAR_RE.sub("", raw_title).strip()

            genres = (
                [] if row["genres"] == "(no genres listed)"
                else row["genres"].split("|")
            )

            action = {"index": {"_index": index_name, "_id": row["movieId"]}}
            doc = {
                "id": int(row["movieId"]),
                "title": clean_title,
                "year": year,
                "genre": genres,
            }
            dst.write(json.dumps(action) + "\n")
            dst.write(json.dumps(doc) + "\n")

if __name__ == "__main__":
    csv_to_ndjson("movies.csv", "movies.ndjson")
```

## Submitting the NDJSON file with `curl`

Always use `--data-binary` (not `-d`), because `-d` strips newline characters and breaks NDJSON formatting:

```bash
curl -k -u elastic:changeme \
  -X POST "https://127.0.0.1:9200/_bulk?pretty" \
  -H "Content-Type: application/x-ndjson" \
  --data-binary @movies.ndjson
```

If your file is larger than ~15 MB, split it into chunks first (`split -l 10000 movies.ndjson chunk_`)—making sure each split contains an **even** number of lines so action/document pairs are never separated—and loop over the chunks.

## Inspecting `_bulk` responses for partial failures

A `_bulk` request can return HTTP `200 OK` even when individual documents fail (for example, due to a mapping type mismatch). Always check the top-level `"errors"` boolean in the response:

```json
{
  "took": 42,
  "errors": true,
  "items": [
    {
      "index": {
        "_index": "movies",
        "_id": "1",
        "status": 201,
        "result": "created"
      }
    },
    {
      "index": {
        "_index": "movies",
        "_id": "2",
        "status": 400,
        "error": {
          "type": "mapper_parsing_exception",
          "reason": "failed to parse field [year] of type [integer]"
        }
      }
    }
  ]
}
```

## Key takeaways

- Use `_bulk` with `Content-Type: application/x-ndjson` and `--data-binary` to avoid per-document HTTP overhead.
- Keep each bulk payload around **5–15 MB** (roughly 1,000–5,000 documents) so you do not overwhelm cluster memory or hit `http.max_content_length` (100 MB default).
- Set explicit `_id` values when re-running scripts so imports are idempotent.
- Never assume HTTP `200` means every document succeeded; always check `"errors": true` and inspect failed `items`.

<div class="chapter-nav">
<a class="chapter-nav__item" href="046-section-4-intro.html"><span>Previous</span><strong>46. Section 4 Intro</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="048-importing-with-client-libraries.html"><span>Next</span><strong>48. Importing with Client Libraries</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
