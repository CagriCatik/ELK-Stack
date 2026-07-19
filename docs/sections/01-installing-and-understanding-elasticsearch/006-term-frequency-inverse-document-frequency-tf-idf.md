---
title: "6. Term Frequency / Inverse Document Frequency (TF/IDF)"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 01</div>

# 6. Term Frequency / Inverse Document Frequency (TF/IDF)

An Elasticsearch index is not a simple list of documents — it is an **inverted index**, the mechanism by which pretty much all search engines work. This chapter explains what an inverted index is, and how **TF/IDF** turns it into ranked, relevant search results.

## The inverted index

Imagine an index holding two text documents:

- **Document 1:** "Space: the final frontier. These are the voyages..."
- **Document 2:** "He's bad, he's number one. He's a space cowboy with a laser gun."

A search engine does not store those strings directly — it flips the problem on its head. Each document is split into individual **search terms** (here: each word, lowercased to normalize), and the index maps **each term to the documents it occurs in**:

```text
space    → document 1, document 2
the      → document 1, document 2
final    → document 1
frontier → document 1
cowboy   → document 2
...
```

That is the "inverted" part: instead of document → words, it stores word → documents, which makes looking up *which documents contain this term* extremely fast. In practice the index also stores the **positions** of each term within each document (which is what makes phrase matching possible), but term → documents is the core idea.

## The relevance problem

Take the word *"the"*. It appears in virtually every document, so a naive lookup for it would return everything. How does a search engine make sure that only documents where a term is actually *special* rank highly? That is where TF/IDF comes in — a fancy-sounding term for a simple concept.

## TF/IDF

**Term Frequency (TF)** — how often a term appears *within a given document*. If "space" occurs many times in a document, that document has a high term frequency for "space". The same is true of "the".

**Document Frequency (DF)** — how often a term appears *across all documents in the entire index*. "Space" probably occurs rarely across the whole index (low DF); "the" appears everywhere (very high DF).

Divide term frequency by document frequency — equivalently, multiply by the *inverse* document frequency:

```text
relevance ∝ TF × IDF  =  term frequency / document frequency
```

The result measures **how special a term is to a document**: not just "how often does this term occur here", but "how does that compare to how often it occurs everywhere else?"

- "space" in an article about space → high TF, low DF → **ranks very highly**
- "the" in the same article → high TF, but huge DF → **ranks poorly**

## Why this matters

This is the basic idea behind how search engines rank results: when you search for a term, results come back in order of relevance, and relevance is (at least loosely) based on TF/IDF. Modern Lucene/Elasticsearch actually uses **BM25**, a refined scoring function built on the same TF/IDF intuition — understanding TF/IDF is what makes relevance scores explainable when you tune them later.

## Key takeaways

- An inverted index maps search terms → documents (plus positions), which is what makes text search fast.
- Term frequency measures importance of a term *within* a document; document frequency measures how common it is *across* the index.
- Relevance ≈ TF × IDF: terms that are frequent in a document but rare elsewhere score highest.
- Common words ("the") are automatically de-weighted because their document frequency is enormous.

<div class="chapter-nav">
<a class="chapter-nav__item" href="005-elasticsearch-basics-logical-concepts.html"><span>Previous</span><strong>5. Elasticsearch Basics: Logical Concepts</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="007-using-elasticsearch.html"><span>Next</span><strong>7. Using Elasticsearch</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 1</a></p>
