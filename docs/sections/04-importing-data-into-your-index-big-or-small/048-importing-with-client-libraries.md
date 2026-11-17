---
title: "48. Importing with Client Libraries"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 48. Importing with Client Libraries

Generating static NDJSON files works for small datasets, but manually splitting files, retrying `429 Too Many Requests` responses, and parsing per-item errors quickly becomes tedious. Official Elasticsearch client libraries—such as `elasticsearch` for Python and `@elastic/elasticsearch` for Node.js—provide built-in bulk helpers that handle chunking, connection pooling, compression, and exponential backoff automatically.

## Python: `elasticsearch.helpers.bulk`

Install the official 8.x Python client:

```bash
pip install "elasticsearch>=8.0,<9.0"
```

### Connecting securely

In Elastic Stack 8.x+, HTTPS and authentication are enabled by default. Connect using an API key (recommended for scripts and services) or basic auth with the cluster CA certificate:

```python
from elasticsearch import Elasticsearch

es = Elasticsearch(
    "https://127.0.0.1:9200",
    ca_certs="/etc/elasticsearch/certs/http_ca.crt",
    api_key=("your_api_key_id", "your_api_key_secret"),
)
```

### Streaming documents with a generator

The `helpers.bulk` and `helpers.streaming_bulk` functions accept any Python generator yielding action dictionaries. Using a generator keeps memory usage constant even when importing millions of rows:

```python
import csv
from elasticsearch import Elasticsearch, helpers

es = Elasticsearch(
    "https://127.0.0.1:9200",
    ca_certs="/etc/elasticsearch/certs/http_ca.crt",
    basic_auth=("elastic", "changeme"),
)

def generate_movie_actions(csv_path: str):
    with open(csv_path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            yield {
                "_op_type": "index",
                "_index": "movies",
                "_id": row["movieId"],
                "_source": {
                    "id": int(row["movieId"]),
                    "title": row["title"],
                    "genre": row["genres"].split("|"),
                },
            }

success, errors = helpers.bulk(
    es,
    generate_movie_actions("movies.csv"),
    chunk_size=2000,          # docs per _bulk request
    max_chunk_bytes=10_485_760,  # 10 MB ceiling per request
    max_retries=3,            # retry on 429 / transient 503
    initial_backoff=2,
    raise_on_error=False,     # return errors list instead of raising
)

print(f"Indexed: {success}, Failed: {len(errors)}")
for err in errors[:5]:
    print(err)
```

### Choosing the right helper

| Helper | Behavior | When to use |
| :--- | :--- | :--- |
| `helpers.bulk` | Consumes the entire iterator and returns `(success_count, errors)` | Batch jobs where you want a summary at the end |
| `helpers.streaming_bulk` | Yields `(ok, info)` for each document as batches complete | Long-running streams where you log or dead-letter failures immediately |
| `helpers.parallel_bulk` | Runs multiple worker threads sending `_bulk` requests concurrently | High-throughput backfills across multi-node clusters |

> **Tip.** When bulk-loading a brand-new index, temporarily set `"index.refresh_interval": "-1"` and `"index.number_of_replicas": 0"` before the import, then restore `"1s"` and `1` afterward (and call `POST /movies/_refresh`). This avoids creating thousands of tiny Lucene segments during ingestion.

## Node.js: `@elastic/elasticsearch`

The official Node.js client offers a comparable `client.helpers.bulk` utility with built-in concurrency and retry handling:

```bash
npm install @elastic/elasticsearch
```

```javascript
import fs from "node:fs";
import readline from "node:readline";
import { Client } from "@elastic/elasticsearch";

const client = new Client({
  node: "https://127.0.0.1:9200",
  auth: { apiKey: "base64_encoded_api_key" },
  tls: { ca: fs.readFileSync("/etc/elasticsearch/certs/http_ca.crt") },
});

async function run() {
  const rl = readline.createInterface({
    input: fs.createReadStream("movies.ndjson"),
    crlfDelay: Infinity,
  });

  const result = await client.helpers.bulk({
    datasource: rl,
    flushBytes: 5 * 1024 * 1024, // 5 MB
    concurrency: 2,
    onDocument(line) {
      const doc = JSON.parse(line);
      return [
        { index: { _index: "movies", _id: doc.id } },
        doc,
      ];
    },
    onDrop(doc) {
      console.error("Failed document:", doc);
    },
  });

  console.log(result);
}

run().catch(console.error);
```

## Key takeaways

- Official client libraries manage batch sizing, HTTP keep-alive, and `429` backoff for you.
- Always stream records via a generator or readable stream rather than loading an entire dataset into memory.
- Set `raise_on_error=False` (Python) or `onDrop` (Node.js) so a single malformed document does not abort a multi-million-row import.

<div class="chapter-nav">
<a class="chapter-nav__item" href="047-importing-data-with-a-script.html"><span>Previous</span><strong>47. Importing Data with a Script</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="049-exercise-importing-with-a-script.html"><span>Next</span><strong>49. [Exercise] Importing with a Script</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
