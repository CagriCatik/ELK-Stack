---
title: "64. Syslog with Logstash Deep Dive"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 64. Syslog with Logstash Deep Dive



Network gear, firewalls, switches, and Linux daemons almost universally speak **Syslog**. While Logstash ships with a dedicated `syslog` input plugin, production environments often outgrow it because vendor implementations vary widely between **RFC 3164** and **RFC 5424** (and non-standard hybrids). Understanding the wire format—and how `syslog_pri` works—lets you parse any syslog stream reliably.

## RFC 3164 vs. RFC 5424

| Feature | RFC 3164 (BSD Syslog) | RFC 5424 (Modern Syslog) |
| :--- | :--- | :--- |
| **Timestamp** | `Oct 11 22:14:15` (no year, no timezone, no sub-seconds) | `2025-10-11T22:14:15.003Z` (ISO 8601 with year, TZ, fractional seconds) |
| **Header fields** | `<PRI>TIMESTAMP HOSTNAME TAG: MSG` | `<PRI>VERSION TIMESTAMP HOSTNAME APP-NAME PROCID MSGID [SD] MSG` |
| **Structured data** | None (unstructured text) | `[exampleSDID@32473 iut="3" eventSource="App"]` |
| **Max message size** | 1,024 bytes (legacy recommendation) | 2,048+ bytes |

## Decoding the Priority Value (`PRI`) with `syslog_pri`

Every syslog message begins with a `<PRI>` integer in angle brackets, such as `<34>` or `<134>`. `PRI` encodes both **Facility** (which subsystem sent the message, `0–23`) and **Severity** (`0` = Emergency to `7` = Debug):

```text
PRI = (Facility * 8) + Severity
```

For example, `<34>` means `34 / 8 = 4` (Facility `4` = `security/authorization`) with remainder `2` (Severity `2` = `critical`).

Logstash's `syslog_pri` filter automatically decodes this integer into human-readable `syslog_facility`, `syslog_facility_code`, `syslog_severity`, and `syslog_severity_code` fields.

## Recommended Pipeline: `tcp`/`udp` + `grok` + `syslog_pri`

Rather than relying on the rigid built-in `syslog` input (which fails if a firewall omits a field or uses RFC 5424), use `tcp`/`udp` inputs combined with `grok` and `syslog_pri`:

```ruby
input {
  udp {
    port => 5514
    type => "syslog"
  }
  tcp {
    port => 5514
    type => "syslog"
  }
}

filter {
  if [type] == "syslog" {
    grok {
      match => {
        "message" => [
          # RFC 3164
          "^<%{POSINT:syslog_pri:int}>%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid:int}\])?: %{GREEDYDATA:syslog_message}",
          # RFC 5424
          "^<%{POSINT:syslog_pri:int}>%{NONNEGINT:syslog_version:int} %{TIMESTAMP_ISO8601:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program} %{DATA:syslog_procid} %{DATA:syslog_msgid} (?:%{SYSLOG5424SD:syslog_sd}|-) %{GREEDYDATA:syslog_message}"
        ]
      }
    }

    syslog_pri { }

    date {
      match => [
        "syslog_timestamp",
        "MMM  d HH:mm:ss",
        "MMM dd HH:mm:ss",
        "ISO8601"
      ]
    }
  }
}

output {
  elasticsearch {
    hosts => ["http://127.0.0.1:9200"]
    index => "syslog-%{+YYYY.MM.dd}"
  }
}
```

## Operational Caveats

- **Privileged port `514`:** Linux prevents non-root processes (including the `logstash` service user) from binding to ports below `1024`. Listen on `5514` in Logstash and redirect `514 → 5514` via `iptables`/`nftables`, or use a local `rsyslog`/`syslog-ng` forwarder.
- **UDP packet loss:** UDP has no flow control or backpressure. Under burst load, kernel receive buffers overflow silently. Prefer **TCP (with TLS)** whenever your network devices support it, or increase `receive_buffer_bytes` on the `udp` input.

## Key takeaways

- RFC 3164 lacks year/timezone metadata and structured fields, whereas RFC 5424 uses ISO 8601 timestamps and structured key-value blocks.
- `PRI = Facility * 8 + Severity`; the `syslog_pri` filter decodes `<PRI>` into facility and severity names for easy Kibana filtering.
- Using `tcp`/`udp` inputs + `grok` + `syslog_pri` gives you full control over mixed RFC 3164, RFC 5424, and vendor-specific syslog formats.

<div class="chapter-nav">
<a class="chapter-nav__item" href="063-logstash-input-plugins-part-3-http-poller.html"><span>Previous</span><strong>63. Logstash Input Plugins, Part 3: HTTP Poller</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="065-elasticsearch-and-kafka-part-1.html"><span>Next</span><strong>65. Elasticsearch and Kafka, Part 1</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
