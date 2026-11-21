---
title: "4. The Elastic Cloud"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 10</div>

# 4. The Elastic Cloud



**Elastic Cloud** is Elastic's official managed platform for running the Elastic Stack (Elasticsearch, Kibana, Fleet/Elastic Agent, Logstash Integrations, APM, and Security). Unlike Amazon OpenSearch Service, which runs the OpenSearch fork exclusively on AWS, Elastic Cloud runs **upstream Elasticsearch 8.x/9.x** across **AWS, Google Cloud (GCP), and Microsoft Azure**—all managed from a single control plane.

Elastic Cloud is offered in two primary models:

1. **Elastic Cloud Hosted (Elasticsearch Service / ESS):** Managed clusters where you choose cloud region, hardware profile, and tier sizes.
2. **Elastic Cloud Serverless:** A fully decoupled compute-and-object-storage architecture with no cluster sizing, shard count tuning, or node management.

## Elastic Cloud Hosted (ESS): Profiles, tiers, and autoscaling

When provisioning an ESS deployment, you select a **deployment profile** tailored to your workload's RAM-to-disk-to-CPU ratio:

| Deployment profile | Hardware characteristics | Ideal workload |
| :--- | :--- | :--- |
| **General Purpose** | Balanced CPU, memory, and NVMe SSD | Mixed search, dashboards, and moderate log ingest |
| **Storage Optimized** | High disk-to-RAM ratio | Log/metric retention where query concurrency is lower |
| **Compute / CPU Optimized** | High vCPU-to-RAM ratio | Heavy full-text search, complex queries, or ingest pipelines |
| **Memory Optimized** | High RAM-to-disk ratio | Large `dense_vector` HNSW graphs, heavy aggregations, hot caches |
| **I/O Optimized** | High-throughput local NVMe SSDs | High-volume indexing, observability, and low-latency search |

### Hot, Warm, Cold, and Frozen (Searchable Snapshots)

Elastic Cloud natively supports ILM across four data tiers. Where Amazon OpenSearch uses UltraWarm and Cold, Elastic Cloud uses **Searchable Snapshots** on cloud object storage (S3, GCS, or Azure Blob) for its **Cold** and **Frozen** tiers:

- **Cold tier:** Mounts a snapshot with a local disk cache for fast historical queries without paying for replica nodes (durability comes from object storage).
- **Frozen tier:** Queries object storage directly via a stateless frozen node with a small shared cache, letting you search petabytes of archived logs in seconds at object-storage prices.

### Autoscaling and Traffic Filters

- **Autoscaling:** Instead of manually resizing nodes before a traffic spike, you enable autoscaling on hot, warm, cold, or ML tiers with min/max bounds. Elastic Cloud automatically adds capacity when disk usage, memory pressure, or queue depth crosses thresholds—and scales back down when demand drops.
- **Traffic Filters:** By default, Elastic Cloud endpoints are protected by TLS and authentication, and you can restrict ingress using **Traffic Filters**:
  - **IP allowlists** (CIDR blocks for office VPNs or NAT gateways)
  - **Private connectivity** via **AWS PrivateLink**, **GCP Private Service Connect**, or **Azure Private Link** so traffic never traverses the public internet.

## Elastic Cloud Serverless

**Elastic Cloud Serverless** removes the cluster abstraction altogether. Instead of choosing instance types, AZ counts, or primary/replica shard counts, you create a **Serverless Project** (Search, Observability, or Security):

- **Stateless indexing & search:** Compute scales automatically and independently from object storage.
- **Zero-downtime upgrades:** Elastic continuously rolls out engine improvements behind the scenes—you never schedule a major-version upgrade.
- **Pay-for-what-you-use:** Billing is based on ingest volume, storage, and search compute (VCUs) rather than idle node hours.

## Built-in Elastic Stack capabilities

Because Elastic Cloud is built by Elastic, every deployment includes the full commercial feature set out of the box (depending on subscription tier: Standard, Gold, Platinum, or Enterprise):

- **Kibana Lens & ES\|QL:** Drag-and-drop visualizations plus Elastic's piped query language (`FROM logs-* | WHERE status >= 500 | STATS count() BY service`).
- **Elastic Agent & Fleet:** Centralized management for collecting logs, metrics, and traces from thousands of hosts without SSHing into servers to edit Filebeat configs.
- **APM & Distributed Tracing:** Native OpenTelemetry (OTLP) ingestion and service maps inside Kibana.
- **Elastic Security (SIEM):** Prebuilt detection rules, timeline investigation, and endpoint security.
- **Vector & Hybrid Search:** Native `dense_vector` HNSW with Better Binary Quantization (BBQ), Reciprocal Rank Fusion (RRF), and Elastic's **ELSER** sparse-vector semantic search model.

### Connecting to Elastic Cloud

Every Elastic Cloud cluster exposes an HTTPS endpoint on port `443` (or `9243` for legacy compatibility) and recommends **API keys** for programmatic access:

```bash
# Querying an Elastic Cloud deployment using an API key
curl -s -X GET "https://my-deployment.es.us-east-1.aws.found.io:443/movies/_search?pretty" \
  -H "Authorization: ApiKey <base64-encoded-api-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "match": { "title": "Matrix" }
    }
  }'
```

## Comparing Self-Managed vs. Amazon OpenSearch vs. Elastic Cloud

| Dimension | Self-Managed (ECE / ECK / VMs) | Amazon OpenSearch Service | Elastic Cloud (ESS / Serverless) |
| :--- | :--- | :--- | :--- |
| **Cloud portability** | Any cloud, on-prem, air-gapped | AWS only | AWS, GCP, and Azure |
| **Control plane** | You manage (or ECK on Kubernetes) | AWS Console / CLI / Terraform | Elastic Cloud Console / API / Terraform |
| **Engine** | Elasticsearch or OpenSearch | OpenSearch (and legacy ES <= 7.10) | Latest Elasticsearch 8.x / 9.x |
| **Cold/Archive search** | Searchable Snapshots (with Enterprise license) | UltraWarm + Cold (S3) | Searchable Snapshots (Cold & Frozen) |
| **Serverless option** | No | OpenSearch Serverless | Yes (Elastic Cloud Serverless) |
| **AWS IAM / SigV4 native** | Manual | First-class native integration | Via Traffic Filters / PrivateLink + API keys / OIDC |
| **Kibana Lens, ES\|QL, Fleet, APM** | Included (Elastic Stack) | Not available (uses OpenSearch Dashboards / PPL) | First-class, built-in |

## Key takeaways

- **Elastic Cloud Hosted (ESS)** runs the full Elastic Stack on **AWS, GCP, and Azure**, offering workload-specific deployment profiles, autoscaling, and **Searchable Snapshots** on object storage.
- **Traffic Filters** (IP allowlists and PrivateLink / Private Service Connect) lock down Elastic Cloud endpoints to private networks.
- **Elastic Cloud Serverless** eliminates shard sizing and node management by decoupling compute from object storage.
- Choose **Amazon OpenSearch Service** when deep AWS IAM/VPC integration and Apache 2.0 OpenSearch matter most; choose **Elastic Cloud** when you want multi-cloud portability, Serverless, and native Elastic Stack features like ES|QL, Lens, Fleet, APM, and SIEM.

<div class="chapter-nav">
<a class="chapter-nav__item" href="003-amazon-opensearch-service-part-2.html"><span>Previous</span><strong>3. Amazon OpenSearch Service, Part 2</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="005-section-10-wrapup.html"><span>Next</span><strong>5. Section 10 Wrapup</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 10</a></p>
