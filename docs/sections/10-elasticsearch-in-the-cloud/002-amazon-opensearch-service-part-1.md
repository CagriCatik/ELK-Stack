---
title: "2. Amazon OpenSearch Service, Part 1"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 10</div>

# 2. Amazon OpenSearch Service, Part 1



**Amazon OpenSearch Service** is AWS's fully managed service for deploying, securing, and scaling OpenSearch (and legacy Elasticsearch 7.x) clusters in the AWS Cloud. Instead of managing EC2 instances, EBS volumes, and `opensearch.yml` files by hand, you provision an **OpenSearch domain** and let AWS handle cluster bootstrapping, patching, and hardware replacement.

## Anatomy of an OpenSearch domain

In AWS terminology, a **domain** is synonymous with a managed OpenSearch cluster plus its endpoints and control-plane configuration. Every domain exposes:

- A **cluster API endpoint** (HTTPS on port `443`, not `9200`) for REST calls, indexing, and search.
- An **OpenSearch Dashboards endpoint** (`https://<domain-endpoint>/_dashboards`) for visualizations and dev tools.
- **Data nodes** (the hot tier), backed by instance store or Amazon EBS volumes.
- Optional **dedicated master nodes**, **UltraWarm nodes**, and **Cold storage** (covered in Chapter 114).

### Why dedicated master nodes matter

For small dev/test domains, you can run without dedicated master nodes—data nodes share cluster-management duties. For any production workload, **always enable 3 dedicated master nodes** (never 2, which cannot break a tie, and rarely 5 unless the cluster is massive):

- **Quorum stability:** Three dedicated masters tolerate the loss of one master node while maintaining a quorum of 2.
- **Isolation from heavy queries:** If a data node experiences a long garbage-collection pause or OOM from an expensive aggregation, dedicated masters keep cluster state, shard allocation, and leader election responsive.
- **Availability Zone (AZ) distribution:** Enable **Zone Awareness** across **3 AZs** (with 3 dedicated masters, one per AZ, and data nodes spread evenly across all 3 AZs) so an entire AZ outage leaves both master quorum and replica shards intact.

> **Warning.** Unlike self-managed clusters where you edit `elasticsearch.yml` directly, Amazon OpenSearch Service blocks direct access to most node-level config files and restricts certain `_cluster/settings` to protect the managed control plane.

## VPC access vs. public access

When creating a domain, one of the most consequential architectural decisions is network placement:

| Access mode | How it works | When to use it |
| :--- | :--- | :--- |
| **VPC access** | Places Elastic Network Interfaces (ENIs) inside your private VPC subnets; traffic stays on the AWS network. | **All production workloads.** Combine with Security Groups and AWS PrivateLink / VPC peering. |
| **Public access** | Exposes a public DNS endpoint reachable over the internet on HTTPS (`443`). | Quick sandboxes or public-facing read endpoints—*only* when locked down with IAM policies and FGAC. |

You cannot switch an existing domain directly between VPC and public access after creation without recreating/migrating the domain (though you can layer AWS PrivateLink VPC endpoints on top of VPC-hosted domains).

> **Tip.** If you deploy a domain inside a private VPC, remember that your browser cannot reach `_dashboards` directly from your laptop. Teams typically connect via a VPN, AWS Client VPN, an SSH/SSM bastion tunnel, or an Application Load Balancer / reverse proxy with Cognito authentication.

## Provisioning a domain with the AWS CLI

You can create domains via the AWS Console, Terraform/CloudFormation, or the AWS CLI. Here is a production-oriented `create-domain` command using OpenSearch 2.x, 3 dedicated masters across 3 AZs, encrypted EBS storage, and VPC placement:

```bash
aws opensearch create-domain \
  --domain-name logs-prod \
  --engine-version OpenSearch_2.11 \
  --cluster-config '{
    "InstanceType": "r6g.large.search",
    "InstanceCount": 3,
    "DedicatedMasterEnabled": true,
    "DedicatedMasterType": "m6g.large.search",
    "DedicatedMasterCount": 3,
    "ZoneAwarenessEnabled": true,
    "ZoneAwarenessConfig": {
      "AvailabilityZoneCount": 3
    }
  }' \
  --ebs-options '{
    "EBSEnabled": true,
    "VolumeType": "gp3",
    "VolumeSize": 200
  }' \
  --vpc-options '{
    "SubnetIds": ["subnet-0aaa1111", "subnet-0bbb2222", "subnet-0ccc3333"],
    "SecurityGroupIds": ["sg-0123456789abcdef0"]
  }' \
  --encryption-at-rest-options '{"Enabled": true}' \
  --node-to-node-encryption-options '{"Enabled": true}' \
  --domain-endpoint-options '{"EnforceHTTPS": true, "TLSSecurityPolicy": "Policy-Min-TLS-1-2-2019-07"}'
```

Once active, you can verify the cluster health through the HTTPS endpoint (signed with SigV4 or authenticated via Fine-Grained Access Control):

```bash
curl -s "https://vpc-logs-prod-abc123.us-east-1.es.amazonaws.com/_cluster/health?pretty"
```

## Divergence between OpenSearch and Elasticsearch

Although OpenSearch began as a fork of Elasticsearch 7.10, the two engines are no longer drop-in equivalents:

| Area | OpenSearch (Amazon OpenSearch Service) | Elasticsearch (Elastic 8.x / 9.x) |
| :--- | :--- | :--- |
| **License & Governance** | Apache 2.0, OpenSearch Software Foundation (Linux Foundation) | Elastic License 2.0 / SSPL / AGPLv3, Elastic-led |
| **UI** | OpenSearch Dashboards | Kibana (Lens, Canvas, Fleet, Maps) |
| **Query languages** | Query DSL, SQL, Piped Processing Language (PPL) | Query DSL, **ES\|QL** (piped query language) |
| **Lifecycle & Security** | **ISM** (Index State Management), OpenSearch Security plugin | **ILM** (Index Lifecycle Management), X-Pack Security |
| **Storage & Vector Search** | UltraWarm / Cold (S3), k-NN plugin (Faiss/NMSLIB/Lucene) | Searchable Snapshots (Frozen tier), `dense_vector` HNSW + BBQ |
| **Client compatibility** | Use `opensearch-py` / `@opensearch-project/opensearch` | Use `elasticsearch` 8.x+ official clients |

> **Warning.** Modern Elasticsearch 8.x/9.x official language clients perform a product-check handshake and **refuse to connect** to OpenSearch clusters. Always match your client library (`opensearch-py`, OpenSearch Java/JS clients) to the engine you run.

## Key takeaways

- An Amazon OpenSearch **domain** bundles the managed cluster, HTTPS endpoints (`443`), and OpenSearch Dashboards into a single AWS resource.
- Always enable **3 dedicated master nodes** and **3-AZ Zone Awareness** for production domains to protect cluster quorum and survive AZ failures.
- Prefer **VPC access** with security groups and encryption in transit/at rest over public endpoints.
- OpenSearch and Elasticsearch have diverged since 7.10 in query languages, lifecycle tooling, vector search internals, and client compatibility—treat them as distinct platforms.

<div class="chapter-nav">
<a class="chapter-nav__item" href="001-section-10-intro.html"><span>Previous</span><strong>1. Section 10 Intro</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="003-amazon-opensearch-service-part-2.html"><span>Next</span><strong>3. Amazon OpenSearch Service, Part 2</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 10</a></p>
