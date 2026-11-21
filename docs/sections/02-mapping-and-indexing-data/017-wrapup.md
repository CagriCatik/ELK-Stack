---
title: "17. Wrap-up"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 17. Wrap-up

Congratulations — this section covered the full working basics of getting data into Elasticsearch.

## What this section covered

- **The workflow** — connecting to the cluster over SSH, and the MovieLens data set used throughout.
- **Mappings and analyzers** — schema definitions, field types, and how character filters, tokenizers, and token filters shape what's searchable.
- **Document operations** — importing via JSON/REST, bulk-importing with `_bulk`, and inserting, updating, and deleting documents (plus your first hands-on exercise).
- **Concurrency** — optimistic concurrency control with `_seq_no`/`_primary_term` and `retry_on_conflict`.
- **`text` vs `keyword`** — how the mapping type changes search behavior, demonstrated hands-on.
- **Data modeling** — normalized vs denormalized trade-offs and native parent/child relationships.
- **Defensive mapping** — the `flattened` datatype, mapping exceptions, and the field-count limit.

## Where to next

There's still more essential ground to cover before Elasticsearch can go to work for you or your organization. Next up: **searching** — query DSL, filters, fuzzy matching, and more.


## Official References & Further Reading

- [Elasticsearch Guide — Mapping & Field data types](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html)
- [Elasticsearch Guide — Dynamic field mapping (dynamic: strict)](https://www.elastic.co/guide/en/elasticsearch/reference/current/dynamic-field-mapping.html)
- [Elasticsearch Guide — Document APIs (_doc, _bulk, _update, seq_no)](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html)
- [Elasticsearch Guide — Text analysis, analyzers, and tokenizers](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis.html)
- [Elasticsearch Guide — Flattened field type & Join field type](https://www.elastic.co/guide/en/elasticsearch/reference/current/flattened.html)

<div class="chapter-nav">
<a class="chapter-nav__item" href="016-dealing-with-mapping-exceptions.html"><span>Previous</span><strong>16. Dealing with Mapping Exceptions</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="../03-searching-with-elasticsearch/001-intro.html"><span>Next</span><strong>1. Section 3 Intro</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
