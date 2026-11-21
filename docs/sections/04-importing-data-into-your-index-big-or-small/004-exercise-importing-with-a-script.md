---
title: "4. [Exercise] Importing with a Script"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04 · EXERCISE</div>

# 4. [Exercise] Importing with a Script

In this exercise, you will build a complete, idempotent Python ingestion script using `elasticsearch.helpers.bulk` to load a MovieLens-style CSV file into a `movies` index with an explicit mapping.

## Your task

Given a `movies.csv` file with the following format:

```csv
movieId,title,genres
1,"Toy Story (1995)",Adventure|Animation|Children|Comedy|Fantasy
2,"Jumanji (1995)",Adventure|Children|Fantasy
3,"Grumpier Old Men (1995)",Comedy|Romance
4,"Waiting to Exhale (1995)",Comedy|Drama|Romance
5,"Father of the Bride Part II (1995)",Comedy
```

Complete these steps:

1. **Create the `movies` index** with an explicit mapping before indexing:
   - `id`: `integer`
   - `title`: `text` with a `.raw` `keyword` multi-field for sorting/exact matching
   - `year`: `integer`
   - `genre`: `keyword`
2. **Write a Python script (`import_movies.py`)** that:
   - Connects to `https://127.0.0.1:9200` (or `http://127.0.0.1:9200` if security is disabled in your local lab).
   - Reads `movies.csv` lazily using `csv.DictReader`.
   - Extracts the 4-digit release year from `title` (if present) into `year` and strips `(YYYY)` from `title`.
   - Splits `genres` on `|` into a list (returning `[]` for `(no genres listed)`).
   - Uses `elasticsearch.helpers.bulk` with `_id` set to `movieId`, `chunk_size=1000`, `max_retries=3`, and `raise_on_error=False`.
3. **Verify the import** by refreshing the index and running a `GET /movies/_count` and a sample `match` query.

## Walkthrough

<details>
<summary>Show solution</summary>

### 1. Create the index mapping

```bash
curl -k -u elastic:changeme -X PUT "https://127.0.0.1:9200/movies" \
  -H "Content-Type: application/json" \
  -d '{
  "mappings": {
    "properties": {
      "id": { "type": "integer" },
      "title": {
        "type": "text",
        "fields": {
          "raw": { "type": "keyword" }
        }
      },
      "year": { "type": "integer" },
      "genre": { "type": "keyword" }
    }
  }
}'
```

### 2. Python bulk import script (`import_movies.py`)

```python
import csv
import re
from typing import Iterator
from elasticsearch import Elasticsearch, helpers

YEAR_PATTERN = re.compile(r"\((\d{4})\)\s*$")

def parse_movies(csv_path: str) -> Iterator[dict]:
    with open(csv_path, mode="r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            raw_title = row["title"].strip()
            match = YEAR_PATTERN.search(raw_title)
            year = int(match.group(1)) if match else None
            clean_title = YEAR_PATTERN.sub("", raw_title).strip()

            raw_genres = row["genres"].strip()
            genres = [] if raw_genres == "(no genres listed)" else raw_genres.split("|")

            yield {
                "_op_type": "index",
                "_index": "movies",
                "_id": row["movieId"],
                "_source": {
                    "id": int(row["movieId"]),
                    "title": clean_title,
                    "year": year,
                    "genre": genres,
                },
            }

def main() -> None:
    es = Elasticsearch(
        "https://127.0.0.1:9200",
        basic_auth=("elastic", "changeme"),
        verify_certs=False,  # Use ca_certs="/path/to/http_ca.crt" in production
    )

    success, errors = helpers.bulk(
        es,
        parse_movies("movies.csv"),
        chunk_size=1000,
        max_retries=3,
        raise_on_error=False,
    )

    es.indices.refresh(index="movies")
    print(f"Successfully indexed {success} movies.")
    if errors:
        print(f"Encountered {len(errors)} errors. First error: {errors[0]}")

if __name__ == "__main__":
    main()
```

### 3. Verify the imported documents

```bash
curl -k -u elastic:changeme "https://127.0.0.1:9200/movies/_count?pretty"

curl -k -u elastic:changeme -X GET "https://127.0.0.1:9200/movies/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "bool": {
      "must": { "match": { "title": "Toy Story" } },
      "filter": { "term": { "year": 1995 } }
    }
  }
}'
```

</details>

## Why this matters

Defining the mapping *before* running a bulk script guarantees that `year` is indexed as an `integer` (supporting range queries) and `genre` as a `keyword` (supporting exact aggregations), rather than relying on dynamic mapping guesses. Using deterministic `_id` values (`movieId`) means you can safely re-run the script after fixing a bad row without creating duplicate documents.

<div class="chapter-nav">
<a class="chapter-nav__item" href="003-importing-with-client-libraries.html"><span>Previous</span><strong>3. Importing with Client Libraries</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="005-introducing-logstash.html"><span>Next</span><strong>5. Introducing Logstash</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
