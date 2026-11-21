---
title: "15. Logstash Grok Examples for Common Log Formats"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 15. Logstash Grok Examples for Common Log Formats



Grok's strength is composability: you rarely write raw regular expressions from scratch because Logstash ships with over 120 reusable patterns for IPs, timestamps, HTTP methods, paths, and syslog headers. In practice, however, Grok is only the first step—you almost always pair it with `date`, `mutate`, and `geoip` filters to turn extracted strings into properly typed, time-indexed, enriched fields.

## 1. Apache Combined Access Logs

A typical Apache HTTP Server combined log line looks like this:

```text
83.149.9.216 - - [17/May/2025:10:05:03 +0000] "GET /presentations/logstash-monitorama-2013/images/kibana-search.png HTTP/1.1" 200 203023 "http://semicomplete.com/presentations/logstash-monitorama-2013/" "Mozilla/5.0"
```

Logstash includes `%{COMBINEDAPACHELOG}` out of the box, which expands into `clientip`, `ident`, `auth`, `timestamp`, `verb`, `request`, `httpversion`, `response`, `bytes`, `referrer`, and `agent`.

```ruby
filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }

  date {
    match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
    target => "@timestamp"
    remove_field => [ "timestamp" ]
  }

  mutate {
    convert => {
      "response" => "integer"
      "bytes"    => "integer"
    }
  }

  geoip {
    source => "clientip"
    target => "geoip"
  }
}
```

> **Note.** Always use the `date` filter when ingesting historical or buffered logs. Without it, `@timestamp` reflects when Logstash *read* the line rather than when the event *occurred*.

## 2. Nginx Access Logs with Custom Timing Fields

Nginx logs often include extra fields at the end of the line, such as `$request_time` and `$upstream_response_time`:

```text
10.0.2.15 - alice [17/May/2025:14:22:10 +0000] "POST /api/v1/orders HTTP/1.1" 201 512 "-" "curl/8.4.0" rt=0.042 uct=0.011
```

You can combine built-in patterns with inline type casting (`:int`, `:float`) so you don't even need a separate `mutate { convert => ... }` block for those fields:

```ruby
filter {
  grok {
    match => {
      "message" => '^%{IPORHOST:clientip} %{USER:ident} %{USER:auth} \[%{HTTPDATE:timestamp}\] "%{WORD:verb} %{DATA:request} HTTP/%{NUMBER:httpversion}" %{NUMBER:response:int} %{NUMBER:bytes:int} "%{DATA:referrer}" "%{DATA:agent}" rt=%{NUMBER:request_time:float} uct=%{NUMBER:upstream_time:float}'
    }
  }

  date {
    match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
    remove_field => [ "timestamp" ]
  }
}
```

## 3. Linux Syslog / Auth Logs

For standard Linux `/var/log/messages` or `/var/log/secure` lines:

```text
May 17 14:30:01 web-01 sshd[24192]: Failed password for invalid user admin from 203.0.113.45 port 52412 ssh2
```

You can start with `%{SYSLOGTIMESTAMP}` and `%{SYSLOGHOST}` and extract the SSH details:

```ruby
filter {
  grok {
    match => {
      "message" => "^%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:logsource} %{DATA:program}(?:\[%{POSINT:pid:int}\])?: %{GREEDYDATA:syslog_message}"
    }
  }

  if [program] == "sshd" {
    grok {
      match => {
        "syslog_message" => "Failed %{WORD:auth_method} for (?:invalid user )?%{USERNAME:target_user} from %{IP:source_ip} port %{POSINT:source_port:int}"
      }
      tag_on_failure => []
    }
  }

  date {
    match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
  }
}
```

Notice the two date formats (`MMM  d` with two spaces for single-digit days like `May  5`, and `MMM dd` for two-digit days like `May 17`).

## Grok Performance and Safety Tips

| Practice | Why it matters |
| :--- | :--- |
| Anchor patterns with `^` | Prevents the regex engine from scanning the entire string after a mismatch |
| Prefer specific patterns over `DATA` / `GREEDYDATA` | Reduces backtracking on long log lines |
| Use `tag_on_failure => ["_grokparsefailure"]` | Lets you route or inspect unparsed lines without dropping data |
| Drop raw `message` only after verifying | Saves storage once parsed fields are reliable, or keep it during debugging |

## Key takeaways

- Built-in patterns like `%{COMBINEDAPACHELOG}` and `%{SYSLOGTIMESTAMP}` cover standard formats and can be extended with inline `:int` and `:float` casts.
- Pair `grok` with `date` (to set `@timestamp` accurately), `mutate` (to clean and convert fields), and `geoip` (to enrich client IPs).
- Anchor Grok expressions with `^` and avoid unnecessary `GREEDYDATA` wildcards to keep Logstash CPU usage predictable at scale.

<div class="chapter-nav">
<a class="chapter-nav__item" href="014-workaround-if-the-grok-debugger-app-in-the-next-lecture-is-down.html"><span>Previous</span><strong>14. Workaround if the Grok Debugger app in the next lecture is down...</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="016-logstash-input-plugins-part-1-heartbeat.html"><span>Next</span><strong>16. Logstash Input Plugins, Part 1: Heartbeat</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
