---
title: "4. Analyzers"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 4. Analyzers

Before importing data, Elasticsearch needs to be told how to store it. That is the job of the **mapping** — and for text fields, the closely related concept of **analyzers**.

## What is a mapping?

A mapping is a **schema definition**: it tells Elasticsearch what format to store your data in, how to index it, and how to analyze it. Elasticsearch has reasonable defaults and will usually infer the right thing from the nature of your data — strings, integers, floating-point numbers — but sometimes it needs a hint.

A classic example from the MovieLens data: the release year should be explicitly interpreted as a **date** field, not just a number. Defining that up front looks like this:

```bash
curl -H "Content-Type: application/json" -XPUT '127.0.0.1:9200/movies' -d '
{
  "mappings": {
    "properties": {
      "year": { "type": "date" }
    }
  }
}'
```

Reading the command: `-H` sends the `Content-Type: application/json` header (required since Elasticsearch 6 whenever a body is sent — the next chapters set up a shortcut so you don't have to type it every time); `-XPUT` is the HTTP verb; `127.0.0.1:9200` is the local server; `/movies` is the index being created; and `-d '…'` carries the JSON body, whose `mappings` section declares that the `year` property has type `date`.

## What mappings can define

- **Field types** — `date` as above, plus `text`, `keyword`, `byte`, `short`, `integer`, `long`, `float`, `double`, `boolean`, and more.
- **Whether a field is indexed for full-text search** — a field can be excluded from search entirely and just carried along in results as ancillary information.
- **Analyzers** — how text in the field is processed, which is the interesting part.

## What an analyzer does

An analyzer has three kinds of components, applied in order:

1. **Character filters** — clean the raw text: remove HTML encoding, convert `&` to `and`, and so on. The key insight: if you apply the *same* analyzer to your search queries and to the indexed data, these discrepancies disappear — searching for `&` or `and` returns the same results either way.
2. **Tokenizers** — split the string into terms. What makes up a "word"? You can split on whitespace, on punctuation, on anything that isn't a letter, or with language-specific rules. This determines the search terms that end up in the inverted index.
3. **Token filters** — transform the terms:
   - **Lowercasing** — makes search case-insensitive (applied to both query and index, case simply stops mattering).
   - **Stemming** — normalizes word variants to a root, so *box*, *boxes*, *boxing*, and *boxed* all match a search for "box".
   - **Synonyms** — a search for *big* can also surface documents containing *large*.
   - **Stop words** — drop low-information words (*the*, *and*, *in*, *a*) to save space.

> **Use stop words with caution.** Phrase search suffers: a query for *"to be or not to be"* is made up almost entirely of stop words — filter them out and that search cannot work at all. Don't enable stop-word filtering lightly.

## Choosing an analyzer

| Analyzer | Behavior | When to use |
| --- | --- | --- |
| **standard** | Splits on word boundaries, removes punctuation, lowercases | The default; the safe choice when the language is unknown |
| **simple** | Splits on anything that isn't a letter; lowercases | Simpler tokenization needs |
| **whitespace** | Splits on whitespace only; preserves case and punctuation | When punctuation is meaningful |
| **language analyzers** (english, french, …) | Adds language-specific stop words, stemming, and synonym handling | Full-text search in a known language |

For MovieLens movie titles, **standard** is actually the right choice — the data includes foreign films, so imposing English-specific rules on every title would be wrong. When you do know the language, a language analyzer unlocks stemming and stop words for it. It is even possible to run *different* analyzers over the same text and store the results as separate fields — for example an English-analyzed and a French-analyzed version of the same content, searchable independently.

## Key takeaways

- A mapping is the index's schema: field types, indexing behavior, and analyzers.
- Elasticsearch infers types well, but be explicit where it matters (dates, and later `keyword` vs `text`).
- Analyzer = character filters → tokenizer → token filters; applying the same analysis to queries and documents is what makes fuzzy, case-insensitive matching work.
- Stop words can break phrase search — enable them deliberately, not by default.

<div class="chapter-nav">
<a class="chapter-nav__item" href="003-introducing-the-movielens-data-set.html"><span>Previous</span><strong>3. Introducing the MovieLens Data Set</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="005-a-note-on-entering-curl-commands.html"><span>Next</span><strong>5. A Note on Entering curl Commands</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
