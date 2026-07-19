---
title: "2. Installing Elasticsearch [Step by Step]"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 01</div>

# 2. Installing Elasticsearch [Step by Step]

This chapter gets a single-node Elasticsearch server running that you can use for every exercise in this knowledge base. The reference environment is an **Ubuntu virtual machine**, but the same steps work on any Debian-based Linux — and a Docker alternative is included below.

Working natively on Windows? Follow the [Windows companion guide](002-windows-installation.md) for a ZIP-based installation that keeps TLS and authentication enabled and optionally adds Kibana and Logstash.

## Prerequisites

- An Ubuntu VM (VirtualBox, VMware, WSL2, or a cloud instance) with at least **4 GB RAM** assigned — Elasticsearch is JVM-based and memory-hungry.
- No separate Java install is needed: modern Elasticsearch ships with its own bundled JDK.

## Step 1 — Add the Elastic package repository

```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
```

## Step 2 — Install Elasticsearch

```bash
sudo apt-get update
sudo apt-get install elasticsearch
```

Watch the install output: it prints the **auto-generated password for the `elastic` superuser**. Save it. If you miss it, you can reset it later:

```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
```

## Step 3 — Configure for local experimentation

The main configuration file is `/etc/elasticsearch/elasticsearch.yml`. For a local learning setup it is common to simplify things by binding to localhost and (optionally) disabling TLS security — **never do this on a production or internet-facing machine**:

```yaml
# /etc/elasticsearch/elasticsearch.yml
network.host: 127.0.0.1
discovery.type: single-node

# Learning setup only — do not disable security in production
xpack.security.enabled: false
xpack.security.http.ssl.enabled: false
```

With security disabled, `curl` commands need no credentials, which matches the examples used throughout this knowledge base.

## Step 4 — Start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
```

## Step 5 — Verify it works

Elasticsearch listens on **port 9200** by default:

```bash
curl 127.0.0.1:9200
```

A healthy node answers with a JSON banner:

```json
{
  "name": "ubuntu",
  "cluster_name": "elasticsearch",
  "version": {
    "number": "8.x.x"
  },
  "tagline": "You Know, for Search"
}
```

If you kept security enabled, authenticate instead: `curl -k -u elastic https://127.0.0.1:9200`.

## Alternative: Docker

If you prefer containers over a VM:

```bash
docker run -d --name elasticsearch -p 9200:9200 \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=false" \
  docker.elastic.co/elasticsearch/elasticsearch:8.14.0
```

## Troubleshooting

| Symptom | Likely cause / fix |
| --- | --- |
| Service dies immediately after start | Not enough RAM — give the VM 4 GB+, or cap the heap in `/etc/elasticsearch/jvm.options.d/` with `-Xms1g` / `-Xmx1g` |
| `curl: (7) Failed to connect` | Service not running (`systemctl status elasticsearch`) or wrong port/host binding |
| `curl: (52) Empty reply from server` | Security/TLS still enabled — use `https://` with `-k -u elastic`, or disable security as above |
| Startup extremely slow | Normal on first boot; check progress with `journalctl -u elasticsearch -f` |

## Key takeaways

- Elasticsearch installs cleanly from Elastic's APT repository and runs as a systemd service.
- Default HTTP endpoint: `127.0.0.1:9200`. Everything else in this knowledge base talks to that endpoint.
- Recent versions enable authentication and TLS by default; for a disposable learning VM it is common to switch them off, but that is never acceptable in production.

<div class="chapter-nav">
<a class="chapter-nav__item" href="001-intro.html"><span>Previous</span><strong>1. Introduction</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="002-windows-installation.html"><span>Next</span><strong>Windows companion: Installing the Elastic Stack</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 1</a></p>
