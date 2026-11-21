# Extending XML Insight Lab with Another XML Format

XML Insight Lab separates **XML parsing/mapping** (`logstash/pipeline/xml-insight.conf`) from **validation and normalization** (`logstash/ruby/normalize_report.rb`). You do not need a generic plugin framework to onboard a second XML report format.

## Recommended Pattern

1. **Define a dedicated schema & template:**
 - Add `schemas/<format>-v1.xsd`and an example under `examples/`.
 - Add explicit Elasticsearch index templates under `elasticsearch/templates/`with `"dynamic": "strict"`.
2. **Add an envelope tag or route:**
 - Have the uploader (or an HTTP header/path like `/ingest/<format>`) set a `report_format`field in the JSON envelope, or detect the root element in Logstash.
3. **Add a dedicated Logstash pipeline in `logstash/config/pipelines.yml`:**
 - Route the new format to its own `logstash/pipeline/<format>.conf`and `logstash/ruby/normalize_<format>.rb`(keep each normalizer small, stateless, and worker-safe).
4. **Reuse the Python uploader & verifier:**
 - The uploader already sends raw XML inside a JSON envelope without pre-parsing, so only the target Logstash port/path and verification index names need to be passed as CLI arguments.
