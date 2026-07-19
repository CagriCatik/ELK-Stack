# ELK Stack Learning Guide

A structured, hands-on knowledge base for learning Elasticsearch and the wider Elastic Stack—from installing a local node and designing mappings to Logstash pipelines, Kibana dashboards, operations, and cloud deployment.

The guide is built with [Zensical](https://zensical.org/) and published as a fast, searchable static site with responsive navigation and light/dark themes.

## What you will learn

| Section | Topics |
| --- | --- |
| 1. Installing and understanding Elasticsearch | Local installation, Elastic Stack architecture, REST APIs, inverted indices, TF/IDF, shards, and replicas |
| 2. Mapping and indexing data | Documents, mappings, analyzers, CRUD operations, bulk indexing, concurrency, and data modeling |
| 3. Searching with Elasticsearch | Query DSL, phrase and fuzzy matching, filters, pagination, sorting, partial matching, and search-as-you-type |
| 4. Importing data | Client scripts, Logstash, JDBC, CSV, JSON, S3, Kafka, and Apache Spark |
| 5. Aggregation | Buckets, metrics, histograms, and nested aggregations |
| 6. Using Kibana | Installation, Discover, Lens, dashboards, management, and Elasticsearch SQL |
| 7. Analyzing log data | Beats, Elastic Stack ingestion architecture, and Kibana log dashboards |
| 8. Elasticsearch operations | Shard strategy, index lifecycle management, hardware and heap sizing, monitoring, failover, snapshots, and rolling restarts |
| 9. Elasticsearch in the cloud | Amazon OpenSearch Service, Elastic Cloud, and managed deployment trade-offs |

The material is organized into more than 100 focused lesson pages, with chapter navigation, exercises, quizzes, and section wrap-ups.

## Quick start

You need Python 3 and `pip`. All remaining documentation dependencies are pinned in `requirements.txt`.

### Windows

The included helper creates the virtual environment, installs dependencies, and opens the development server:

```powershell
.\serve.ps1
```

Or run the steps manually:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
zensical serve --dev-addr localhost:8000 --open
```

### macOS and Linux

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
zensical serve --dev-addr localhost:8000 --open
```

The development site is available at `http://localhost:8000` and reloads when documentation files change.

## Build the static site

With the virtual environment active:

```bash
zensical build --clean
```

Zensical writes the generated site to `site/`. For the most consistent behavior, preview that directory through an HTTP server instead of opening `site/index.html` directly.

Every push to `main` also triggers the workflow in `.github/workflows/docs.yml`, which is configured to build the documentation and deploy it to GitHub Pages once Pages is enabled for the repository.

## Optional: install the Elastic Stack on Windows

The repository includes a PowerShell installer for Elasticsearch, Kibana, and Logstash. It downloads matching Windows ZIP packages from Elastic, verifies their SHA-512 checksums, extracts them beneath a common directory, and creates launcher scripts.

Run it from PowerShell:

```powershell
.\install-elastic.stack.ps1
```

Choose a different Stack version or destination when needed:

```powershell
.\install-elastic.stack.ps1 `
  -Version 9.4.3 `
  -InstallRoot D:\Elastic `
  -KeepArchives
```

The default destination is `C:\Elastic`. Existing installations are preserved unless you pass `-Force`.

After installation, start the components in order from the installation directory:

```powershell
.\start-elasticsearch.ps1
.\start-kibana.ps1
.\start-logstash.ps1 -f .\logstash-9.4.3\pipeline\console-demo.conf
```

For first-run security setup, enrollment, service configuration, and troubleshooting, see the [Windows installation companion](docs/sections/01-installing-and-understanding-elasticsearch/002-windows-installation.md).

## Repository layout

```text
.
├── .github/workflows/docs.yml       # GitHub Pages build and deployment
├── docs/
│   ├── index.md                     # Course landing page
│   ├── sections/                    # Lessons grouped into nine sections
│   └── stylesheets/extra.css        # Course-specific presentation
├── install-elastic.stack.ps1        # Verified Windows Stack installer
├── requirements.txt                 # Pinned documentation dependencies
├── serve.ps1                        # Windows development-server helper
├── site/                            # Generated static output
└── zensical.toml                    # Navigation and site configuration
```

## Contributing

Documentation lives in `docs/` as Markdown. To make a change:

1. Edit or add the relevant lesson.
2. Add new pages to the navigation in `zensical.toml`.
3. Run `zensical build --clean`.
4. Check the generated page, chapter navigation, code blocks, and internal links before opening a pull request.

Keep examples safe for local learning environments, clearly label production caveats, and avoid hard-coding version claims that will quickly become stale.

## Disclaimer

This is an independent learning resource and is not affiliated with or endorsed by Elastic. Elasticsearch, Kibana, Logstash, Beats, and Elastic are trademarks of Elasticsearch B.V.
