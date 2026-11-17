---
title: "53. Logstash and MySQL, Part 1"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 53. Logstash and MySQL, Part 1

Relational databases like MySQL and PostgreSQL are great for transactional integrity, but terrible for full-text search, fuzzy matching, and high-cardinality faceted aggregations. A classic ELK pattern is syncing tables from MySQL into Elasticsearch using Logstash's **JDBC input plugin**.

In Part 1, we set up the MySQL JDBC driver (Connector/J) and run an initial full-table import. In Part 2, we make the sync incremental and idempotent.

## Step 1: Obtain the MySQL Connector/J driver

Logstash does not bundle proprietary or GPL-licensed database drivers, so you must provide the MySQL JDBC `.jar` file yourself.

Download the platform-independent archive for **MySQL Connector/J 8.x** from `dev.mysql.com/downloads/connector/j/`, extract it, and place the `.jar` in a readable directory such as `/usr/share/logstash/logstash-core/lib/jars/` or `/opt/jdbc-drivers/`:

```bash
sudo mkdir -p /opt/jdbc-drivers
sudo cp mysql-connector-j-8.4.0.jar /opt/jdbc-drivers/
sudo chmod 644 /opt/jdbc-drivers/mysql-connector-j-8.4.0.jar
```

> **Note.** Make sure the `logstash` system user has read permission on both `/opt/jdbc-drivers/` and the `.jar` file; otherwise Logstash fails at startup with `Java::JavaSql::SQLException: No suitable driver found`.

## Step 2: Prepare a sample MySQL table

Assume you have a `movielens.movies` table in MySQL:

```sql
CREATE TABLE movies (
  movie_id INT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  release_year INT,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

Create a dedicated read-only MySQL user for Logstash rather than using `root`:

```sql
CREATE USER 'logstash'@'%' IDENTIFIED BY 'StrongPassword!';
GRANT SELECT ON movielens.* TO 'logstash'@'%';
FLUSH PRIVILEGES;
```

## Step 3: Write the initial JDBC pipeline

Create `/etc/logstash/conf.d/mysql-movies.conf`:

```ruby
input {
  jdbc {
    jdbc_driver_library => "/opt/jdbc-drivers/mysql-connector-j-8.4.0.jar"
    jdbc_driver_class => "com.mysql.cj.jdbc.Driver"
    jdbc_connection_string => "jdbc:mysql://127.0.0.1:3306/movielens?useSSL=false&serverTimezone=UTC"
    jdbc_user => "logstash"
    jdbc_password => "StrongPassword!"
    statement => "SELECT movie_id, title, release_year, updated_at FROM movies"
  }
}

output {
  stdout {
    codec => rubydebug
  }
}
```

Test the configuration and run it once:

```bash
/usr/share/logstash/bin/logstash -t -f /etc/logstash/conf.d/mysql-movies.conf
/usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/mysql-movies.conf
```

Each row returned by `SELECT` becomes one Logstash event with lowercase field names (`movie_id`, `title`, `release_year`, `updated_at`). Notice that without a `schedule` parameter, the `jdbc` input runs the query **once** and exits.

> **Tip.** If you are importing a very large table (millions of rows), set `jdbc_paging_enabled => true` and `jdbc_page_size => 50000` so Logstash fetches rows in chunks instead of loading the entire JDBC result set into JVM heap at once.

## Key takeaways

- Logstash's `jdbc` input connects to any relational database that provides a JDBC `.jar` driver.
- For MySQL 8.x Connector/J, use `com.mysql.cj.jdbc.Driver` (not the legacy `com.mysql.jdbc.Driver`).
- Always test a new `jdbc` pipeline against `stdout { codec => rubydebug }` first to verify column names and types before writing to Elasticsearch.

<div class="chapter-nav">
<a class="chapter-nav__item" href="052-running-logstash.html"><span>Previous</span><strong>52. Running Logstash</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="054-logstash-and-mysql-part-2.html"><span>Next</span><strong>54. Logstash and MySQL, Part 2</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
