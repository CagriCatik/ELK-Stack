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

<div class="chapter-nav">
<a class="chapter-nav__item" href="016-dealing-with-mapping-exceptions.html"><span>Previous</span><strong>16. Dealing with Mapping Exceptions</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="../03-searching-with-elasticsearch/001-intro.html"><span>Next</span><strong>Section 3: Searching with Elasticsearch</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
