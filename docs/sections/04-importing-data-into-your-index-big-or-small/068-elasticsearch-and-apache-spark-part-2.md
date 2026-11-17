---
title: "68. Elasticsearch and Apache Spark, Part 2"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 68. Elasticsearch and Apache Spark, Part 2



Let's look at concrete PySpark patterns for **writing** DataFrames to Elasticsearch, **reading** with predicate pushdown, and **streaming** continuously via Spark Structured Streaming.

## 1. Writing a DataFrame to Elasticsearch

Use `format("org.elasticsearch.spark.sql")` (or the short alias `format("es")`) with `SaveMode.Append`:

```python
from pyspark.sql import SparkSession

spark = (
    SparkSession.builder
    .appName("es-batch-writer")
    .getOrCreate()
)

df = spark.read.parquet("s3a://my-bucket/movies-enriched/")

(
    df.write
    .format("org.elasticsearch.spark.sql")
    .option("es.nodes", "127.0.0.1")
    .option("es.port", "9200")
    .option("es.nodes.wan.only", "true")
    .option("es.resource", "movies")
    .option("es.mapping.id", "movie_id")
    .option("es.write.operation", "upsert")
    .option("es.batch.size.entries", "1000")
    .option("es.batch.size.bytes", "5mb")
    .mode("append")
    .save()
)
```

Setting `es.mapping.id` + `es.write.operation = "upsert"` makes the job **idempotent**: if a Spark task retries after a failure, it updates the existing `_id` instead of creating duplicate documents.

## 2. Reading from Elasticsearch with Pushdown (`es.query`)

When reading an index into Spark, push filtering down to Elasticsearch with `es.query` so irrelevant documents never cross the network:

```python
scifi_df = (
    spark.read
    .format("org.elasticsearch.spark.sql")
    .option("es.nodes", "127.0.0.1")
    .option("es.port", "9200")
    .option("es.nodes.wan.only", "true")
    .option("es.resource", "movies")
    .option("es.query", '{"query": {"bool": {"filter": [{"term": {"genre": "Sci-Fi"}}, {"range": {"year": {"gte": 2000}}}]}}}')
    .load()
)

scifi_df.show(10, truncate=False)
```

Spark SQL also automatically pushes down simple `WHERE` filters (e.g., `df.filter("year >= 2000")`) when `es.pushdown` is enabled (the default).

## 3. Structured Streaming into Elasticsearch

For micro-batch streaming (e.g., Spark reading from Kafka and writing to Elasticsearch):

```python
query = (
    enriched_stream.writeStream
    .format("org.elasticsearch.spark.sql")
    .outputMode("append")
    .option("checkpointLocation", "/tmp/spark-checkpoints/movies-es")
    .option("es.nodes", "127.0.0.1")
    .option("es.port", "9200")
    .option("es.nodes.wan.only", "true")
    .option("es.resource", "movies-stream")
    .start()
)
```

`checkpointLocation` is required by Structured Streaming so Spark can track committed micro-batch offsets across restarts.

## Security and Version Compatibility

- **TLS & Authentication (8.x/9.x):** Pass `es.net.ssl = "true"`, `es.net.http.auth.user`, and `es.net.http.auth.pass` (or an API key via `es.net.http.header.Authorization`).
- **JAR Matching:** Always match the connector artifact to your Spark and Scala versions—for example, `org.elasticsearch:elasticsearch-spark-30_2.12:8.15.0` for Spark 3.x on Scala 2.12.

## Key takeaways

- Combine `es.mapping.id` with `es.write.operation = "upsert"` for safe, idempotent Spark retries.
- Use `es.query` (or Spark SQL `es.pushdown`) to filter documents inside Elasticsearch before transferring data to Spark executors.
- Match the `elasticsearch-spark` JAR to both your Spark major version and Scala binary version (`_2.12` or `_2.13`).

<div class="chapter-nav">
<a class="chapter-nav__item" href="067-elasticsearch-and-apache-spark-part-1.html"><span>Previous</span><strong>67. Elasticsearch and Apache Spark, Part 1</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="069-exercise-importing-data-with-spark.html"><span>Next</span><strong>69. [Exercise] Importing Data with Spark</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
