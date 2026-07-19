---
title: "8. How Elasticsearch Scales"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 01</div>

# 8. How Elasticsearch Scales

This chapter covers Elasticsearch's architecture: how an index is spread across an entire cluster of machines, and how primary and replica shards keep the cluster running when nodes fail.

## Shards: the scaling trick

Elasticsearch's main scaling mechanism is that **an index is split into shards, and every shard is a self-contained Lucene instance**. With a cluster of computers, shards are spread across multiple machines; when you need more capacity, you add machines and distribute the shards across them.

Routing is deterministic: when you talk to any server in the cluster, Elasticsearch **hashes the document's ID to a shard number**, so it can instantly work out which shard owns a given document and redirect the request to the right node — no lookup table needed.

```text
Index ──► shard 0 ─ node A
      ├─► shard 1 ─ node B
      └─► shard 2 ─ node C        hash(document ID) → owning shard
```

## Primary and replica shards

Machines fail — a cluster must survive that. Elasticsearch's answer is the split between **primary shards** (where writes go first) and **replica shards** (copies that can also serve reads).

A **node** is one installation of Elasticsearch — usually one node per physical server (more is possible, but unusual). Consider an index with **2 primary shards and 2 replicas** on 3 nodes; Elasticsearch lays this out for you automatically:

```text
Node 1              Node 2              Node 3
├─ Primary 1        ├─ Replica 0        ├─ Replica 0
└─ Replica 1        └─ Replica 1        └─ Primary 0
```

### Failover in action

- **Node 1 dies** (disk failure, burned-out power supply...): primary 1 and a replica of 0 are lost — but replicas of shard 1 exist on nodes 2 and 3. Elasticsearch **elects one of those replicas as the new primary**. The cluster keeps accepting writes and serving reads until the lost capacity is restored.
- **Node 3 dies**: primary 0 is lost, but replicas sit on nodes 1 and 2; one is promoted, and the cluster carries on.
- The design even tolerates **multiple node failures** in the right configuration — the cluster keeps working as long as at least one copy of every shard survives.

As an end user, a node failure is invisible: the design goal is that you never notice.

Two operational notes from this design:

- Prefer an **odd number of nodes** for resiliency (it avoids split-brain situations in master elections).
- **Round-robin your application's requests** across all nodes — either in the application or via a load balancer — so no single node absorbs all the initial traffic.

## Write path and read path

- **Writes** are routed to the **primary shard** that owns the document; from there the data is automatically replicated to that shard's replicas.
- **Reads** can be served by the **primary or any replica**, which spreads read load across the cluster.

The consequence: **adding replicas increases read capacity**, while **write capacity is bottlenecked by the number of primary shards**.

## Choosing shard counts up front

The number of primary shards is fixed **when the index is created** — you cannot simply raise it later. It is defined at creation time:

```bash
curl -H "Content-Type: application/json" -XPUT '127.0.0.1:9200/testindex' -d '
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1
  }
}'
```

This is less painful than it sounds:

- Many Elasticsearch workloads are **read-heavy** (a Wikipedia-style search site gets far more searches than new documents), and **replicas can be added later** at any time for more read capacity.
- If you truly need more write capacity, you can **re-index your data into a new index** with more primaries and copy it over.
- Still, plan ahead: provision enough primary shards up front for the growth you can reasonably expect. (Newer Elasticsearch versions also offer the `_split` and `_shrink` APIs, which relax this limitation somewhat — but sizing correctly at creation remains best practice.)

## The shard math

How many shards does the request above create? **Six**: 3 primaries × 1 replica each = 3 replicas, plus the 3 primaries.

| Primaries | Replicas per primary | Total shards |
| --- | --- | --- |
| 3 | 1 | 3 + 3 = **6** |
| 3 | 2 | 3 + 6 = **9** |
| 5 | 3 | 5 + 15 = **20** |

Shard counts add up fast — but remember, a single node can host many shards; 20 shards does not mean 20 machines.

## Key takeaways

- An index is partitioned into shards (each a Lucene instance); document IDs are hashed to shards for instant routing.
- Primary shards take writes; replicas take reads and provide failover — Elasticsearch promotes a replica automatically when a primary's node dies.
- Replicas scale reads; only primaries scale writes — and the primary count is fixed at index creation, so size it for expected growth.
- Total shards = primaries × (1 + replicas). Use an odd node count and spread requests across nodes.

<div class="chapter-nav">
<a class="chapter-nav__item" href="007-using-elasticsearch.html"><span>Previous</span><strong>7. Using Elasticsearch</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="009-quiz-elasticsearch-concepts-and-architecture.html"><span>Next</span><strong>9. Quiz: Elasticsearch Concepts and Architecture</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 1</a></p>
