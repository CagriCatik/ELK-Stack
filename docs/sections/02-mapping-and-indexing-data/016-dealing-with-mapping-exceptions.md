---
title: "16. Dealing with Mapping Exceptions"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 16. Dealing with Mapping Exceptions

Mapping is the heart of an index — and like most important things, it can go wrong. This chapter simulates the common mapping failures in a safe playground before you meet them in production.

## Recap: the two sides of mapping

A mapping is both a **process** (defining how JSON documents are stored) and a **result** (the metadata structure that comes out of it). The process happens one of two ways:

- **Explicit mapping** — you define the fields, types, and parameters yourself.
- **Dynamic mapping** — Elasticsearch infers types automatically and updates the mapping as new fields appear.

The running example is a simple log-collection microservice index:

```bash
curl -XPUT '127.0.0.1:9200/microservice-logs' -d '
{
  "mappings": {
    "properties": {
      "timestamp": { "type": "date" },
      "service":   { "type": "keyword" },
      "host_ip":   { "type": "ip" },
      "port":      { "type": "integer" },
      "message":   { "type": "text" }
    }
  }
}'
```

Dynamic mapping stays enabled, so *new* fields can still appear and be mapped automatically. Two failure modes lurk here: **type mismatches** against the explicit mapping, and **mapping explosions** from unbounded dynamic fields.

## Failure 1 — Type mismatches and the "safety zone"

A well-formed log indexes fine — `"port": 12345` is an integer, as mapped. Now a service logs its port as a **string**:

```json
{ "timestamp": "2020-04-11T12:34:56.789Z", "service": "ABC", "host_ip": "10.0.2.15", "port": "15000", "message": "..." }
```

Surprisingly, **this works**. Elasticsearch has a coercion "safety zone": `"15000"` parses cleanly to an integer, so it is accepted. But log `"port": "none"` — a string with no numeric interpretation — and you hit your first mapping exception:

```text
HTTP 400 — mapper_parsing_exception: failed to parse field [port] of type [integer]
  caused_by: number_format_exception: For input string: "none"
```

### Partial fix: `ignore_malformed`

There is no one-size-fits-all solution, but `ignore_malformed` helps in this case. It is a **non-dynamic** setting — set it at index creation, or close/reopen the index around the change:

```bash
curl -XPOST '127.0.0.1:9200/microservice-logs/_close'

curl -XPUT '127.0.0.1:9200/microservice-logs/_settings' -d '
{ "index.mapping.ignore_malformed": true }'

curl -XPOST '127.0.0.1:9200/microservice-logs/_open'
```

Re-index the `"port": "none"` document and it now succeeds — with a twist: fetching it by ID shows the port value was **omitted from indexing** and the document carries an `_ignored: ["port"]` marker.

### Where `ignore_malformed` gives up

Its limits are considerable: it **cannot handle JSON objects** arriving in a scalar field. If a developer logs a JSON payload into the `text`-mapped `message` field, the mapper_parsing_exception is back, `ignore_malformed` or not. And nesting doesn't save you either: give the payload its own dynamically-mapped `object` field, and the first sender whose `payload.data` has a *different type* than the first-seen one triggers the same exception again.

Realistic mitigations:

- Make sure engineers know these mapping mechanics; establish **shared guidelines** for log fields.
- Use a **dead letter queue** pattern — route failed documents to a separate queue (application-level, or Logstash's DLQ) so they can still be processed instead of silently lost.

## Failure 2 — The field-limit wall

Nested payloads accumulate fields fast, and the road ends at **1,000 fields** — the default limit per mapping. Simulate it by generating a 1,001-field document (install `jq` first if needed: `sudo apt-get install jq`):

```bash
THOUSANDONE_FIELDS_JSON=$(echo {1..1001} | jq -Rn '( input | split(" ") ) as $nums | $nums[] | {("key_" + .): .} ' | jq -cs 'add')

curl -XPUT '127.0.0.1:9200/big-objects'

curl -XPOST '127.0.0.1:9200/big-objects/_doc?pretty' --data-raw "$THOUSANDONE_FIELDS_JSON"
```

Straight to an `illegal_argument_exception`: *Limit of total fields [1000] has been exceeded*.

The limit is a **dynamic setting**, so it can be raised without closing the index:

```bash
curl -XPUT '127.0.0.1:9200/big-objects/_settings' -d '
{ "index.mapping.total_fields.limit": 1001 }'
```

But treat that as a last resort: first ask *why* the index needs that many fields, because a bigger mapping buys potential performance degradation and memory pressure (recall the cluster-state mechanics from the previous chapter). The `flattened` datatype is often the better answer.

## Key takeaways

- Coercion gives a safety zone (`"15000"` → 15000), but non-parseable values throw `mapper_parsing_exception`.
- `ignore_malformed` swallows bad scalar values (marking them `_ignored`) but cannot cope with JSON objects in scalar fields.
- Guard against silent data loss with team conventions and a dead-letter-queue pattern for failed documents.
- Mappings cap out at 1,000 fields by default; the limit is tunable, but flattening or restraint is usually wiser.

<div class="chapter-nav">
<a class="chapter-nav__item" href="015-flattened-datatype.html"><span>Previous</span><strong>15. Flattened Datatype</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="017-wrapup.html"><span>Next</span><strong>17. Wrap-up</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
