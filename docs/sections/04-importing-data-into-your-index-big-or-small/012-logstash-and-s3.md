---
title: "12. Logstash and S3"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 04</div>

# 12. Logstash and S3

Cloud services—such as AWS CloudFront, ALB/ELB access logs, CloudTrail, and application log archives—commonly deliver logs to **Amazon S3** buckets. Logstash's built-in `s3` input plugin polls an S3 bucket, downloads new objects (automatically decompressing `.gz` files), tracks processed objects in a `sincedb` file, and streams their contents through your pipeline.

## Authentication and IAM permissions

Never hardcode long-lived AWS root keys in `.conf` files. Prefer **IAM Instance Profiles** (on EC2) or **IAM Roles for Service Accounts** (on EKS), which Logstash discovers automatically via the AWS SDK credential chain.

If you run Logstash outside AWS, supply dedicated IAM credentials via environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) or Logstash's keystore rather than plaintext.

The IAM role or user needs at least:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::my-app-logs-bucket"]
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::my-app-logs-bucket/alb-logs/*"]
    }
  ]
}
```

## Example S3-to-Elasticsearch pipeline

The following pipeline polls `s3://my-app-logs-bucket/alb-logs/` every 60 seconds, decodes JSON Lines objects, and tracks state in `sincedb`:

```ruby
input {
  s3 {
    bucket => "my-app-logs-bucket"
    prefix => "alb-logs/"
    region => "us-east-1"
    interval => 60
    sincedb_path => "/var/lib/logstash/s3_alb_sincedb"
    codec => "json_lines"
    # If running outside AWS without an IAM role, use keystore/env vars or:
    # access_key_id => "${AWS_ACCESS_KEY_ID}"
    # secret_access_key => "${AWS_SECRET_ACCESS_KEY}"
  }
}

filter {
  mutate {
    remove_field => ["@version"]
  }
}

output {
  elasticsearch {
    hosts => ["https://127.0.0.1:9200"]
    user => "elastic"
    password => "changeme"
    ssl_certificate_authorities => ["/etc/elasticsearch/certs/http_ca.crt"]
    index => "alb-logs-%{+YYYY.MM.dd}"
  }
}
```

## Important operational details

- **Gzip decompression**: Files ending in `.gz` or `.gzip` are decompressed automatically by the `s3` input plugin.
- **How `sincedb` works with S3**: Unlike the `file` input (which stores byte offsets), the `s3` input stores the timestamp of the last processed object (`last_modified`). Only objects newer than that timestamp are fetched on subsequent polls.
- **High-volume buckets**: If your bucket accumulates millions of objects, `s3:ListBucket` polling becomes slow and costly. For high-scale S3 ingestion, configure **S3 Event Notifications -> Amazon SQS** and use Logstash's `sqs` input plugin (or Filebeat's `aws-s3` input) instead of polling `ListBucket`.

## Key takeaways

- Use IAM roles (EC2 instance profiles / IRSA) or environment variables rather than hardcoding AWS keys in `.conf` files.
- Set a dedicated `sincedb_path` per S3 input so restarts do not re-ingest the entire bucket.
- For very large or high-frequency buckets, trigger ingestion via S3 -> SQS notifications rather than polling `ListBucket`.

<div class="chapter-nav">
<a class="chapter-nav__item" href="011-importing-json-data-with-logstash.html"><span>Previous</span><strong>11. Importing JSON Data with Logstash</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="013-parsing-and-filtering-logstash-with-grok.html"><span>Next</span><strong>13. Parsing and Filtering Logstash with Grok</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 4</a></p>
