---
title: "12. Using Analyzers and Tokenizers"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 12. Using Analyzers and Tokenizers

Every text field forces a decision: should searches on it be **exact matches**, or **analyzed** partial matches ranked by relevance? The mapping type you choose — `keyword` or `text` — determines this, and this chapter shows the difference hands-on.

## `keyword` vs `text`

- **`keyword`** — analysis is suppressed entirely. Only **exact matches** return results: case-sensitive, whole-value matching. Use it for identifiers, tags, categories.
- **`text`** — the field is run through an **analyzer**. Searches can partial-match, are case-insensitive (with the usual analyzers), can apply stemming and synonyms and stop words — and multi-term searches don't need every term to match; documents matching only some terms come back too, just with lower relevance scores.

## Hands-on: analyzed fields are forgiving

Search the movie titles for "Star Trek":

```bash
curl -XGET '127.0.0.1:9200/movies/_search?pretty' -d '
{
  "query": {
    "match": { "title": "Star Trek" }
  }
}'
```

The results include *Star Trek Beyond* — but also *Star Wars*. Both titles match the term `star`, so both come back; Elasticsearch errs on the side of giving you more results. Relevance sorts it out: Star Trek Beyond scores ~3.0, Star Wars only ~0.87, so the best match is on top.

Now try the genre field, with what sounds like a very precise query:

```bash
curl -XGET '127.0.0.1:9200/movies/_search?pretty' -d '
{
  "query": {
    "match_phrase": { "genre": "sci" }
  }
}'
```

This *also* returns hits — every Sci-Fi movie, despite searching for lowercase `sci`. The genre field was dynamically mapped as analyzed text: the analyzer split `Sci-Fi` on the hyphen into two terms and lowercased them, so `sci` matches. For a genre taxonomy, that's not what you want — searching a nonexistent genre `sci` should return nothing.

## Fixing it with an explicit mapping

Mappings generally **cannot be changed in place** — the index has to be rebuilt. Delete it (note how frighteningly easy this is — have backups):

```bash
curl -XDELETE 127.0.0.1:9200/movies
```

Recreate it with genre as an exact-match `keyword` and title as analyzed `text` with the English analyzer:

```bash
curl -XPUT 127.0.0.1:9200/movies -d '
{
  "mappings": {
    "properties": {
      "id": { "type": "integer" },
      "year": { "type": "date" },
      "genre": { "type": "keyword" },
      "title": { "type": "text", "analyzer": "english" }
    }
  }
}'
```

Re-import the data from the bulk file that should still be sitting in your home directory:

```bash
/usr/bin/curl -H "Content-Type: application/x-ndjson" -XPUT '127.0.0.1:9200/_bulk?pretty' --data-binary @movies.json
```

## Verifying the new behavior

| Query on `genre` | Result | Why |
| --- | --- | --- |
| `"sci"` | no hits | keyword fields need the exact value |
| `"sci-fi"` | no hits | exact means case-sensitive too |
| `"Sci-Fi"` | hits | exact match — works |

And the title field still behaves like an analyzed field should: searching `star wars` (lowercase) returns both Star Wars and Star Trek movies, with Star Wars scoring far higher. Partial matches allowed, case irrelevant, relevance on top.

## Key takeaways

- `text` → analyzed: partial, case-insensitive, relevance-ranked matching. `keyword` → exact, case-sensitive matching only.
- Dynamic mapping makes every string analyzed text by default — often wrong for categories, tags, and IDs.
- Changing a field's mapping means deleting and recreating the index, then re-importing — decide your mappings up front.
- A per-field `analyzer` (like `english`) adds language-specific stemming, stop words, and synonyms to text fields.

<div class="chapter-nav">
<a class="chapter-nav__item" href="011-dealing-with-concurrency.html"><span>Previous</span><strong>11. Dealing with Concurrency</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="013-data-modeling-and-parent-child-relationships-part-1.html"><span>Next</span><strong>13. Data Modeling and Parent/Child Relationships, Part 1</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
