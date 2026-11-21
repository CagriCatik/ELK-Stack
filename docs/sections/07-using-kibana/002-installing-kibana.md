---
title: "2. Installing Kibana"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 07</div>

# 2. Installing Kibana

Kibana is a Node.js-based web application that connects to Elasticsearch over HTTP(S) and stores its own metadata (dashboards, Data Views, saved searches, and UI state) inside internal Elasticsearch system indices (such as `.kibana_*`).

## Version compatibility

Kibana **must** match the minor version of your Elasticsearch cluster (for example, Kibana `8.15.x` with Elasticsearch `8.15.x`, or `9.x` with `9.x`). A version mismatch prevents Kibana from starting or causes Saved Objects migrations to fail.

## Installing Kibana

On Debian/Ubuntu with the Elastic APT repository configured:

```bash
sudo apt-get update && sudo apt-get install kibana
```

On RHEL/CentOS/Rocky Linux with `dnf`:

```bash
sudo dnf install kibana
```

Or with Docker on the same network as Elasticsearch:

```bash
docker run -d --name kibana --net elastic \
  -p 5601:5601 \
  docker.elastic.co/kibana/kibana:8.15.0
```

## Configuring `kibana.yml`

The main configuration file lives at `/etc/kibana/kibana.yml` (or `/usr/share/kibana/config/kibana.yml` in tar/Docker distributions).

| Setting | Default | Purpose |
| :--- | :--- | :--- |
| `server.port` | `5601` | HTTP port Kibana listens on |
| `server.host` | `"localhost"` | Network interface to bind (`"0.0.0.0"` for remote access) |
| `elasticsearch.hosts` | `["http://localhost:9200"]` | One or more Elasticsearch node URLs |
| `elasticsearch.serviceAccountToken` | *(unset)* | Service account token for authenticating to secured Elasticsearch |
| `server.publicBaseUrl` | *(unset)* | External URL used for links, alerts, and SSO redirects |

A minimal development `kibana.yml` (without TLS/security) looks like:

```yaml
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://127.0.0.1:9200"]
```

## Connecting to a secured cluster (8.x / 9.x)

Since Elasticsearch 8.0, **X-Pack Security and TLS are enabled by default**. You have two standard ways to connect Kibana:

1. **Enrollment token (interactive setup — recommended for quick starts):**
   Generate a short-lived enrollment token on the Elasticsearch node:

   ```bash
   /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
   ```

   Start Kibana, open `http://<host>:5601` in a browser, and paste the token. Kibana automatically writes the TLS trust configuration and a service account token into `kibana.yml` / its keystore.

2. **Service account token (automated / declarative setup):**
   Create a token for the built-in `elastic/kibana` service account:

   ```bash
   /usr/share/elasticsearch/bin/elasticsearch-service-tokens create elastic/kibana kibana-token
   ```

   Then reference it in `/etc/kibana/kibana.yml` (or store it in `kibana-keystore` so it is not plaintext on disk):

   ```yaml
   elasticsearch.hosts: ["https://127.0.0.1:9200"]
   elasticsearch.serviceAccountToken: "AAEAAWVsYXN0aWMva2liYW5hL2tpYmFuYS10b2tlbjo..."
   elasticsearch.ssl.certificateAuthorities: ["/etc/kibana/certs/http_ca.crt"]
   ```

> **Never use the `elastic` superuser credentials in `kibana.yml`.** Elasticsearch explicitly blocks using the `elastic` superuser for Kibana's internal connection; always use an enrollment token or the `elastic/kibana` service account token.

## Starting and verifying Kibana

Enable and start the systemd service:

```bash
sudo systemctl enable --now kibana
sudo systemctl status kibana
```

Wait 20–40 seconds on first boot while Kibana runs Saved Objects migrations, then verify it is healthy:

```bash
curl -s http://127.0.0.1:5601/api/status | head -c 300
```

Once `status.overall.level` reports `"available"`, open `http://127.0.0.1:5601` in your browser.

## Key takeaways

- Kibana listens on port `5601` by default and persists its state in internal `.kibana_*` indices inside Elasticsearch.
- Always match Kibana's version to your Elasticsearch cluster version.
- In Elasticsearch 8.x/9.x, connect Kibana using an **enrollment token** or an `elastic/kibana` **service account token**, never the `elastic` superuser.

<div class="chapter-nav">
<a class="chapter-nav__item" href="001-section-7-intro.html"><span>Previous</span><strong>1. Section 7 Intro</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="003-playing-with-kibana.html"><span>Next</span><strong>3. Playing with Kibana</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 7</a></p>
