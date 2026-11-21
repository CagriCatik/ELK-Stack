---
title: "6. Installing Logstash"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 6. Installing Logstash

Before building pipelines, you need Logstash installed and aligned with your Elasticsearch version. Keeping Logstash on the same major/minor version as Elasticsearch ensures plugin compatibility and consistent Elastic Common Schema (ECS) behavior.

> **Note.** Modern Logstash packages (8.x and 9.x) bundle a compatible OpenJDK distribution inside the package, so you no longer need to install or manage a separate system Java runtime unless you explicitly override `LS_JAVA_HOME`.

## Installation options

### Debian / Ubuntu (APT)

Add the Elastic GPG key and APT repository (if not already configured from installing Elasticsearch), then install Logstash:

```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update && sudo apt-get install -y logstash
```

### RHEL / CentOS / Rocky (RPM / DNF)

```bash
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
# With /etc/yum.repos.d/elastic.repo configured for 8.x:
sudo dnf install -y logstash
```

### Archive / macOS / Docker

For local development or macOS, download the `.tar.gz` archive from Elastic's downloads page, or run the official Docker image:

```bash
docker pull docker.elastic.co/logstash/logstash:8.15.0
```

## Important directories and files

When installed via APT or RPM, Logstash separates binaries from configuration and state:

| Path | Purpose |
| :--- | :--- |
| `/usr/share/logstash/bin/logstash` | Main Logstash executable (`logstash-plugin` lives alongside it) |
| `/etc/logstash/logstash.yml` | Global daemon settings (node name, queue type, DLQ, API port `9600`) |
| `/etc/logstash/pipelines.yml` | Defines multiple isolated pipelines when running as a service |
| `/etc/logstash/conf.d/` | Default directory for `.conf` pipeline files |
| `/etc/logstash/jvm.options` | JVM heap size (`-Xms` / `-Xmx`, typically set to 50% of available RAM, max ~4–8 GB) |
| `/var/lib/logstash/` | Persistent state (`sincedb` files, persistent queue data, dead-letter queue) |
| `/var/log/logstash/` | Logstash service logs (`logstash-plain.log`) |

## Verifying the installation

Check the installed version and inspect bundled plugins:

```bash
/usr/share/logstash/bin/logstash --version
/usr/share/logstash/bin/logstash-plugin list | grep -E "jdbc|s3|grok|elasticsearch"
```

If you are installing on a server with limited memory (for example, a 2 GB lab VM), adjust `/etc/logstash/jvm.options` before starting the service so the JVM does not compete with Elasticsearch for RAM:

```text
-Xms1g
-Xmx1g
```

## Key takeaways

- Match Logstash's major/minor version to your Elasticsearch cluster.
- Logstash 8.x/9.x bundles its own JDK, avoiding Java version mismatches.
- Know the split between `/etc/logstash/` (config), `/usr/share/logstash/` (binaries/plugins), and `/var/lib/logstash/` (persistent state like `sincedb`).

<div class="chapter-nav">
<a class="chapter-nav__item" href="005-introducing-logstash.html"><span>Previous</span><strong>5. Introducing Logstash</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="007-running-logstash.html"><span>Next</span><strong>7. Running Logstash</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
