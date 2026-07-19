---
title: "9. Quiz: Elasticsearch Concepts and Architecture"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 01 · QUIZ</div>

# 9. Quiz: Elasticsearch Concepts and Architecture

Time to show what you know. Four questions covering the concepts from this section — try to answer each before expanding the solution.

## Question 1 — Where does the schema live?

The schema for your documents — the definition of what fields your documents contain and their data types. Is it defined by:

- **a)** the index itself
- **b)** the cluster settings
- **c)** the document itself

<details>
<summary>Show answer</summary>

**a) The index** — technically, the type mapping associated with the index. An index is like a database table: it holds one kind of document, and its mapping defines the fields and their data types.

For an Apache access-log index, the mapping might define the requested URL, status code, request time, and referring URL; for Wikipedia articles it might define the article text, author, and title. Either way, the mapping is set up on the index when the index is created.

</details>

## Question 2 — What do inverted indices do?

What purpose does an inverted index serve in a search engine (any search engine, not just Elasticsearch)?

- **a)** Allows searching phrases in reverse order
- **b)** Quickly maps search terms to the documents they reside within
- **c)** A load-balancing mechanism for spreading search requests across the cluster

<details>
<summary>Show answer</summary>

**b)** An inverted index maps search terms to the documents they live in. As documents are indexed, they are split into search terms, and the index serves as a very fast lookup from each term to every document (and position) where it occurs.

</details>

## Question 3 — Shard math

An index is configured with **5 primary shards and 3 replicas**. How many shards exist in total?

- **a)** 8
- **b)** 15
- **c)** 20

<details>
<summary>Show answer</summary>

**c) 20 shards.** 5 primaries, each with 3 replicas: 5 × 3 = 15 replica shards, plus the 5 primaries = **20**.

Shard counts add up fast — but a single node can host many shards, so 20 shards does not require 20 machines. Elasticsearch distributes shards across the nodes automatically in whatever way makes sense for the cluster.

</details>

## Question 4 — True or false

*Elasticsearch is built only for full-text search of documents.*

<details>
<summary>Show answer</summary>

**False.** Elasticsearch can index any structured data with any mapping you can dream up — numerical data, time-based data, whatever. It is used for searching, aggregating, and visualizing far more than encyclopedias and blogs; a common example is aggregating web-server logs into a system that competes with Google Analytics.

</details>

## How did you do?

If any of these were shaky, review the earlier chapters of this section — these concepts (mappings, inverted indices, primaries and replicas) underpin everything in the hands-on sections ahead.

<div class="chapter-nav">
<a class="chapter-nav__item" href="008-how-elasticsearch-scales.html"><span>Previous</span><strong>8. How Elasticsearch Scales</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="010-wrap-up.html"><span>Next</span><strong>10. Wrap-up</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 1</a></p>
