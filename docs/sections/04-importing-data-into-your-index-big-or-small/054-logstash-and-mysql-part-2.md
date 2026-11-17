---
title: "54. Logstash and MySQL, Part 2"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 54. Logstash and MySQL, Part 2

Running `SELECT * FROM movies` once is fine for a static table, but production databases change continuously. You do not want to re-import millions of unchanged rows every minute, nor do you want duplicate documents in Elasticsearch when a row is updated.

To solve both problems, we combine **incremental tracking (`:sql_last_value`)** in the `jdbc` input with **deterministic `document_id`** in the `elasticsearch` output.

## Incremental polling with `:sql_last_value`

The `jdbc` input plugin tracks the highest value it has seen from a specified column and injects it into your SQL query via the `:sql_last_value` parameter.

| Setting | Purpose |
| :--- | :--- |
| `schedule => "* * * * *"` | Cron expression; runs the query every minute |
| `use_column_value => true` | Track a column's value (`updated_at` or `movie_id`) instead of the wall-clock run time |
| `tracking_column => "updated_at"` | Column used for incremental comparison |
| `tracking_column_type => "timestamp"` | `"numeric"` (default) or `"timestamp"` |
| `last_run_metadata_path` | File where Logstash persists `:sql_last_value` across restarts |

## Complete MySQL-to-Elasticsearch pipeline

Update `/etc/logstash/conf.d/mysql-movies.conf`:

```ruby
input {
  jdbc {
    jdbc_driver_library => "/opt/jdbc-drivers/mysql-connector-j-8.4.0.jar"
    jdbc_driver_class => "com.mysql.cj.jdbc.Driver"
    jdbc_connection_string => "jdbc:mysql://127.0.0.1:3306/movielens?useSSL=false&serverTimezone=UTC"
    jdbc_user => "logstash"
    jdbc_password => "StrongPassword!"

    schedule => "* * * * *"
    use_column_value => true
    tracking_column => "updated_at"
    tracking_column_type => "timestamp"
    last_run_metadata_path => "/var/lib/logstash/.logstash_jdbc_movies_last_run"

    statement => "
      SELECT movie_id, title, release_year, updated_at
      FROM movies
      WHERE updated_at > :sql_last_value
      ORDER BY updated_at ASC
    "
  }
}

filter {
  mutate {
    remove_field => ["@version"]
  }
}

output {
  elasticsearch {
    hosts => ["https://127.0.0.1:9200"]
    user => "elastic"
    password => "changeme"
    ssl_certificate_authorities => ["/etc/elasticsearch/certs/http_ca.crt"]
    index => "movies"
    document_id => "%{movie_id}"
  }
}
```

### Why `document_id => "%{movie_id}"` is essential

When a movie's `title` is edited in MySQL, its `updated_at` column advances, so the next scheduled query picks it up. Because `document_id` is set to `%{movie_id}`, Elasticsearch **overwrites** the existing document with that `_id` rather than creating a second copy.

### Why `ORDER BY updated_at ASC` matters

If Logstash stops mid-batch or crashes, it persists the `updated_at` value of the last processed row. Ordering ascending ensures `:sql_last_value` moves forward monotonically without skipping older rows.

## Handling deletes (important caveat)

Polling via `WHERE updated_at > :sql_last_value` detects **inserts** and **updates**, but it cannot detect hard `DELETE` statements because the deleted row no longer exists in MySQL. Common workarounds include:

1. **Soft deletes**: Add an `is_deleted TINYINT(1)` column in MySQL, filter out deleted docs in search queries (or delete them via a Logstash `if [is_deleted] == 1 { ... action => "delete" }` conditional).
2. **Change Data Capture (CDC)**: Stream the MySQL binlog using Debezium + Kafka Connect for true real-time insert/update/delete synchronization.

## Key takeaways

- Combine `use_column_value => true`, `tracking_column`, and `:sql_last_value` to poll only new or modified rows.
- Always set `document_id => "%{primary_key}"` in the `elasticsearch` output so updates are idempotent.
- JDBC polling cannot see hard `DELETE`s; use soft-delete flags or binlog CDC when deletions must propagate.

<div class="chapter-nav">
<a class="chapter-nav__item" href="053-logstash-and-mysql-part-1.html"><span>Previous</span><strong>53. Logstash and MySQL, Part 1</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="055-importing-csv-data-with-logstash.html"><span>Next</span><strong>55. Importing CSV Data with Logstash</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
