---
title: "91. X-Pack Security"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 07</div>

# 91. X-Pack Security



Before shipping production logs into Elasticsearch, you need to lock down who can read, write, and administer the cluster. **X-Pack Security** provides encryption in transit (TLS), authentication, role-based access control (RBAC), and API keys.

> **8.x/9.x Security by Default.** Starting with Elasticsearch 8.0, X-Pack Security is **enabled and auto-configured on first startup**. Elasticsearch generates a local CA, configures TLS on both HTTP and transport layers, creates the `elastic` superuser password, and prints an enrollment token for Kibana and additional nodes.

## TLS: Transport vs. HTTP layers

Elasticsearch separates network encryption into two distinct layers in `elasticsearch.yml`:

| Layer | Port | Purpose | Key `elasticsearch.yml` settings |
| :--- | :--- | :--- | :--- |
| **Transport** | `9300` | Node-to-node cluster communication & shard replication | `xpack.security.transport.ssl.enabled: true`, `verification_mode: certificate` |
| **HTTP** | `9200` | Client, Kibana, Filebeat, and Logstash REST traffic | `xpack.security.http.ssl.enabled: true`, `keystore.path` or `certificate`/`key` |

Never disable transport TLS in multi-node clusters—any node that can join the transport layer has full cluster access.

## Built-in users and password management

Elasticsearch includes reserved built-in users for stack components:

- **`elastic`**: Superuser with full cluster and data access. Use it for initial administration, **not** inside Filebeat, Logstash, or application configs.
- **`kibana_system`**: Service account used by Kibana to communicate with Elasticsearch (not for human login).
- **`logstash_system`** / **`beats_system`**: Used by Logstash and Beats for monitoring data.

To reset a built-in user's password in **8.x/9.x**:

```bash
# Interactive reset for the elastic superuser
/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic

# Reset kibana_system with an auto-generated password
/usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system -b
```

*(In Elastic Stack 7.x, passwords were initialized once with `bin/elasticsearch-setup-passwords interactive` or `auto`.)*

## Role-Based Access Control (RBAC) and API Keys

Follow the principle of least privilege: create dedicated roles for log shippers and analysts, and authenticate shippers with **API keys** rather than shared passwords.

### 1. Create a least-privilege role for Filebeat

```bash
curl -k -u elastic:changeme -X POST "https://127.0.0.1:9200/_security/role/filebeat_nginx_writer" \
  -H "Content-Type: application/json" \
  -d '{
    "cluster": ["monitor", "manage_ilm", "manage_ingest_pipelines"],
    "indices": [
      {
        "names": ["filebeat-*"],
        "privileges": ["create_doc", "create_index", "view_index_metadata", "manage"]
      }
    ]
  }'
```

### 2. Generate a scoped API key

```bash
curl -k -u elastic:changeme -X POST "https://127.0.0.1:9200/_security/api_key" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "filebeat-web01",
    "role_descriptors": {
      "filebeat_writer": {
        "cluster": ["monitor"],
        "indices": [
          {
            "names": ["filebeat-*"],
            "privileges": ["create_doc", "auto_configure"]
          }
        ]
      }
    }
  }'
```

The response returns an `id` and `api_key`, combined as `id:api_key` in `filebeat.yml` (`api_key: "<id>:<api_key>"`). API keys can be rotated or invalidated per host (`DELETE /_security/api_key`) without touching other shippers.

## Key takeaways

- **X-Pack Security is enabled by default** in Elastic Stack 8.x/9.x, configuring TLS and the `elastic` superuser automatically.
- **Transport TLS (`9300`)** protects node-to-node traffic; **HTTP TLS (`9200`)** protects REST clients, Kibana, and shippers.
- Use `elasticsearch-reset-password` (8.x+) to manage built-in user credentials, and avoid embedding the `elastic` superuser in shipper configs.
- Prefer **RBAC roles** and per-host **API keys** so compromised credentials can be revoked cleanly without cluster-wide disruption.

<div class="chapter-nav">
<a class="chapter-nav__item" href="090-filebeat-and-the-elastic-stack-architecture.html"><span>Previous</span><strong>90. FileBeat and the Elastic Stack Architecture</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="092-installing-filebeat.html"><span>Next</span><strong>92. Installing FileBeat</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 7</a></p>
