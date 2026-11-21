---
title: "7. Running Logstash"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 7. Running Logstash

You can run Logstash in two ways: interactively from the command line while developing and testing a pipeline, or as a managed `systemd` service in production.

## Quick smoke test with `-e`

To verify that Logstash starts and processes events without writing a config file, pass an inline pipeline with `-e`:

```bash
/usr/share/logstash/bin/logstash -e '
  input { stdin { } }
  output { stdout { codec => rubydebug } }
'
```

Wait until you see `Pipelines running`, then type `hello logstash` and press Enter. Logstash prints the structured event with `@timestamp`, `host`, and `message`:

```json
{
  "@timestamp" => 2026-11-17T18:30:00.123Z,
  "@version" => "1",
  "event" => {
    "original" => "hello logstash"
  },
  "host" => {
    "hostname" => "lab-node"
  },
  "message" => "hello logstash"
}
```

> **Tip.** Press `Ctrl+D` (EOF) or `Ctrl+C` to stop an interactive Logstash process cleanly.

## Running a configuration file with `-f`

Real pipelines live in `.conf` files. Always validate syntax before starting or reloading a pipeline using `--config.test_and_exit` (`-t`):

```bash
/usr/share/logstash/bin/logstash -t -f /etc/logstash/conf.d/movies.conf
```

Once `Configuration OK` is printed, run the pipeline:

```bash
/usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/movies.conf --config.reload.automatic
```

- `-f /path/to/file.conf` (or a directory `/etc/logstash/conf.d/`): loads the pipeline configuration.
- `--config.reload.automatic` (`-r`): watches the config file for edits and reloads the pipeline automatically without restarting the JVM (which saves 15–30 seconds of startup time during development).

## Running as a service with `pipelines.yml`

When you start Logstash via `systemd` (`sudo systemctl enable --now logstash`), it reads `/etc/logstash/pipelines.yml` instead of a single `-f` argument. Defining separate entries in `pipelines.yml` isolates unrelated workloads so a slow JDBC query never blocks your web access log pipeline:

```yaml
- pipeline.id: apache-logs
  path.config: "/etc/logstash/conf.d/apache.conf"
  pipeline.workers: 4

- pipeline.id: mysql-movies
  path.config: "/etc/logstash/conf.d/mysql-movies.conf"
  pipeline.workers: 1
```

> **Warning.** If you pass a directory like `/etc/logstash/conf.d/*.conf` to a single pipeline without `pipelines.yml`, Logstash **concatenates** all `.conf` files into one shared pipeline. Events from every input will flow through every filter and every output unless you wrap them in `if` conditionals.

## Checking pipeline health via the monitoring API

While Logstash is running, it exposes a local HTTP monitoring API on port `9600`:

```bash
curl -s "http://127.0.0.1:9600/_node/stats/pipelines?pretty"
```

This shows `events.in`, `events.filtered`, `events.out`, and per-plugin latency—making it easy to spot which filter or output is bottlenecking throughput.

## Key takeaways

- Use `-t` (`--config.test_and_exit`) to catch syntax errors before deploying a `.conf` change.
- Use `-r` (`--config.reload.automatic`) during development to avoid JVM restarts on every edit.
- Use `pipelines.yml` in production to isolate independent pipelines instead of concatenating unrelated `.conf` files.

<div class="chapter-nav">
<a class="chapter-nav__item" href="006-installing-logstash.html"><span>Previous</span><strong>6. Installing Logstash</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="008-logstash-and-mysql-part-1.html"><span>Next</span><strong>8. Logstash and MySQL, Part 1</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
