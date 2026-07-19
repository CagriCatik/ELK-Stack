---
title: "7. Using Elasticsearch"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 01</div>

# 7. Using Elasticsearch

How do you actually use an Elasticsearch index? There are three levels to talk about, from lowest to highest: the raw **RESTful API**, language-specific **client libraries**, and **analytics tools** like Kibana. Each is a different trade-off between control and convenience.

## 1. The RESTful API

At the lowest level you talk to Elasticsearch exactly the way a browser talks to a web server: an HTTP request with a verb (`GET`, `PUT`, `POST`, `DELETE`) and a body describing what you want. Searching, for example, is a `GET` request whose JSON body contains the query.

Because it is plain HTTP, **any language, tool, or environment that can make web requests can drive Elasticsearch** — nothing more is required. If you understand how to structure the JSON requests, you can talk to an Elasticsearch server from anywhere.

Most of this knowledge base works at this level deliberately, so you understand what Elasticsearch is doing under the hood.

## 2. Client libraries

You don't always have to do it the hard way. If you are accessing Elasticsearch from an application — a web server, a backend service — there is usually a **client API** that abstracts over the REST calls. Instead of hand-constructing the right JSON for a search or an insert, the client gives you specialized methods for searching and indexing.

Clients exist for Python, Ruby, Perl, C++, Java, JavaScript, and practically every other language. Two things to understand about them:

- **They all boil down to REST calls in the end.** If you understand the underlying HTTP requests, you can pick up any client API — and move between languages easily.
- **They are generally thin wrappers.** You still need to understand what happens underneath to use them successfully; the client saves typing, not understanding.

This is why the material here doesn't single out one language: raw-HTTP knowledge transfers to all of them.

## 3. Analytics tools: Kibana

At the highest level sit tools that require no code at all. **Kibana**, part of the Elastic Stack, is a web-based graphical UI for interacting with and exploring your indices — searching, visualizing, and analyzing without writing a single request. That makes it a visual analysis tool you can put in front of practically anyone in your organization, not just developers.

## Choosing a level

| Level | What it is | When to use it |
| --- | --- | --- |
| REST API | Raw HTTP + JSON | Learning, debugging, scripting, anything language-agnostic |
| Client library | Language wrapper over REST | Application code in a specific language |
| Kibana | Web UI, no code | Exploration, dashboards, non-developer users |

## Key takeaways

- Elasticsearch is driven over plain HTTP: any language that can make a web request can use it, with no special SDK required.
- Client libraries are convenience wrappers around the same REST calls — learn the REST layer once and every client makes sense.
- Kibana covers the no-code end: exploring and visualizing indices interactively.
- These are the interface options; the next chapter looks at how the cluster works internally.

<div class="chapter-nav">
<a class="chapter-nav__item" href="006-term-frequency-inverse-document-frequency-tf-idf.html"><span>Previous</span><strong>6. Term Frequency / Inverse Document Frequency (TF/IDF)</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="008-how-elasticsearch-scales.html"><span>Next</span><strong>8. How Elasticsearch Scales</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 1</a></p>
