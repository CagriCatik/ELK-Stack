---
title: "4. Intro to HTTP and RESTful API's"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 01</div>

# 4. Intro to HTTP and RESTful API's

Elasticsearch is built on top of a RESTful interface: every interaction with it happens through HTTP requests that follow REST conventions. Before doing anything with Elasticsearch, it pays to understand exactly what an HTTP request is made of and what "RESTful" actually means.

## Anatomy of an HTTP request

Whenever a browser requests a web page, it sends an HTTP request to a web server. Elasticsearch works the same way — you are just talking to an Elasticsearch server instead of a web server, over the exact same protocol. An HTTP request contains more than you might think:

| Part | What it is | Elasticsearch relevance |
| --- | --- | --- |
| **Method (verb)** | What you ask the server to do | `GET` retrieves (searches), `PUT`/`POST` create or replace data, `DELETE` removes it |
| **Protocol** | The HTTP version in use | e.g. `HTTP/1.1` |
| **Host** | The server the request goes to | Usually `127.0.0.1:9200` in this knowledge base |
| **URL** | The resource being requested | Index, document, or API endpoint, e.g. `/shakespeare/_search` |
| **Body** | Optional structured payload | JSON describing your query or document |
| **Headers** | Metadata about the request | `Content-Type: application/json`; browsers also send `User-Agent`, caching info, cookies |

A browser fetching a home page might send:

```text
GET /index.html HTTP/1.1
Host: sundog-education.com
Accept: text/html
User-Agent: Mozilla/5.0 ...
```

No body is needed — the URL says everything. With Elasticsearch, the body is where most of the interesting information goes, and the headers stay minimal.

## What makes an API "RESTful"?

The pragmatic definition: **you communicate with a service using HTTP requests and responses.** Because that is exactly how Elasticsearch works, it exposes a RESTful API:

- **Search** → send a `GET` with the query in the body
- **Insert** → send a `PUT` (or `POST`) with the document in the body
- **Remove** → send a `DELETE`

More formally, REST (**Representational State Transfer**) has six guiding constraints:

1. **Client–server architecture** — clients send requests to a server (or a whole cluster of servers), which is exactly the Elasticsearch model.
2. **Stateless** — every request must be self-contained. Neither side keeps memory of previous requests, so all information needed to fulfill a request must travel inside it.
3. **Cacheable** — the system must *allow* for response caching (e.g., responses can declare whether they may be cached).
4. **Layered system** — a hostname does not mean one physical machine; requests may be routed to any server in a fleet. This is why statelessness matters — the next request may hit a different host.
5. **Code on demand** *(optional)* — servers may send executable code (e.g., JavaScript) in a response body. Not used with Elasticsearch, but permitted by REST.
6. **Uniform interface** — data is exchanged in a predictable, structured form that can evolve in a controlled way.

## Why work at the HTTP level?

This knowledge base deliberately works with raw HTTP requests and responses rather than a language-specific client, for a good reason:

- **Every language can send HTTP requests** — Java, JavaScript, Python, whatever you use. The mechanics of sending the request are trivial; the skill is constructing the request and interpreting the JSON response.
- **Client libraries are thin wrappers.** Language clients for Elasticsearch generally wrap these same HTTP calls, so you need to understand what happens underneath to use them well.
- **All official Elasticsearch documentation is written in this style**, so the skill transfers directly.

## curl: the tool for this knowledge base

`curl` sends HTTP requests straight from the command line. The general shape of an Elasticsearch curl command:

```bash
curl -H "Content-Type: application/json" -X<VERB> '<host>:<port>/<path>' -d '<json body>'
```

- `-H "Content-Type: application/json"` — tells Elasticsearch the body is JSON. Always required when sending a body.
- `-X` — the HTTP verb (`GET`, `PUT`, `POST`, `DELETE`).
- The URL — host (usually `127.0.0.1:9200`), then the index and the operation.
- `-d` — the JSON message body, in single quotes.

### Example 1 — searching

Query the `shakespeare` index for the phrase *"to be or not to be"*:

```bash
curl -H "Content-Type: application/json" -XGET '127.0.0.1:9200/shakespeare/_search?pretty' -d '
{
  "query": {
    "match_phrase": {
      "text_entry": "to be or not to be"
    }
  }
}'
```

Reading it piece by piece: `_search` says "process a search query"; the `?pretty` query parameter formats the JSON response for human eyes on the command line; and the body nests a `query` containing a `match_phrase` clause against the `text_entry` field.

### Example 2 — inserting a document

Insert a movie with the explicit ID `109487` into the `movies` index:

```bash
curl -H "Content-Type: application/json" -XPUT '127.0.0.1:9200/movies/_doc/109487' -d '
{
  "genre": ["IMAX", "Sci-Fi"],
  "title": "Interstellar",
  "year": 2014
}'
```

The `PUT` verb creates/replaces the document at that ID. In JSON, a list (like multiple genres) is a comma-delimited set of values in square brackets.

> **Note:** Older Elasticsearch versions used named *mapping types* in the URL (e.g., `/movies/movie/109487`). Mapping types were removed; current versions use the fixed `_doc` endpoint shown above.

## Key takeaways

- Elasticsearch speaks plain HTTP: verb + URL + JSON body in, JSON out.
- REST is mostly a pragmatic idea — HTTP as the API — plus formal constraints, of which *statelessness* matters most in practice.
- Learn to construct requests and parse responses, and you can drive Elasticsearch from any language or tool.
- `curl` against `127.0.0.1:9200` is the reference workflow for everything that follows.

<div class="chapter-nav">
<a class="chapter-nav__item" href="003-elasticsearch-overview.html"><span>Previous</span><strong>3. Elasticsearch Overview</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="005-elasticsearch-basics-logical-concepts.html"><span>Next</span><strong>5. Elasticsearch Basics: Logical Concepts</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 1</a></p>
