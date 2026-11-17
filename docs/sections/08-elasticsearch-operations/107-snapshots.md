---
title: "107. Snapshots"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 08</div>

# 107. Snapshots



Replicas protect you from a node crash, **not** from accidental `DELETE /_all`, bad mappings, or cluster-wide corruption. For true disaster recovery, you need **Snapshots** stored in an external repository.

> **Warning.** Never back up Elasticsearch by copying its `data/` directory with `rsync` or `tar` while nodes are running—Lucene files are constantly mutating, and a filesystem copy produces a corrupt, unrecoverable index. Always use the `_snapshot` API.

## How Incremental Snapshots Work

Elasticsearch snapshots are **incremental at the Lucene segment level**:
- The first snapshot copies all segments of your indices to the repository.
- Subsequent snapshots check which immutable segments already exist in the repository and **only upload newly created segments**.
- Deleting an old snapshot is safe: Elasticsearch tracks segment references and only deletes segments no longer needed by any remaining snapshot.

## Step 1: Register a Snapshot Repository

### Shared Filesystem (`fs`) Repository
Every master and data node must mount the same shared path (e.g., NFS) and list it in `elasticsearch.yml`:

```yaml
# elasticsearch.yml (on all master and data nodes)
path.repo: ["/mnt/es_backups"]
```

Then register the repository via the API:

```bash
curl -X PUT "http://127.0.0.1:9200/_snapshot/fs_backups" \
  -H "Content-Type: application/json" \
  -d '{
  "type": "fs",
  "settings": {
    "location": "/mnt/es_backups",
    "compress": true
  }
}'
```

### Amazon S3 (`s3`) Repository
In cloud deployments, object storage (S3, GCS, Azure Blob) is the standard choice. Install/enable `repository-s3`, store credentials in the `elasticsearch-keystore`, and register:

```bash
curl -X PUT "http://127.0.0.1:9200/_snapshot/s3_backups" \
  -H "Content-Type: application/json" \
  -d '{
  "type": "s3",
  "settings": {
    "bucket": "prod-elk-snapshots",
    "region": "us-east-1",
    "base_path": "clusters/prod-elk"
  }
}'
```

Verify any repository across all nodes with `POST /_snapshot/s3_backups/_verify`.

## Step 2: Take a Snapshot

Take an asynchronous snapshot of specific indices (or omit `indices` to snapshot the entire cluster, including cluster state):

```bash
curl -X PUT "http://127.0.0.1:9200/_snapshot/s3_backups/snap-2026-11-17?wait_for_completion=false" \
  -H "Content-Type: application/json" \
  -d '{
  "indices": "movies,logs-*",
  "ignore_unavailable": true,
  "include_global_state": false
}'
```

Check progress with `GET /_snapshot/s3_backups/snap-2026-11-17/_status`.

## Step 3: Restore from a Snapshot

You can restore all indices or selectively restore and rename a single index (for example, to inspect yesterday's data alongside today's live index):

```bash
curl -X POST "http://127.0.0.1:9200/_snapshot/s3_backups/snap-2026-11-17/_restore" \
  -H "Content-Type: application/json" \
  -d '{
  "indices": "movies",
  "rename_pattern": "(.+)",
  "rename_replacement": "restored-$1"
}'
```

## Key takeaways

- Always back up Elasticsearch with the **`_snapshot` API**—never with raw filesystem copies of `path.data`.
- Snapshots are **incremental at the Lucene segment level**, making frequent backups fast and storage-efficient.
- Use **shared filesystems (`fs`)** with `path.repo` on-prem or **object storage (`s3`, `gcs`, `azure`)** in the cloud.
- Test restores regularly using `rename_pattern` / `rename_replacement` so you can verify backups without overwriting live indices.

<div class="chapter-nav">
<a class="chapter-nav__item" href="106-index-design-changes-grouping-splitting-and-shrinking-indices.html"><span>Previous</span><strong>106. Index Design Changes (Grouping, Splitting, and Shrinking Indices)</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="108-snapshot-lifecycle-management.html"><span>Next</span><strong>108. Snapshot Lifecycle Management</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 8</a></p>
