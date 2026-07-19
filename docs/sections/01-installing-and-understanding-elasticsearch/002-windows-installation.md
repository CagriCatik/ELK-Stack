---
title: "Windows companion: Installing the Elastic Stack"
hide:
  - toc
---

<div class="chapter-kicker">SECTION 01 · WINDOWS COMPANION</div>

# Installing the Elastic Stack on Windows

The main installation chapter uses Ubuntu because the later command-line exercises assume a Linux environment. If you prefer a native Windows setup, this companion guide takes you from an empty machine to a local, TLS-secured Elasticsearch, Kibana, and Logstash installation.

The examples use version **9.4.3**. Substitute the version you download, and use that same version for all three products. Kibana should match Elasticsearch exactly; keeping Logstash on the same Stack version also makes a fresh installation easier to reason about.

## Before you begin

Use a current, supported 64-bit edition of Windows. You do not normally need to install Java or Node.js separately: Elasticsearch and Logstash include a tested JDK, while Kibana includes its own Node.js runtime.

Create a short installation path to avoid trouble with spaces, permissions, and long filenames:

```text
C:\Elastic\
├── elasticsearch-9.4.3\
├── kibana-9.4.3-windows-x86_64\
└── logstash-9.4.3\
```

Install and start the products in this order:

```text
Elasticsearch → Kibana → Logstash
```

Stop them in reverse order.

## 1. Install Elasticsearch

Download the Windows `x86_64` ZIP from Elastic, extract it to `C:\Elastic`, and open PowerShell:

```powershell
cd C:\Elastic\elasticsearch-9.4.3
.\bin\elasticsearch.bat
```

The first start may take a minute. Elasticsearch stays in the foreground and automatically configures its security features, including:

- TLS certificates and HTTPS for the REST API
- a password for the `elastic` user
- an enrollment token for Kibana
- certificates under `config\certs`

Save the generated password and enrollment token from the console. The token is valid for 30 minutes; create another one if it expires:

```powershell
cd C:\Elastic\elasticsearch-9.4.3
.\bin\elasticsearch-create-enrollment-token.bat -s kibana
```

If you lose the `elastic` password, reset it with:

```powershell
.\bin\elasticsearch-reset-password.bat -u elastic
```

### Verify Elasticsearch

Leave Elasticsearch running and open a second PowerShell window:

```powershell
cd C:\Elastic\elasticsearch-9.4.3

curl.exe `
  --cacert .\config\certs\http_ca.crt `
  -u elastic `
  https://localhost:9200
```

Enter the `elastic` password when prompted. A successful response includes the node name, cluster name, version, and the `You Know, for Search` tagline.

This Windows setup deliberately keeps the default security enabled. When later course examples use plain `http://127.0.0.1:9200`, use `https://localhost:9200` with your credentials and CA certificate instead.

## 2. Install Kibana

Extract the matching Kibana ZIP to `C:\Elastic\kibana-9.4.3-windows-x86_64`. Keep Elasticsearch running, then start Kibana in another PowerShell window:

```powershell
cd C:\Elastic\kibana-9.4.3-windows-x86_64
.\bin\kibana.bat
```

Open the setup link printed in the console and paste in the Kibana enrollment token. Then sign in with the `elastic` user and the password saved during the Elasticsearch setup.

Kibana is available at:

```text
http://localhost:5601
```

Open **Management → Dev Tools** and verify the connection:

```http
GET /
```

```http
GET _cluster/health
```

A single-node learning cluster may report `yellow`: replica shards cannot be placed on the same node as their primary. That is expected here, not an installation failure.

## 3. Install Logstash

Extract the matching Logstash ZIP to `C:\Elastic\logstash-9.4.3`. Logstash must trust the certificate authority Elasticsearch created on first start, so copy the CA certificate into its configuration tree:

```powershell
New-Item `
  -ItemType Directory `
  -Force `
  C:\Elastic\logstash-9.4.3\config\certs

Copy-Item `
  C:\Elastic\elasticsearch-9.4.3\config\certs\http_ca.crt `
  C:\Elastic\logstash-9.4.3\config\certs\http_ca.crt
```

### Create a dedicated Logstash user

Do not use the `elastic` administrator account for a long-running pipeline. In Kibana Dev Tools, create a role limited to the pipeline's indices:

```http
POST _security/role/logstash_writer
{
  "cluster": [
    "manage_index_templates",
    "monitor",
    "manage_ilm"
  ],
  "indices": [
    {
      "names": ["logstash-*"],
      "privileges": [
        "write",
        "create",
        "create_index",
        "manage",
        "manage_ilm"
      ]
    }
  ]
}
```

Then create the user. Replace the example password with a strong one of your own:

```http
POST _security/user/logstash_internal
{
  "password": "choose-a-strong-password",
  "roles": ["logstash_writer"],
  "full_name": "Internal Logstash User"
}
```

The built-in `logstash_system` user is for monitoring; it is not the account a pipeline should use to write events.

### Create a first pipeline

Create `C:\Elastic\logstash-9.4.3\pipeline\demo.conf`:

```text
input {
  stdin { }
}

filter {
}

