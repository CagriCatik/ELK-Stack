---
title: "4. [Exercise] Exploring Data with Kibana"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 06 · EXERCISE</div>

# 4. [Exercise] Exploring Data with Kibana

Now that you know how Data Views, Discover, KQL, and Dev Tools Console work, put them together on the `movies` dataset.

## Your task

1. **Create a Data View** named `movies` matching the `movies` index (without a time filter).
2. **Open Discover**, select the `movies` Data View, and add `title`, `genre`, and `year` as visible table columns so you can scan results without expanding `_source`.
3. **Filter with KQL** to find all movies that:
   - Include the genre `Sci-Fi`
   - Were released between `1990` and `1999` (inclusive)
   - Do **not** include the genre `Horror`
4. **Inspect field statistics** in the left sidebar for `genre` (or `genre.keyword`, depending on your mapping) to see the top co-occurring genres among 1990s Sci-Fi films.
5. **Verify in Dev Tools Console** by running the equivalent Elasticsearch Query DSL `bool` query and confirming the hit count matches Discover.

## Walkthrough

<details>
<summary>Show solution</summary>

1. **Create the Data View:**
   - Open **Stack Management → Data Views → Create data view**.
   - Set **Name** to `movies` and **Index pattern** to `movies`.
   - Under **Timestamp field**, choose **I don't want to use the time filter**, then click **Save data view to Kibana**.

2. **Configure Discover columns:**
   - Open **Analytics → Discover** and select `movies` from the Data View dropdown at the top left.
   - In the left **Available fields** sidebar, hover over `title`, `genre`, and `year` and click the **+** icon to promote them into the table columns.

3. **Run the KQL filter:**
   In the Discover search bar, enter:

   ```text
   genre: Sci-Fi and year >= 1990 and year <= 1999 and not genre: Horror
   ```

   Press **Enter** (or click **Update**). Note the total hits shown above the results table.

4. **Check co-occurring genres:**
   In the left sidebar, click on `genre.keyword` (or `genre` if mapped as `keyword`). Kibana displays the top 5 values (such as `Action`, `Adventure`, `Thriller`) and their percentage of the filtered result set.

5. **Verify in Dev Tools Console:**
   Open **Management → Dev Tools** and run:

   ```json
   GET movies/_search
   {
     "track_total_hits": true,
     "size": 5,
     "query": {
       "bool": {
         "filter": [
           { "term": { "genre.keyword": "Sci-Fi" } },
           { "range": { "year": { "gte": 1990, "lte": 1999 } } }
         ],
         "must_not": [
           { "term": { "genre.keyword": "Horror" } }
         ]
       }
     }
   }
   ```

   > **Note.** If your `movies` mapping stores `genre` as `text` without a `.keyword` subfield, use `"match": { "genre": "Sci-Fi" }` and `"match": { "genre": "Horror" }` instead of `"term"` on `genre.keyword`.

   The `hits.total.value` returned by Elasticsearch should match the hit count shown in Discover.

</details>

## Why this matters

In real investigations—whether debugging a production incident or auditing product catalog data—analysts start in **Discover** with KQL to isolate a slice of documents, inspect sidebar distributions to spot anomalies, and then drop into **Dev Tools** to turn that ad-hoc filter into a reproducible Query DSL payload for an application or alert rule.

<div class="chapter-nav">
<a class="chapter-nav__item" href="003-playing-with-kibana.html"><span>Previous</span><strong>3. Playing with Kibana</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="005-kibana-lens.html"><span>Next</span><strong>5. Kibana Lens</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 7</a></p>
