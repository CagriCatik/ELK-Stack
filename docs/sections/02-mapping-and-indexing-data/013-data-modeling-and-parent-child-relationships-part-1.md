---
title: "13. Data Modeling and Parent/Child Relationships, Part 1"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 13. Data Modeling and Parent/Child Relationships, Part 1

In many distributed data stores — Cassandra, MongoDB — the standard advice is to **denormalize** your data. Coming from relational databases, where information is tied together through relations, that can feel counterintuitive. Elasticsearch lets you do it either way; this chapter walks through the trade-offs, using MovieLens ratings as the example.

## The normalized approach

A rating record contains only a user ID, a movie ID, a rating, and a timestamp. But what you want to *display* is the movie's title — `6733` means nothing to anyone; *Interstellar* does. Normalized, titles live once in a movies index, and looking up a rating takes **two hops**:

```text
1. GET rating        → { userID, movieID, rating }
2. GET movie by ID   → { title }
```

**Pros:**

- Minimal storage — each title stored exactly once.
- Easy to change: fixing a movie title means updating one document, and the fix is reflected everywhere automatically.

**Cons:**

- Two queries instead of one — potentially **double the traffic** on your cluster, and added latency from two dependent round-trips.

## The denormalized approach

Copy the title into every rating record:

```text
1. GET rating → { userID, title, rating }
```

**Pros:** one query, one round-trip — best for page response time when latency matters.

**Cons:** titles are duplicated into every rating, and changing one means iterating over every rating that references it. Not impossible — just painful.

## How to decide

Don't over-weight the storage argument. On modern clusters, storage is cheap; optimizing for minimal storage is rarely the right call. The questions that actually matter:

- **How often does the shared data change?** Movie titles essentially never change (typo fixes at most) — a strong argument for denormalizing them.
- **Can you afford the extra traffic and latency** of two dependent lookups on every read? If page response time is critical, denormalize.
- **Do you need easy updates** to shared values? Then keep them normalized.

## Parent/child relationships

There's a third option for genuinely relational structures: Elasticsearch has **built-in parent/child modeling**. Think of movie franchises and their films — the Star Wars franchise as the parent, with *A New Hope*, *The Empire Strikes Back*, *Return of the Jedi*, and *The Force Awakens* as its children. Both entity types stay independent documents, but they can be queried through their relationship.

The next chapter sets this up hands-on.

## Key takeaways

- Normalized = compact and easy to update, but two hops per lookup; denormalized = one fast lookup, but duplicated data that's hard to change.
- Optimize for query patterns and latency, not for storage — storage is cheap, round-trips are not.
- Data that rarely changes (like movie titles) is a natural candidate for denormalization.
- For real hierarchies, Elasticsearch offers native parent/child relationships as a middle path.

<div class="chapter-nav">
<a class="chapter-nav__item" href="012-using-analyzers-and-tokenizers.html"><span>Previous</span><strong>12. Using Analyzers and Tokenizers</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="014-data-modeling-and-parent-child-relationships-part-2.html"><span>Next</span><strong>14. Data Modeling and Parent/Child Relationships, Part 2</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
