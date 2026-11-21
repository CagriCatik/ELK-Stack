---
title: "10. Wrap-up"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 01</div>

# 10. Wrap-up

A lot was accomplished in a short period of time. This section took you from nothing to a working Elasticsearch server plus the conceptual model needed to use it well.

## What this section covered

- **Environment** — an Ubuntu virtual machine with Elasticsearch installed, running, and answering on `127.0.0.1:9200`.
- **The Elastic Stack** — Elasticsearch as a horizontally scaled Lucene, with Kibana for visualization, Logstash/Beats for ingestion, and X-Pack for security and operations.
- **The interface** — everything happens over a RESTful API: HTTP verbs, JSON bodies, and `curl` as the reference tool.
- **Logical concepts** — documents (JSON entities with unique IDs) and indices (queryable collections with a mapping), and how they map to database tables and rows.
- **Search internals** — the inverted index, and TF/IDF as the basis of relevance ranking.
- **Architecture** — primary and replica shards, hash-based routing, automatic failover, and why the primary shard count must be planned at index creation.

## Where to next

This only scratches the surface of what Elasticsearch can do. The remaining sections are hands-on: importing, searching, and analyzing data with Elasticsearch in many different ways — starting with mapping and indexing data in Section 2.


## Official References & Further Reading

- [Elasticsearch Guide — What is Elasticsearch?](https://www.elastic.co/guide/en/elasticsearch/reference/current/elasticsearch-intro.html)
- [Elasticsearch Guide — Set up Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup.html)
- [Elasticsearch Guide — Similarity module & Okapi BM25](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-modules-similarity.html)
- [Elasticsearch Guide — Scalability and resilience (Clusters, Nodes, and Shards)](https://www.elastic.co/guide/en/elasticsearch/reference/current/scalability.html)

<div class="chapter-nav">
<a class="chapter-nav__item" href="009-quiz-elasticsearch-concepts-and-architecture.html"><span>Previous</span><strong>9. Quiz: Elasticsearch Concepts and Architecture</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="../02-mapping-and-indexing-data/001-intro.html"><span>Next</span><strong>1. Introduction</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 1</a></p>
