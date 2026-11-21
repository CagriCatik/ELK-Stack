---
title: "24. [Exercise] Importing Data with Spark"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04 · EXERCISE</div>

# 24. [Exercise] Importing Data with Spark



In this exercise, you will build an end-to-end batch import pipeline using **PySpark** and the `elasticsearch-spark` connector to transform a MovieLens-style CSV file and upsert it into Elasticsearch.

## Your task

1. Create a sample CSV file `/tmp/movies_spark.csv` with columns `movieId,title,genres` (including a trailing release year in parentheses inside `title`, e.g., `Matrix, The (1999)`).
2. Create an Elasticsearch index named `movies-spark` with explicit mappings for `movie_id` (`keyword`), `title` (`text` + `.keyword` subfield), `genres` (`keyword`), and `year` (`integer`).
3. Write a PySpark script `/tmp/import_movies_spark.py` that:
   - Reads `/tmp/movies_spark.csv` with headers.
   - Extracts the 4-digit `year` from `title` as an integer.
   - Splits pipe-delimited `genres` (e.g., `Action|Sci-Fi`) into an array of strings.
   - Upserts the resulting DataFrame into `movies-spark` using `movie_id` as the document `_id`.
4. Run the job with `spark-submit` (including the `elasticsearch-spark` package) and verify the indexed documents with `curl`.

## Walkthrough

<details>
<summary>Show solution</summary>

### Step 1: Create the sample CSV

```bash
cat <<'EOF' > /tmp/movies_spark.csv
movieId,title,genres
1,Toy Story (1995),Adventure|Animation|Children|Comedy|Fantasy
2,Jumanji (1995),Adventure|Children|Fantasy
260,Star Wars: Episode IV - A New Hope (1977),Action|Adventure|Sci-Fi
2571,Matrix, The (1999),Action|Sci-Fi|Thriller
EOF
```

### Step 2: Create the `movies-spark` index mapping

```bash
curl -s -X PUT "http://127.0.0.1:9200/movies-spark" \
  -H "Content-Type: application/json" \
  -d '{
  "mappings": {
    "properties": {
      "movie_id": { "type": "keyword" },
      "title": {
        "type": "text",
        "fields": { "keyword": { "type": "keyword" } }
      },
      "genres": { "type": "keyword" },
      "year": { "type": "integer" }
    }
  }
}' | jq .
```

### Step 3: Write `/tmp/import_movies_spark.py`

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, regexp_extract, split, when

spark = SparkSession.builder.appName("ImportMoviesToES").getOrCreate()

raw_df = (
    spark.read
    .option("header", "true")
    .option("quote", '"')
    .csv("/tmp/movies_spark.csv")
)

clean_df = (
    raw_df
    .withColumn("movie_id", col("movieId").cast("string"))
    .withColumn("year_str", regexp_extract(col("title"), r"\((\d{4})\)\s*$", 1))
    .withColumn("year", when(col("year_str") != "", col("year_str").cast("int")))
    .withColumn("genres", split(col("genres"), r"\|"))
    .select("movie_id", "title", "genres", "year")
)

(
    clean_df.write
    .format("org.elasticsearch.spark.sql")
    .option("es.nodes", "127.0.0.1")
    .option("es.port", "9200")
    .option("es.nodes.wan.only", "true")
    .option("es.resource", "movies-spark")
    .option("es.mapping.id", "movie_id")
    .option("es.write.operation", "upsert")
    .mode("append")
    .save()
)

spark.stop()
```

### Step 4: Submit the Spark job and verify

```bash
spark-submit \
  --packages org.elasticsearch:elasticsearch-spark-30_2.12:8.15.0 \
  /tmp/import_movies_spark.py
```

Verify the documents in Elasticsearch:

```bash
curl -s "http://127.0.0.1:9200/movies-spark/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
  "query": { "term": { "genres": "Sci-Fi" } }
}'
```

Notice that `_id` equals `260` and `2571`, `genres` is an array (`["Action", "Adventure", "Sci-Fi"]`), and `year` is stored as an integer.

</details>

## Why this matters

Real-world datasets rarely arrive in clean, Elasticsearch-ready JSON. Using Spark to parse, type-cast, and split fields before indexing—while setting `es.mapping.id` and `es.write.operation = "upsert"`—gives you a repeatable, idempotent pipeline that scales from a laptop CSV to multi-terabyte data lakes.

<div class="chapter-nav">
<a class="chapter-nav__item" href="023-elasticsearch-and-apache-spark-part-2.html"><span>Previous</span><strong>23. Elasticsearch and Apache Spark, Part 2</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="025-using-elasticsearch-as-a-vector-database-with-embeddings-and-dense-vecto.html"><span>Next</span><strong>25. Using Elasticsearch as a Vector Database with Embeddings and dense_vector</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
