---
title: "112. Section 9 Intro"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 09</div>

# 112. Section 9 Intro



In Section 8, you learned what it takes to operate Elasticsearch yourself: sizing shards, tuning JVM heaps, managing hot-warm-cold lifecycles, taking snapshots, and recovering from node failures. Running a cluster in production is rewarding, but it also means owning OS patching, TLS certificate rotation, rolling upgrades, disk watermark emergencies, and 3 a.m. split-brain alerts.

Section 9 shifts focus from **self-managed operations** to **managed cloud services**. Instead of provisioning VMs and babysitting cluster state, you delegate infrastructure lifecycle management to a cloud control plane—while still owning data modeling, index lifecycle design, query performance, and access control.

## Why teams move to managed search in the cloud

Managed Elasticsearch and OpenSearch services do not eliminate operational responsibility, but they change *where* you spend your engineering time:

| Operational concern | Self-managed | Managed cloud service |
| :--- | :--- | :--- |
| OS patching, JVM upgrades, rolling restarts | You schedule and execute | Automated by the control plane |
| Hardware provisioning & AZ placement | You configure VMs, disks, and rack awareness | Selected via instance profiles or serverless tiers |
| TLS certificates & node-to-node encryption | You generate, distribute, and rotate certs | Provisioned and rotated automatically |
| Automated backups & snapshot plumbing | You configure S3/GCS plugins and Cron/SLM | Built-in automated snapshots (plus custom S3/GCS) |
| Shard sizing, mappings, and query tuning | **Still yours** | **Still yours** |
| Access policies, RBAC, and cost governance | **Still yours** | **Still yours** |

> **Note.** Moving to a managed service does *not* fix bad mappings, oversharding, or unbounded wildcard queries. A poorly designed index will still hit heap pressure or slow down searches—only now you pay the cloud provider per GB of RAM to absorb it.

## Two ecosystems: OpenSearch vs. Elastic Cloud

Before choosing a managed provider, it helps to understand why two distinct ecosystems exist today. In 2021, Elastic changed the license of Elasticsearch and Kibana from Apache 2.0 to a dual Elastic License / SSPL model. In response, AWS forked Elasticsearch 7.10 and Kibana 7.10 under the Apache 2.0 license to create **OpenSearch** and **OpenSearch Dashboards**.

Since that fork, the two codebases have diverged significantly:

- **Amazon OpenSearch Service** runs AWS-managed **OpenSearch** (and legacy Elasticsearch up to 7.10) deeply integrated with AWS IAM, VPCs, KMS, CloudWatch, and S3.
- **Elastic Cloud** runs **Elastic's** own Elasticsearch and Kibana across AWS, GCP, and Azure, giving you immediate access to Elastic-proprietary features such as **ES|QL**, **Kibana Lens**, **Searchable Snapshots** on object storage, **Elastic Agent & Fleet**, **APM**, **SIEM**, and **Elastic Cloud Serverless**.

## What this section covers

1. **[113. Amazon OpenSearch Service, Part 1](113-amazon-opensearch-service-part-1.html)** — Domains, dedicated master nodes, VPC vs. public access, provisioning via the AWS CLI, and how OpenSearch diverged from Elasticsearch.
2. **[114. Amazon OpenSearch Service, Part 2](114-amazon-opensearch-service-part-2.html)** — Hot, UltraWarm, and Cold storage tiers, Index State Management (ISM), IAM + Fine-Grained Access Control (FGAC), and automated vs. manual S3 snapshots.
3. **[115. The Elastic Cloud](115-the-elastic-cloud.html)** — Elastic Cloud Hosted (ESS) deployment profiles, autoscaling, Traffic Filters / PrivateLink, Elastic Cloud Serverless, built-in Observability & Security, and a three-way comparison against self-managed and Amazon OpenSearch.
4. **[116. Section 9 Wrapup](116-section-9-wrapup.html)** — A synthesis of cloud hosting trade-offs and a final wrap-up of the entire course.

<div class="chapter-nav">
<a class="chapter-nav__item" href="../08-elasticsearch-operations/111-section-8-wrapup.html"><span>Previous</span><strong>111. Section 8 Wrapup</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="113-amazon-opensearch-service-part-1.html"><span>Next</span><strong>113. Amazon OpenSearch Service, Part 1</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 9</a></p>
