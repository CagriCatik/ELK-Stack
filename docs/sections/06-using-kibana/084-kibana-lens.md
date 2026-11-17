---
title: "84. Kibana Lens"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 06</div>

# 84. Kibana Lens

**Kibana Lens** is Kibana's primary drag-and-drop visualization editor. Instead of choosing a chart type up front and locking yourself into rigid aggregation forms, Lens lets you drag fields onto a canvas, previews the aggregation live, and lets you switch between bar, line, area, pie, donut, table, and metric views with a single click.

## How Lens maps fields to Elasticsearch aggregations

Every Lens chart is backed by standard Elasticsearch bucket and metric aggregations:

| Lens concept | Elasticsearch equivalent | Example on `movies` |
| :--- | :--- | :--- |
| **Horizontal axis / Slice by** | Bucket aggregation (`terms`, `histogram`, `date_histogram`) | `year` with interval `10` (decades) |
| **Vertical axis / Metric** | Metric aggregation (`count`, `avg`, `sum`, `cardinality`, `percentile`) | `Count of records` or `Unique count of title.keyword` |
| **Break down by** | Sub-bucket aggregation (`terms`) | Top 5 values of `genre.keyword` |
| **Filter (KQL)** | `bool.filter` around the aggregation | `year >= 1970` |

> **Tip.** If a field does not appear as aggregatable in the Lens sidebar, check its mapping. Pure `text` fields have `fielddata: false` by default and cannot be aggregated—use the `.keyword` subfield (`genre.keyword`) instead.

## Building a chart in Lens

1. Open **Analytics → Visualize Library → Create visualization → Lens** (or click **Visualize** directly from a field in Discover).
2. Select the `movies` Data View from the top-left dropdown.
3. Drag `year` to the **Horizontal axis** (Lens automatically chooses a numeric `histogram` bucket; click the axis pill to set a clean **Minimum interval** such as `5` or `10` years).
4. Leave the **Vertical axis** as `Count of records`, or drag `genre.keyword` into **Break down by** to turn the bar chart into a stacked bar chart showing genres per decade.
5. Switch the chart type in the top-center selector (e.g., **Bar vertical stacked**, **Area**, or **Line**) to see which layout tells the story best.

## Using Lens Formula

Simple counts and averages only go so far. **Lens Formula** lets you write arithmetic and ratio expressions across multiple aggregations—such as error rates, cache hit ratios, or percentage share—without writing scripted Painless fields.

In the **Vertical axis** configuration, switch from **Quick functions** to **Formula** and try:

```text
count(kql='genre.keyword: "Sci-Fi"') / count()
```

Format the result as **Percent** under **Value format** to plot the exact share of Sci-Fi movies per decade, rather than raw counts.

Other common Formula patterns in operational dashboards:

- **HTTP 5xx error rate:** `count(kql='http.response.status_code >= 500') / count()`
- **Week-over-week delta:** `count() - count(shift='7d')`
- **Moving average:** `moving_average(average(response_time_ms), window=5)`

## Saving to a Dashboard

Click **Save and return** (or **Save**), give the panel a title, and add it to a new or existing **Dashboard**. Dashboards share a single global KQL search bar and time picker across all panels, and clicking any bar or legend item in a Lens panel applies an interactive filter across the entire dashboard.

## Key takeaways

- **Kibana Lens** translates drag-and-drop field placements into Elasticsearch bucket and metric aggregations in real time.
- Categorical breakdowns require `keyword` (or numeric/date) fields—use `.keyword` subfields when `text` fields are not aggregatable.
- **Lens Formula** enables ratios, filtered counts, and time-shifted comparisons (`shift='7d'`) directly in the UI without Painless scripts.

<div class="chapter-nav">
<a class="chapter-nav__item" href="083-exercise-exploring-data-with-kibana.html"><span>Previous</span><strong>83. [Exercise] Exploring Data with Kibana</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="085-kibana-management.html"><span>Next</span><strong>85. Kibana Management</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 6</a></p>
