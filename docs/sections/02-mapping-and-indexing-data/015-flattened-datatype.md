---
title: "15. Flattened Datatype"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 15. Flattened Datatype

So far our documents have been short, with only a few fields. Documents with **many nested inner fields** — think syslog events in JSON, where top-level fields like `host`, `process`, and `fileset` each contain sub-fields that vary by sender — are a different story. By default, dynamic mapping maps **every inner field individually**, and that can eventually take your cluster down. The **`flattened`** datatype is the defense.

## Why many fields are dangerous: the cluster state

Every field's mapping lives in the **cluster state**, alongside index settings and node details — inspect it with:

```bash
curl -XGET '127.0.0.1:9200/_cluster/state?pretty=true' > es-cluster-state.json
```

(It's big — over 5,000 lines even on this tiny playground; search it for your index name to find its mappings.)

The cluster state is shared: a master node pushes the latest cluster state to every node, and each node acknowledges it. **Every new field added to any document creates a new mapping entry, which changes the cluster state, which must be re-synced to every node.** Let unpredictable documents keep adding fields and the cluster state grows unboundedly, sync traffic and delays climb, nodes hit memory pressure, basic indexing and search operations stall — and in the worst case the cluster goes down. That failure mode has a name: a **mapping explosion**.

## Seeing the default behavior

Index a syslog-style document with many inner fields into an unprepared index, then look at what dynamic mapping produced:

```bash
curl -XGET '127.0.0.1:9200/demo-default/_mapping?pretty=true'
```

Every inner field of `host` — OS name, version, architecture, and so on — has been individually mapped with an inferred type. Types were guessed well, but each one is another entry in the cluster state, and senders can keep inventing new ones.

## The flattened fix

The `flattened` type maps a whole object **as a single field**; its inner fields don't appear in the mapping at all. Create a second index that flattens `host` up front:

```bash
curl -XPUT '127.0.0.1:9200/demo-flattened'

curl -XPUT '127.0.0.1:9200/demo-flattened/_mapping' -d '
{
  "properties": {
    "host": { "type": "flattened" }
  }
}'
```

Index the same syslog document into `demo-flattened`, and the mapping now shows `host` as one `flattened` field — while `process`, not flattened, still lists all its inner fields.

The real test: update the document with **new** inner fields (say `host.osVersion` and `host.osArchitecture`), then re-check the mapping. The document holds the new values — but **the mapping is unchanged**. No new field mappings, no cluster state growth. That's the mapping explosion mitigated.

## The trade-off: flattened values are keywords

Everything inside a flattened field is stored as a **keyword**: no analyzers, no tokenizers. That means:

| Query on flattened data | Result |
| --- | --- |
| `"Bionic Beaver"` (exact, on `host`) | ✔ matches — searches all inner values as keywords |
| `host.osVersion: "Bionic Beaver"` (dot notation) | ✔ matches the specific inner field |
| `host.osVersion: "Beaver"` (partial) | ✘ no results — not analyzed, exact only |
| `host.osVersion: "bionic beaver"` (wrong case) | ✘ no results — keywords are case-sensitive |

Supported query types are limited accordingly: `term`, `terms`, `terms_set`, `prefix`, `range`, `match`/`multi_match` (behaving as exact keyword matches), `query_string`, `simple_query_string`, and `exists`. Numerical calculations and true full-text matching don't apply, and **result highlighting doesn't work** on flattened fields, since highlighting depends on analysis.

## Key takeaways

- Every mapped field lives in the cluster state, which is synced across all nodes — unbounded field growth is a cluster-level risk, not just an index nuisance.
- `flattened` maps an entire object as one field; new inner fields never touch the mapping.
- The price: inner values are exact-match keywords — no analysis, partial matching, or highlighting.
- Use it for fields whose inner structure is large, unpredictable, or sender-controlled (log payloads are the classic case) — and keep analyzed mappings for fields you genuinely search as text.

<div class="chapter-nav">
<a class="chapter-nav__item" href="014-data-modeling-and-parent-child-relationships-part-2.html"><span>Previous</span><strong>14. Data Modeling and Parent/Child Relationships, Part 2</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="016-dealing-with-mapping-exceptions.html"><span>Next</span><strong>16. Dealing with Mapping Exceptions</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
