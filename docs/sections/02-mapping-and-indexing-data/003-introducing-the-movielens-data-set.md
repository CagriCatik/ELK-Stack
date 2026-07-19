---
title: "3. Introducing the MovieLens Data Set"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02</div>

# 3. Introducing the MovieLens Data Set

The hands-on work in this knowledge base uses **MovieLens**, a free data set of movie ratings built up over many years at [movielens.org](https://movielens.org) — think of rating movies on Netflix and getting recommendations back. It is a great playground because it mixes **textual data** (movie titles) with **structured data** (ratings, release years, genres).

## Getting the data

The data sets are hosted at [grouplens.org](https://grouplens.org) under *Datasets*, free for education and research use. Different sizes are available; since this is a single-machine learning setup rather than big data, use the one recommended for education and development:

- **ml-latest-small.zip** — about **100,000 ratings** sampled from the full data set.

Download it and skim the included `README.html`, which documents the file formats.

## What's inside

To keep the data anonymous and compact, users and movies are both identified by numeric IDs, with a separate file mapping movie IDs to names:

| File | Contents |
| --- | --- |
| `ratings.csv` | 100,000 rows: user ID, movie ID, rating, and a timestamp of when the rating was made |
| `movies.csv` | Maps each movie ID to its title and a pipe-separated list of genres |
| `tags.csv` | Free-text tags users have applied to movies — handy for text experiments later |
| `links.csv` | Maps movie IDs to IMDb/TMDb IDs (not used here, but useful for joining to external data) |

Opening `movies.csv` in Excel or any CSV viewer, you'll see for example that movie ID **1** is *Toy Story*, with the genres Adventure, Animation, Children, Comedy, and Fantasy — note that **a movie can have multiple genres**, which matters when we design its mapping.

## What it's for

This data gets loaded into the virtual machine later and used throughout the knowledge base: indexing it, searching it ("find all the action movies…"), aggregating ratings, and more. For now, the goal is just to be familiar with the shape of the data before playing with it.

## Key takeaways

- MovieLens (from GroupLens) provides free movie-ratings data; the small ~100k-rating set is right for learning on one machine.
- Users and movies are numeric IDs; `movies.csv` joins IDs to titles and genres.
- The mix of text (titles, tags) and structure (ratings, years, genres) exercises both sides of Elasticsearch.

<div class="chapter-nav">
<a class="chapter-nav__item" href="002-connecting-to-your-cluster.html"><span>Previous</span><strong>2. Connecting to your Cluster</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="004-analyzers.html"><span>Next</span><strong>4. Analyzers</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
