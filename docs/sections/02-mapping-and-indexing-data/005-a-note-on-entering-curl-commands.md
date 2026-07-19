---
title: "5. A Note on Entering curl Commands"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 02 · NOTE</div>

# 5. A Note on Entering curl Commands

A quick note on how commands are presented from here on.

For the next few sections, everything is done with **raw `curl` commands** against the Elasticsearch REST API — later, once Kibana is introduced, its **Dev Tools** console becomes a friendlier way to do the same thing. Working at the curl level first is deliberate: it shows the low-level API you would use when connecting to Elasticsearch programmatically from an application.

Practical tips for following along:

- **Type the commands yourself.** The syntax sinks in much faster when you type it than when you read it — every chapter shows the full command and its expected output so you can work at your own pace.
- **Watch the quoting.** Request bodies are wrapped in single quotes; JSON inside uses double quotes. Mixing these up is the most common source of errors.
- **The `Content-Type` header is mandatory** whenever a body is sent. The next chapter sets up a small wrapper script that adds it automatically so it never has to be typed again.
- **Longer commands are meant to be copied.** For the more complex requests later in the knowledge base, copy and paste them rather than retyping — the goal is understanding the structure, not typing practice.

<div class="chapter-nav">
<a class="chapter-nav__item" href="004-analyzers.html"><span>Previous</span><strong>4. Analyzers</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="006-import-a-single-movie-via-json-rest.html"><span>Next</span><strong>6. Import a Single Movie via JSON / REST</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 2</a></p>
