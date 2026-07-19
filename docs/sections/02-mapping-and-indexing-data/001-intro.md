---
title: "1. Introduction"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 1. Introduction

This section is about **mapping and indexing your data**. To make things interesting, it works with a real-world data set of movies and movie ratings — you won't just read about the concepts, you'll import this data into Elasticsearch yourself.

## What this section covers

- **Connecting to your cluster** — the SSH workflow used before every hands-on exercise.
- **The MovieLens data set** — the free movie-ratings data used throughout this knowledge base.
- **Mappings and analyzers** — telling Elasticsearch how to store, index, and analyze your data.
- **Document CRUD** — inserting, bulk-importing, updating, and deleting individual documents, plus a hands-on exercise.
- **Concurrency** — the complexities that arise when many clients write to a busy cluster at the same time, and how optimistic concurrency control solves them.
- **Analyzers and tokenizers in practice** — `text` vs `keyword` fields and how they change search behavior.
- **Data modeling** — normalized vs denormalized data, and parent/child relationships for relational-style structures.
- **Advanced mapping topics** — the `flattened` datatype, mapping explosions, and dealing with mapping exceptions.

There's a lot to cover, so let's get started.

<div class="chapter-nav">
<a class="chapter-nav__item" href="../01-installing-and-understanding-elasticsearch/010-wrap-up.html"><span>Previous</span><strong>Section 1: Wrap-up</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="002-connecting-to-your-cluster.html"><span>Next</span><strong>2. Connecting to your Cluster</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
