---
title: "11. Dealing with Concurrency"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 11. Dealing with Concurrency

Distributed systems bring a class of subtle problems: what happens when two clients try to change the same thing at the same time? Who wins? This chapter covers how Elasticsearch handles those situations.

## The problem: lost updates

Imagine a busy website that stores a **view count** per page in Elasticsearch, served by multiple web servers:

```text
Client A: reads count → 10          Client B: reads count → 10
Client A: writes count = 11         Client B: writes count = 11
                                    ✗ should have been 12
```

Two increments happened, but the count only went up by one. In the window between *reading* the current value and *writing* the new one, the other client's write was silently lost. On a cluster with real traffic, this absolutely happens.

## The solution: optimistic concurrency control

Elasticsearch tracks every document revision with two automatically maintained fields (this is separate from the `_version` field used for updates, and gives finer control):

- **`_seq_no`** — a sequence number, incremented on every change to the document
- **`_primary_term`** — identifies which primary shard owned the sequence (it increments when a new primary is elected)

Together they uniquely identify a chronological revision of the document. Every read returns them, so a client can say: *"apply my write only if the document is still at the revision I read."* If two clients try to update the same revision, **only one succeeds** — the other gets a version-conflict error and must re-read and retry with the latest revision. That retry loop is the "optimistic" part: no locks, just detection and retry.

## Hands-on

Look at Interstellar's current revision:

```bash
curl -XGET '127.0.0.1:9200/movies/_doc/109487?pretty'
```

The response includes `"_seq_no" : 7` and `"_primary_term" : 1`. Now update *that specific revision* by passing both values as query parameters (double quotes this time — the URL contains characters the shell would otherwise mangle):

```bash
curl -XPUT "127.0.0.1:9200/movies/_doc/109487?if_seq_no=7&if_primary_term=1" -d '
{
  "genres": ["IMAX", "Sci-Fi"],
  "title": "Interstellar Foo",
  "year": 2014
}'
```

It succeeds, and the response carries a new sequence number (say, 12). Now **replay the exact same command** — pretending to be a second client that also read revision 7:

```text
version_conflict_engine_exception: current document has seqNo [12] and primary term [1]
```

Exactly the behavior we want: had those two updates raced, only one would have won. The losing client re-reads (or takes the seq_no from the error), retries with `if_seq_no=12` — and succeeds, producing revision 13.

## The easy way: `retry_on_conflict`

Managing sequence numbers by hand is instructive, but partial updates can delegate the retry loop to Elasticsearch:

```bash
curl -XPOST '127.0.0.1:9200/movies/_update/109487?retry_on_conflict=5' -d '
{
  "doc": { "title": "Interstellar" }
}'
```

On a conflict, Elasticsearch automatically re-fetches the latest revision and reapplies the partial update, up to 5 times, before giving up.

## Key takeaways

- Read-modify-write cycles lose updates under concurrency — the classic race condition.
- `_seq_no` + `_primary_term` identify a document revision; conditional writes with `if_seq_no`/`if_primary_term` make conflicting writes fail loudly instead of silently losing data.
- On conflict: re-read, retry with the new revision — or let `retry_on_conflict=N` on `_update` requests do it for you.
- If your cluster takes concurrent writes to the same documents, use one of these mechanisms. Always.

<div class="chapter-nav">
<a class="chapter-nav__item" href="010-exercise-insert-update-and-delete-a-movie.html"><span>Previous</span><strong>10. Insert, Update and Delete a Movie</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="012-using-analyzers-and-tokenizers.html"><span>Next</span><strong>12. Using Analyzers and Tokenizers</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
