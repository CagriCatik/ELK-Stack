---
title: "110. Uptime Monitoring with Heartbeat"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 110. Uptime Monitoring with Heartbeat



Logs and node metrics tell you how your infrastructure behaves *internally*, but they don't tell you whether external users can actually reach your APIs, TLS certificates are about to expire, or DNS is resolving. **Elastic Heartbeat** is a lightweight Beat that performs **synthetic uptime monitoring** from outside your services by probing **HTTP/HTTPS**, **TCP**, and **ICMP** endpoints on a schedule.

## Configuring `heartbeat.yml`

In `/etc/heartbeat/heartbeat.yml`, you define one or more `heartbeat.monitors` and point `output.elasticsearch` at your monitoring cluster:

```yaml
heartbeat.monitors:
  # 1. HTTP/HTTPS monitor with response status and TLS check
  - type: http
    id: movies-api-health
    name: "Movies Search API"
    enabled: true
    schedule: '@every 10s'
    urls:
      - "https://api.example.com/health"
    timeout: 5s
    check.response:
      status: [200]
      json:
        - description: "Verify cluster status is ok"
          condition:
            equals:
              status: "ok"

  # 2. TCP monitor for Elasticsearch or database ports
  - type: tcp
    id: es-http-port
    name: "Elasticsearch 9200 TCP"
    schedule: '@every 15s'
    hosts: ["10.0.1.21:9200", "10.0.1.22:9200"]
    timeout: 3s

  # 3. ICMP ping monitor for network reachability
  - type: icmp
    id: gateway-ping
    name: "Core Gateway Ping"
    schedule: '@every 30s'
    hosts: ["10.0.1.1"]
    wait: 1s

output.elasticsearch:
  hosts: ["https://monitoring-es.example.com:9200"]
  username: "heartbeat_writer"
  password: "${HEARTBEAT_ES_PASS}"

setup.kibana:
  host: "https://kibana.example.com:5601"
```

## What Heartbeat Records

Every probe emits a structured event containing:
- `monitor.status`: `"up"` or `"down"`
- `monitor.duration.us`: Total round-trip latency (DNS + TCP connect + TLS handshake + HTTP response)
- `tls.certificate_not_valid_after`: Enables alerting **days before** an SSL/TLS certificate expires
- `error.message`: Exact failure reason (`connection refused`, `i/o timeout`, `status 503`)

## Viewing Results in Kibana Uptime / Synthetics

Once Heartbeat is running (`sudo systemctl enable --now heartbeat-elastic`), open **Observability → Uptime** (or **Synthetics** in newer 8.x/9.x Kibana) to view:
- Live **Up / Down** status and availability percentage per monitor
- Latency percentiles (`p50`, `p95`, `p99`) broken down by DNS, TCP, TLS, and HTTP wait time
- Built-in **Alerting rules** (e.g., notify Slack/PagerDuty when `monitor.status == down` for 2 consecutive checks or TLS expires within 14 days)

> **Note.** In modern Elastic Stack 8.x/9.x deployments, Heartbeat's lightweight ICMP/TCP/HTTP checks are complemented by **Elastic Synthetics** (via Elastic Agent), which adds browser-based Playwright journeys on top of Heartbeat's core engine.

## Key takeaways

- **Heartbeat** provides external, synthetic availability and latency monitoring for **HTTP**, **TCP**, and **ICMP** endpoints.
- Configure `heartbeat.monitors` in `heartbeat.yml` with `schedule` intervals and `check.response` assertions.
- Heartbeat automatically tracks **TLS certificate expiration** and breaks down latency by DNS, TCP, TLS, and HTTP phases.
- Run Heartbeat from **outside** the target cluster (and ship to a separate monitoring cluster) so network outages are still detected and alerted on.

<div class="chapter-nav">
<a class="chapter-nav__item" href="109-rolling-restarts.html"><span>Previous</span><strong>109. Rolling Restarts</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="111-section-8-wrapup.html"><span>Next</span><strong>111. Section 8 Wrapup</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
