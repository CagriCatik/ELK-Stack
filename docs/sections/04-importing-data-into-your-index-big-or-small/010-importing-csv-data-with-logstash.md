---
title: "10. Importing CSV Data with Logstash"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 10. Importing CSV Data with Logstash

CSV exports are one of the most common data formats you will encounter—from MovieLens datasets to billing reports and legacy system dumps. Logstash handles CSV files using the `file` input plugin paired with the `csv` filter plugin.

## Reading files with `sincedb`

When the `file` input reads a file, it tracks the byte offset it has reached in a **sincedb** file so it never re-indexes the same lines after a restart.

- **In production**: Keep the default `sincedb_path` (under `/var/lib/logstash/plugins/inputs/file/`) so Logstash resumes where it left off.
- **For one-time lab imports**: Set `start_position => "beginning"` and `sincedb_path => "/dev/null"` so you can re-run the pipeline on the same file during testing.

> **Warning.** Never use `sincedb_path => "/dev/null"` in production—every Logstash restart will re-read the entire file from byte 0.

## Complete CSV pipeline example

Suppose `/data/movies.csv` looks like this:

```csv
movieId,title,genres
1,"Toy Story (1995)",Adventure|Animation|Children|Comedy|Fantasy
2,"Jumanji (1995)",Adventure|Children|Fantasy
3,"Grumpier Old Men (1995)",Comedy|Romance
```

Create `/etc/logstash/conf.d/csv-movies.conf`:

```ruby
input {
  file {
    path => "/data/movies.csv"
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
}

filter {
  csv {
    separator => ","
    skip_header => true
    columns => ["id", "title", "genre"]
    convert => {
      "id" => "integer"
    }
  }

  mutate {
    split => { "genre" => "|" }
    remove_field => ["message", "event", "@version", "log", "host"]
  }
}

output {
  elasticsearch {
    hosts => ["https://127.0.0.1:9200"]
    user => "elastic"
    password => "changeme"
    ssl_certificate_authorities => ["/etc/elasticsearch/certs/http_ca.crt"]
    index => "movies"
    document_id => "%{id}"
  }
}
```

### Key `csv` filter options

| Option | Behavior |
| :--- | :--- |
| `columns => [...]` | Explicit field names in column order |
| `autodetect_column_names => true` | Reads column names from the first line automatically (useful for wide CSVs; note that it assumes the file starts with the header) |
| `skip_header => true` | Drops the header row when `columns` are specified explicitly |
| `convert => { "col" => "integer" }` | Casts strings to `integer`, `float`, `boolean`, or `date_time` |
| `quote_char => '"'` | Handles quoted fields containing commas (default is `"`) |

If a line fails to parse (for example, malformed quotes), the `csv` filter adds a `_csvparsefailure` tag to `tags` so you can route or inspect broken rows instead of silently indexing garbage.

## Key takeaways

- Combine `file` input (`start_position => "beginning"`) with the `csv` filter to turn delimited rows into structured events.
- Use `skip_header => true` when defining `columns` explicitly so the header line is not indexed as a document.
- Use `convert` in the `csv` filter and `split` in `mutate` to ensure numeric types and arrays match your Elasticsearch mapping.

<div class="chapter-nav">
<a class="chapter-nav__item" href="009-logstash-and-mysql-part-2.html"><span>Previous</span><strong>9. Logstash and MySQL, Part 2</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="011-importing-json-data-with-logstash.html"><span>Next</span><strong>11. Importing JSON Data with Logstash</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
