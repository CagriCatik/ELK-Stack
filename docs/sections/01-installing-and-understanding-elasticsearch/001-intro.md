---
title: "1. Introduction"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 01</div>

# 1. Introduction

This section lays the conceptual and practical foundation for everything else in this knowledge base: you will get Elasticsearch running, understand what it actually is, and learn the core architecture concepts that every later section builds on.

## What this section covers

1. **Installing Elasticsearch** — getting a working single-node Elasticsearch server you can experiment with.
2. **Elasticsearch Overview** — the 30,000-foot view of the Elastic Stack: Elasticsearch, Kibana, Logstash, Beats, and X-Pack, and how they fit together.
3. **HTTP and RESTful APIs** — the anatomy of HTTP requests and why everything in Elasticsearch is done through its REST interface.
4. **Logical Concepts** — documents and indices, and how they map to familiar database ideas.
5. **TF/IDF and the inverted index** — how search engines actually store text and rank results by relevance.
6. **Using Elasticsearch** — the three levels of interacting with a cluster: raw REST calls, client libraries, and Kibana.
7. **How Elasticsearch Scales** — primary and replica shards, routing, failover, and cluster resiliency.
8. **Quiz and wrap-up** — a knowledge check on the concepts before moving on to hands-on work.

## What you should have by the end

- A running Elasticsearch installation you can send requests to with `curl`
- A clear mental model of the Elastic Stack components and when to use each
- The vocabulary used throughout the rest of this knowledge base: document, index, mapping, shard, replica, node, cluster

These concepts are the underpinning for all the hands-on sections that follow — importing data, searching, aggregating, and operating clusters — so it is worth making sure they are solid before moving on.

<div class="chapter-nav">
<span></span>
<a class="chapter-nav__item chapter-nav__item--next" href="002-installing-elasticsearch-step-by-step.html"><span>Next</span><strong>2. Installing Elasticsearch [Step by Step]</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 1</a></p>