output {
  stdout {
    codec => rubydebug
  }

  elasticsearch {
    hosts => ["https://localhost:9200"]
    index => "logstash-demo-%{+YYYY.MM.dd}"
    user => "logstash_internal"
    password => "${LOGSTASH_INTERNAL_PASSWORD}"
    ssl_enabled => true
    ssl_certificate_authorities => [
      "C:/Elastic/logstash-9.4.3/config/certs/http_ca.crt"
    ]
  }
}
```

Forward slashes are usually easier than backslashes inside Logstash configuration files on Windows.

### Validate and run the pipeline

Set the password only for the current PowerShell session, then validate the configuration before starting it:

```powershell
$env:LOGSTASH_INTERNAL_PASSWORD = 'choose-a-strong-password'

cd C:\Elastic\logstash-9.4.3

.\bin\logstash.bat `
  --config.test_and_exit `
  -f .\pipeline\demo.conf
```

After Logstash reports `Configuration OK`, run the pipeline:

```powershell
.\bin\logstash.bat -f .\pipeline\demo.conf
```

Wait for startup to complete, type `Hello Elastic Stack`, and press Enter. Logstash should print the event and send it to Elasticsearch.

### Find the event in Kibana

In Kibana Dev Tools, run:

```http
GET logstash-demo-*/_search
{
  "query": {
    "match_all": {}
  }
}
```

To explore the data visually, create a `logstash-demo-*` data view under **Stack Management → Data Views**, select `@timestamp` as its time field, and open **Analytics → Discover**.

## Optional: run Elasticsearch as a Windows service

Complete the first interactive start before installing the service; that first run creates the security configuration and credentials. Stop Elasticsearch with `Ctrl+C`, open PowerShell as Administrator, and run:

```powershell
cd C:\Elastic\elasticsearch-9.4.3

.\bin\elasticsearch-service.bat install
.\bin\elasticsearch-service.bat manager
.\bin\elasticsearch-service.bat start
```

The service commands are:

```powershell
.\bin\elasticsearch-service.bat start
.\bin\elasticsearch-service.bat stop
.\bin\elasticsearch-service.bat remove
```

Kibana and Logstash do not include an equivalent Windows service installer. For a learning machine, starting their `.bat` launchers manually keeps the setup transparent. For a persistent installation, use a Windows service wrapper only after you have tested each command and pipeline interactively.

## Configuration map

| Component | File | Purpose |
| --- | --- | --- |
| Elasticsearch | `config\elasticsearch.yml` | Cluster, network, paths, and security |
| Elasticsearch | `config\jvm.options.d\*.options` | JVM and heap overrides |
| Kibana | `config\kibana.yml` | Server and Elasticsearch connection |
| Logstash | `config\logstash.yml` | Global Logstash settings |
| Logstash | `config\pipelines.yml` | Multiple pipeline definitions |
| Logstash | `pipeline\*.conf` | Pipeline inputs, filters, and outputs |

Elasticsearch sizes its JVM heap automatically. Leave that default in place for an initial local installation.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| `localhost:9200` does not respond | Use `https://localhost:9200`, not HTTP, and provide the credentials and `http_ca.crt`. |
| Kibana rejects the enrollment token | It may have expired; generate a new one with `elasticsearch-create-enrollment-token.bat -s kibana`. |
| Logstash reports `PKIX path building failed` | Confirm `ssl_certificate_authorities` points to the copied `http_ca.crt`. |
| Logstash reports `401 Unauthorized` | Check the username, password environment variable, role, and permissions for `logstash-*`. |
| PowerShell reports an execution-policy problem | The Elastic launchers used here are `.bat` files, so the policy for `.ps1` files normally does not apply. |
| Port 9200 or 5601 is already occupied | Find the listener with `Get-NetTCPConnection -LocalPort 9200` or `Get-NetTCPConnection -LocalPort 5601`, then inspect its PID with `Get-Process -Id <PID>`. |

## Daily startup sequence

Use three PowerShell windows and start the components in order:

```powershell
# Window 1
cd C:\Elastic\elasticsearch-9.4.3
.\bin\elasticsearch.bat
```

```powershell
# Window 2
cd C:\Elastic\kibana-9.4.3-windows-x86_64
.\bin\kibana.bat
```

```powershell
# Window 3
$env:LOGSTASH_INTERNAL_PASSWORD = 'choose-a-strong-password'
cd C:\Elastic\logstash-9.4.3
.\bin\logstash.bat -f .\pipeline\demo.conf
```

You now have a complete local Elastic Stack whose internal connections use TLS and dedicated credentials.

## Official references

- [Install Elasticsearch from a ZIP archive on Windows](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-with-zip-on-windows)
- [Install Kibana on Windows](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-kibana-on-windows)
- [Secure the Logstash connection to Elasticsearch](https://www.elastic.co/docs/reference/logstash/secure-connection)
- [Run Logstash on Windows](https://www.elastic.co/docs/reference/logstash/running-logstash-windows)
- [Elastic support matrix](https://www.elastic.co/support/matrix)

<div class="chapter-nav">
<a class="chapter-nav__item" href="002-installing-elasticsearch-step-by-step.html"><span>Previous</span><strong>2. Installing Elasticsearch [Step by Step]</strong></a>
<a class="chapter-nav__item chapter-nav__item--next" href="003-elasticsearch-overview.html"><span>Next</span><strong>3. Elasticsearch Overview</strong></a>
</div>

<p class="back-to-section"><a href="index.html">← Back to Section 1</a></p>
