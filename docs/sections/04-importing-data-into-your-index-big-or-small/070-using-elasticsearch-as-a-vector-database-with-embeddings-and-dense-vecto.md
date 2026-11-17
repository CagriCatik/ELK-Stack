---
title: "70. Using Elasticsearch as a Vector Database with Embeddings and dense_vector"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 70. Using Elasticsearch as a Vector Database with Embeddings and dense_vector



Traditional keyword search (BM25) matches exact terms and stems—great for product SKUs, error codes, and names, but brittle when a user searches for *"space survival drama"* and the movie overview says *"astronaut stranded on Mars"*. **Embeddings** solve this by mapping text into high-dimensional numeric vectors where semantic similarity becomes geometric proximity.

With `dense_vector` and **HNSW** (Hierarchical Navigable Small World) indexing, Elasticsearch acts as a full-featured vector database *and* a lexical search engine in a single cluster.

## 1. Mapping a `dense_vector` Field

To store and search embeddings efficiently, declare a `dense_vector` field with `dims` matching your embedding model (for example, `384` for `all-MiniLM-L6-v2` or `1536` for OpenAI `text-embedding-3-small`) and `similarity: "cosine"`:

```bash
curl -s -X PUT "http://127.0.0.1:9200/movies-vectors" \
  -H "Content-Type: application/json" \
  -d '{
  "mappings": {
    "properties": {
      "title": { "type": "text" },
      "genre": { "type": "keyword" },
      "year": { "type": "integer" },
      "overview": { "type": "text" },
      "overview_vector": {
        "type": "dense_vector",
        "dims": 3,
        "index": true,
        "similarity": "cosine",
        "index_options": {
          "type": "hnsw",
          "m": 16,
          "ef_construction": 100
        }
      }
    }
  }
}' | jq .
```

*(We use `dims: 3` here so the example payloads stay readable; real models typically use `384`–`1536` dimensions.)*

### Similarity Metrics

| Metric | Use when |
| :--- | :--- |
| `cosine` | Direction matters more than vector magnitude (most text embedding models) |
| `dot_product` | Vectors are already unit-normalized (fastest similarity computation) |
| `l2_norm` | Euclidean distance between points is meaningful |

In Elasticsearch 8.x/9.x, `int8_hnsw` quantization is also available (and often default for larger vectors) to cut RAM usage by ~4x with minimal recall loss.

## 2. Indexing Documents with Embeddings

Index documents just like any other JSON payload, passing the embedding array in `overview_vector`:

```bash
curl -s -X POST "http://127.0.0.1:9200/movies-vectors/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  -d '
{ "index": { "_id": "1" } }
{ "title": "The Martian", "genre": "Sci-Fi", "year": 2015, "overview": "An astronaut stranded on Mars fights to survive.", "overview_vector": [0.92, 0.31, 0.15] }
{ "index": { "_id": "2" } }
{ "title": "Interstellar", "genre": "Sci-Fi", "year": 2014, "overview": "Explorers travel through a wormhole to save humanity.", "overview_vector": [0.85, 0.48, 0.22] }
{ "index": { "_id": "3" } }
{ "title": "Toy Story", "genre": "Animation", "year": 1995, "overview": "A cowboy doll is jealous of a new spaceman toy.", "overview_vector": [0.12, 0.19, 0.96] }
' | jq .
```

> **Tip.** Instead of generating embeddings in your application before indexing, you can also attach an Elasticsearch **Inference Pipeline** (`inference` processor) to call a deployed NLP model automatically at ingest time.

## 3. Approximate kNN Search (with Pre-Filtering)

Query `overview_vector` using the top-level `knn` clause. Always set `num_candidates` higher than `k` (a common starting point is `10 * k`) to trade a small amount of latency for higher recall:

```bash
curl -s "http://127.0.0.1:9200/movies-vectors/_search" \
  -H "Content-Type: application/json" \
  -d '{
  "knn": {
    "field": "overview_vector",
    "query_vector": [0.90, 0.35, 0.18],
    "k": 2,
    "num_candidates": 20,
    "filter": {
      "range": { "year": { "gte": 2010 } }
    }
  },
  "_source": ["title", "genre", "year"]
}' | jq .
```

Because `filter` is applied **during** HNSW graph traversal (pre-filtering), Elasticsearch guarantees you still get `k` matching results even when the filter excludes older movies.

## 4. Hybrid Search with Reciprocal Rank Fusion (RRF)

Combining **BM25 lexical search** (`query`) with **kNN vector search** (`knn`) gives you the best of both worlds: exact keyword precision plus semantic recall. **Reciprocal Rank Fusion (RRF)** merges both ranked lists without requiring manual score-normalization weights:

```bash
curl -s "http://127.0.0.1:9200/movies-vectors/_search" \
  -H "Content-Type: application/json" \
  -d '{
  "query": {
    "match": { "overview": "astronaut Mars survival" }
  },
  "knn": {
    "field": "overview_vector",
    "query_vector": [0.90, 0.35, 0.18],
    "k": 10,
    "num_candidates": 50
  },
  "rank": {
    "rrf": {
      "window_size": 50,
      "rank_constant": 60
    }
  }
}' | jq .
```

*(In Elasticsearch 8.14+ / 9.x, the `retriever` API also supports `rrf` pipelines with multiple sub-retrievers.)*

## Key takeaways

- Map embedding arrays as `dense_vector` with `dims`, `similarity` (`cosine`, `dot_product`, or `l2_norm`), and HNSW indexing.
- Use top-level `knn` with `num_candidates >= k` and inline `filter` clauses for fast, pre-filtered semantic search.
- Combine `query` (BM25) and `knn` with **Reciprocal Rank Fusion (`rank.rrf`)** for hybrid search that handles both exact terms and conceptual queries.

<div class="chapter-nav">
<a class="chapter-nav__item" href="069-exercise-importing-data-with-spark.html"><span>Previous</span><strong>69. [Exercise] Importing Data with Spark</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="071-section-4-wrapup.html"><span>Next</span><strong>71. Section 4 Wrapup</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
