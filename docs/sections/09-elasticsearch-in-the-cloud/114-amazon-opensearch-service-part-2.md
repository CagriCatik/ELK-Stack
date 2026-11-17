---
title: "114. Amazon OpenSearch Service, Part 2"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 09</div>

# 114. Amazon OpenSearch Service, Part 2



Once an Amazon OpenSearch domain is provisioned, three operational pillars determine whether it stays fast, affordable, and secure: **storage tiering** (UltraWarm and Cold), **access control** (IAM + Fine-Grained Access Control), and **backups** (automated vs. manual S3 snapshots).

## Storage tiering: Hot, UltraWarm, and Cold

Paying for EBS-backed data nodes to hold six months of rarely queried logs quickly becomes expensive. Amazon OpenSearch Service solves this with three storage tiers:

| Tier | Backing storage | Behavior & latency | Best used for |
| :--- | :--- | :--- | :--- |
| **Hot** | EBS or instance store on data nodes | Read/write, millisecond queries, active indexing | Recent logs, active search indices, high-QPS workloads |
| **UltraWarm** | Amazon S3 + local NVMe read cache | **Read-only** indices, seconds-level latency, ~90% cheaper per GB than hot | Compliance logs, 30–180 day analytics, historical dashboards |
| **Cold** | Amazon S3 (detached from compute) | Not searchable until **attached** to UltraWarm nodes on demand | Multi-year archival data queried only during audits or incidents |

UltraWarm nodes still run as managed instances in your domain (typically 2 or more for availability), acting as a stateless compute/cache layer in front of S3. Cold storage costs only S3 storage fees until you re-attach an index to UltraWarm.

### Automating transitions with Index State Management (ISM)

In OpenSearch, **Index State Management (ISM)** plays the same role as ILM in Elasticsearch. You attach an ISM policy to an index template so indices automatically migrate from `hot` → `warm` → `cold` → `delete`:

```json
PUT _plugins/_ism/policies/logs_lifecycle_policy
{
  "policy": {
    "description": "Move logs from hot to UltraWarm after 7 days, delete after 90 days",
    "default_state": "hot",
    "states": [
      {
        "name": "hot",
        "transitions": [
          {
            "state_name": "warm",
            "conditions": { "min_index_age": "7d" }
          }
        ]
      },
      {
        "name": "warm",
        "actions": [
          { "warm_migration": {} }
        ],
        "transitions": [
          {
            "state_name": "delete",
            "conditions": { "min_index_age": "90d" }
          }
        ]
      },
      {
        "name": "delete",
        "actions": [
          { "delete": {} }
        ]
      }
    ]
  }
}
```

> **Note.** Because UltraWarm indices are **read-only**, ensure your index rollover happens *before* `warm_migration` runs, and avoid policies that try to update or delete individual documents inside warm indices.

## IAM and Fine-Grained Access Control (FGAC)

Amazon OpenSearch Service enforces security in three layers:

1. **Network layer:** VPC subnets and Security Groups (who can reach port `443`).
2. **Domain access policy (IAM):** Resource-based JSON policies attached to the domain, controlling which AWS IAM principals (users, roles, Lambda functions, EC2 instances) can call the domain's HTTP endpoints. Requests using IAM credentials must be **SigV4-signed**.
3. **Fine-Grained Access Control (FGAC):** Built on the OpenSearch Security plugin, FGAC adds **index-level, document-level, and field-level security** plus multi-tenant Dashboards spaces.

With FGAC enabled, a request must pass *both* the IAM domain policy and FGAC role mapping. You can map an IAM Role ARN directly to an OpenSearch backend role (such as `all_access` or a custom `logs_reader` role), or use an internal user database / SAML 2.0 / Amazon Cognito for human users logging into OpenSearch Dashboards.

```bash
# Calling an IAM-protected domain with curl 7.75+ native AWS SigV4 signing
curl --aws-sigv4 "aws:amz:us-east-1:es" \
  --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
  -H "x-amz-security-token: $AWS_SESSION_TOKEN" \
  "https://vpc-logs-prod-abc123.us-east-1.es.amazonaws.com/_cat/indices?v"
```

> **Warning.** Never leave a domain access policy wide open (`"Principal": {"AWS": "*"}` without conditions) on a public endpoint, even if FGAC is enabled. Defense in depth means locking down the network, the IAM policy, *and* FGAC roles.

## Automated vs. manual snapshots to S3

Every Amazon OpenSearch domain takes **automated snapshots** hourly (or daily depending on engine/configuration) and retains them for **14 days** in an AWS-managed S3 bucket at no extra charge. Automated snapshots are great for emergency disaster recovery, *but they cannot be used to migrate data to another AWS account, another region, or a self-managed cluster*.

For cross-region migration, blue/green domain upgrades, or long-term retention, configure **manual snapshots** to your own S3 bucket:

1. Create an S3 bucket in the same region as your domain.
2. Create an IAM role (`OpenSearchSnapshotRole`) with `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`, and `s3:ListBucket` permissions on that bucket, trusting `opensearchservice.amazonaws.com` (and `es.amazonaws.com`).
3. Register the repository using a SigV4-signed `PUT _snapshot/<repo_name>` request (this requires `iam:PassRole` permission on your caller):

```json
PUT _snapshot/my-s3-backups
{
  "type": "s3",
  "settings": {
    "bucket": "company-opensearch-snapshots-us-east-1",
    "base_path": "logs-prod",
    "region": "us-east-1",
    "role_arn": "arn:aws:iam::123456789012:role/OpenSearchSnapshotRole"
  }
}
```

4. Trigger a snapshot on demand (or schedule it via Snapshot Management / EventBridge + Lambda):

```bash
curl --aws-sigv4 "aws:amz:us-east-1:es" \
  --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
  -X PUT "https://vpc-logs-prod-abc123.us-east-1.es.amazonaws.com/_snapshot/my-s3-backups/snap-2026-11-17?wait_for_completion=false"
```

## Key takeaways

- Use **Hot** (EBS) for active writes, **UltraWarm** (S3 + NVMe cache) for cost-effective read-only analytics, and **Cold** (detached S3) for long-term archival, automated via **ISM policies**.
- Combine **IAM domain policies** (SigV4 authentication) with **Fine-Grained Access Control (FGAC)** for index-, document-, and field-level authorization.
- Rely on **automated snapshots** for 14-day point-in-time recovery, and register a **manual S3 snapshot repository** whenever you need cross-region backups, long-term retention, or domain-to-domain migrations.

<div class="chapter-nav">
<a class="chapter-nav__item" href="113-amazon-opensearch-service-part-1.html"><span>Previous</span><strong>113. Amazon OpenSearch Service, Part 1</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="115-the-elastic-cloud.html"><span>Next</span><strong>115. The Elastic Cloud</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 9</a></p>
