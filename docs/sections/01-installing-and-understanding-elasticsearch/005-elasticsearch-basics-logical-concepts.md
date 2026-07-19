---
title: "5. Elasticsearch Basics: Logical Concepts"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 01</div>

# 5. Elasticsearch Basics: Logical Concepts

Before working with an Elasticsearch server, you need its two main logical concepts: the **document** and the **index**. Both have close analogies in the database world, which makes them easy to pick up — but keep in mind that how Elasticsearch works *under the hood* is very different from a traditional database.

## Documents

A **document** is a lot like a row in a database: it represents a given entity — the thing you are searching for. Two important properties:

- **Documents are JSON.** Elasticsearch works on top of JSON-formatted data: structured data containing strings, numbers, dates, lists, and nested objects, encoded in a way that transmits cleanly over the web. And it is not just about text — any structured data works.
- **Every document has a unique ID.** You can either assign the ID explicitly yourself (as with the movie ID in the previous chapter) or let Elasticsearch generate one for you.

## Indices

An **index** is the highest-level entity you can query against in Elasticsearch, and it contains a collection of documents. Continuing the database analogy: an index is like a table, and documents are the rows in it.

Two things belong to the index:

- **The schema (mapping)** — the definition of the fields and data types in your documents lives with the index.
- **One kind of document per index.** A single index holds one type of document, so all documents in it share the same field definitions.

## The database analogy

| Relational database | Elasticsearch |
| --- | --- |
| Database | Cluster |
| Table | Index |
| Row | Document |
| Schema | Mapping |

The terminology maps neatly, which helps when reasoning about data modeling. But the analogy stops at the concepts: an index is not stored like a table, and queries do not execute like SQL — the next chapter on the inverted index shows just how differently a search engine organizes its data.

## Key takeaways

- A document is a JSON entity with a unique ID; an index is a queryable collection of documents.
- The field/type schema (the *mapping*) is a property of the index, and an index holds one kind of document.
- Cluster ≈ database, index ≈ table, document ≈ row — same concepts, very different machinery underneath.

<div class="chapter-nav">
<a class="chapter-nav__item" href="004-intro-to-http-and-restful-api-s.html"><span>Previous</span><strong>4. Intro to HTTP and RESTful API's</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="006-term-frequency-inverse-document-frequency-tf-idf.html"><span>Next</span><strong>6. Term Frequency / Inverse Document Frequency (TF/IDF)</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 1</a></p>
