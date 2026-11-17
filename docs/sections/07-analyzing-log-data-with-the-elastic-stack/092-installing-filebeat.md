---
title: "92. Installing FileBeat"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 07</div>

# 92. Installing FileBeat



With your architecture and security credentials in place, the next step is installing Filebeat on the host generating logs, configuring inputs and outputs, enabling modules, and loading the Elastic Stack assets.

## 1. Installing Filebeat

Install Filebeat from Elastic's official package repository so its version matches your Elasticsearch and Kibana version (Elastic requires Beats to be the same major/minor version or compatible within the same major version):

```bash
# Debian / Ubuntu (after adding the Elastic APT repository)
sudo apt-get update && sudo apt-get install -y filebeat

# RHEL / Rocky / CentOS (after adding the Elastic YUM repository)
sudo dnf install -y filebeat
```

For quick local testing on macOS or Linux without root packages, download and extract the official `.tar.gz` archive and run `./filebeat` from the extracted directory.

## 2. Configuring `filebeat.yml`

Filebeat's main configuration lives at `/etc/filebeat/filebeat.yml`. Use the modern **`filestream`** input (which replaces the deprecated `log` input with cleaner state tracking and built-in parsers) and point `output.elasticsearch` to your secured cluster:

```yaml
# /etc/filebeat/filebeat.yml
filebeat.inputs:
  - type: filestream
    id: app-json-logs
    enabled: true
    paths:
      - /var/log/myapp/*.log
    parsers:
      - ndjson:
          keys_under_root: true
          add_error_key: true

filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false

output.elasticsearch:
  hosts: ["https://127.0.0.1:9200"]
  api_key: "<id>:<api_key>"
  ssl.certificate_authorities: ["/etc/filebeat/http_ca.crt"]

setup.kibana:
  host: "https://127.0.0.1:5601"
  ssl.certificate_authorities: ["/etc/filebeat/http_ca.crt"]
```

> **Tip.** Every `filestream` input **must** have a unique `id`. Filebeat uses this `id` to track file offsets in `/var/lib/filebeat/registry`; changing the `id` causes Filebeat to re-read matching files from the beginning.

## 3. Enabling Filebeat modules

Filebeat modules package input paths, Elasticsearch Ingest Pipelines, and Kibana dashboards for common software. Enable `nginx` and `system`:

```bash
# List available and enabled modules
sudo filebeat modules list

# Enable nginx and system modules
sudo filebeat modules enable nginx system
```

If your logs live in non-default paths (or you are testing with sample log files), edit `/etc/filebeat/modules.d/nginx.yml`:

```yaml
- module: nginx
  access:
    enabled: true
    var.paths: ["/var/log/nginx/access.log*"]
  error:
    enabled: true
    var.paths: ["/var/log/nginx/error.log*"]
```

## 4. Loading assets with `filebeat setup`

Before starting Filebeat as a daemon, run `filebeat setup` **once** from a host that can reach both Elasticsearch and Kibana. This creates the index templates, Index Lifecycle Management (ILM) policies, ingest pipelines for enabled modules, and Kibana dashboards:

```bash
# Validate syntax and connectivity first
sudo filebeat test config
sudo filebeat test output

# Load templates, ILM policies, ingest pipelines, and dashboards
sudo filebeat setup -e
```

Once `setup` completes, enable and start the Filebeat service:

```bash
sudo systemctl enable --now filebeat
sudo systemctl status filebeat
```

## Key takeaways

- Use the **`filestream`** input with a unique `id` per input rather than the legacy `log` input.
- Enable built-in **modules** (`nginx`, `system`, etc.) to get automatic ECS-compliant parsing via Elasticsearch Ingest Pipelines.
- Run **`filebeat test config`**, **`filebeat test output`**, and **`filebeat setup -e`** once before starting the service so templates, pipelines, and dashboards are in place.
- Authenticate Filebeat with a scoped **API key** and verify the Elasticsearch CA certificate via `ssl.certificate_authorities`.

<div class="chapter-nav">
<a class="chapter-nav__item" href="091-x-pack-security.html"><span>Previous</span><strong>91. X-Pack Security</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="093-analyzing-logs-with-kibana-dashboards.html"><span>Next</span><strong>93. Analyzing Logs with Kibana Dashboards</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 7</a></p>
