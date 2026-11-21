# Kibana Dashboards & Tabellen: Begriffe, Unterschiede und eigene Anpassung

Diese Dokumentation erklärt, **wie die Bausteine in Kibana offiziell heißen**, **warum manche Tabellen wie unübersichtliche Rohdaten aussehen** und **wie du Dashboards, Tabellen und Fehlerregeln selbst anpassen kannst**.

---

## 1. Wie heißen die Dinge in Kibana tatsächlich – und wo liegt der Unterschied?

In Kibana gibt es zwei völlig unterschiedliche Arten, eine Tabelle auf einem Dashboard darzustellen:

| Eigenschaft | 1. Discover Saved Search (`type: "search"`) | 2. Lens Data Table (`type: "lens"`, `visualizationType: "lnsDatatable"`) |
| :--- | :--- | :--- |
| **Kibana-Begriff in der UI** | **Discover** / **Saved Search** („Gespeicherte Suche“) | **Lens → Table** („Lens-Datentabelle“) |
| **Was zeigt eine Zeile?** | **Ein einzelnes Rohdokument** (`1 Zeile = 1 JSON-Event` in Elasticsearch) | **Eine aggregierte Gruppe** (z. B. gruppiert nach `Bench`, `Suite`, `Error Category`) |
| **Spalte `@timestamp`** | Wird von Kibana standardmäßig links mit Aufklapp-Pfeil (`>`) erzwungen | **Kein `@timestamp`** – nur die Spalten, die du explizit definierst |
| **Spaltenköpfe** | Technische Feldnamen (`test_case.name`, `extracted_error_codes`) + Typ-Icons (`k`, `t`, `#`) | Saubere, frei wählbare Namen (`customLabel: true`, z. B. `TestCase`, `Failures`) |
| **Berechnungen / Summen** | **Nicht möglich** (keine Summen, keine Anzahl, keine Quoten) | **Voll unterstützt** (`Count`, `Sum`, `Unique count`, gefilterte Metriken) |
| **Wann sinnvoll?** | Nur für rohes Log-Debugging in *Discover* | **Standard für alle Dashboard-Tabellen** |

> **Kurz gesagt:** Wenn eine Tabelle „primitiv“ oder „wie Rohdaten“ aussieht, war sie eine **Discover Saved Search (`type: "search"`)**. Alle Tabellen auf unseren 11 Dashboards sind jetzt auf **Lens Data Tables (`lnsDatatable`)** umgestellt.

---

### Weitere offizielle Kibana-Begriffe im Projekt

- **Data View** (im NDJSON technisch `type: "index-pattern"`):
  Bindet einen Elasticsearch-Index an Kibana an. In unserem Projekt gibt es **7 Data Views**:
  1. `xml-insight-runs-v1` (`xml-insight-runs-v1*`) – **1 Dokument pro XML-Report / Testlauf**
  2. `xml-insight-suites-v1` (`xml-insight-suites-v1*`) – **1 Dokument pro Suite-Ausführung**
  3. `xml-insight-testcases-v1` (`xml-insight-testcases-v1*`) – **1 Dokument pro TestCase** (`phase: "suite"` oder `phase: "deinit"`)
  4. `xml-insight-steps-v1` (`xml-insight-steps-v1*`) – **1 Dokument pro Testschritt (`<step>`)**
  5. `xml-insight-messages-v1` (`xml-insight-messages-v1*`) – **1 Dokument pro Meldung (`<msg>`) oder `<errors>`-Eintrag**
  6. `xml-insight-errors-v1` (`xml-insight-errors-v1*`) – **Dedizierte Fehlerdokumente**
  7. `xml-insight-plan-status-v1` (`xml-insight-plan-status-v1*`) – **Soll-/Ist-Vergleich gegen den Nightly-Testplan**
- **Lens Visualization (`type: "lens"`)**:
  Moderne Visualisierungs-Engine in Kibana. Wichtige Typen (`visualizationType`):
  - `lnsDatatable`: Aggregierte Datentabelle (**Table**)
  - `lnsMetric`: Einzelne KPI-Kachel (**Metric**)
  - `lnsXY`: Balken- oder Liniendiagramm (**Bar vertical stacked**, **Bar horizontal**)
  - `lnsPie`: Donut- oder Sunburst-Diagramm (**Pie / Donut**)
- **KQL (Kibana Query Language)**:
  Die Filtersprache oben im Dashboard oder in einzelnen Panels, z. B.:
  ```text
  phase : "suite" and normalized_result : ("FAILED" or "ERROR")
  ```

---

## 2. Wo sind die Dateien im Projekt gespeichert?

Alle relevanten Konfigurationen liegen im Ordner `project/`:

| Datei / Pfad | Funktion |
| :--- | :--- |
| `project/kibana/provisioning/xml-insight-dashboard.ndjson` | **Zentrale Kibana-Definition:** Enthält alle 7 Data Views, alle Lens-Tabellen/Diagramme und alle 11 Dashboards (1 Zeile = 1 JSON-Objekt im NDJSON-Format). |
| `project/config/error_mapping.yaml` | **Fehlerklassifizierungs-Regeln:** Definiert, welcher Fehlercode oder Text welcher `category`, `severity`, `disposition`, `root_cause` und `owner` zugeordnet wird. |
| `project/logstash/ruby/normalize_report.rb` | **XML-Normalizer:** Zerlegt jeden XML-Report in Run-, Suite-, TestCase-, Step- und Message-Dokumente und ruft die Error-Mapping-Engine auf. |
| `project/elasticsearch/templates/index-templates.json` | **Elasticsearch-Mappings:** Legt die Datentypen (`keyword`, `integer`, `date`, `boolean`) für alle 7 Indexfamilien fest. |
| `project/scripts/reprocess.sh` | Löscht die bestehenden Indizes und verarbeitet alle XML-Reports mit geänderten Regeln aus `error_mapping.yaml` komplett neu. |

---

## 3. Wie kann ich Tabellen & Dashboards selbst anpassen?

Du hast zwei Wege: **Direkt per Klick in der Kibana-UI** (am einfachsten zum Ausprobieren) oder **über die Datei `xml-insight-dashboard.ndjson`** (reproduzierbar im Git-Repository).

### Weg A: Direkt in der Kibana-Weboberfläche (Drag & Drop)

1. Öffne das gewünschte Dashboard unter `http://127.0.0.1:5601/app/dashboards`.
2. Klicke oben rechts auf **Edit** (Bearbeiten).
3. Klicke bei der Tabelle oder dem Diagramm oben rechts auf das **Zahnrad-Icon → Edit visualization** (in Lens öffnen).
4. **In Kibana Lens anpassen:**
   - **Links** wählst du die **Data View** (z. B. `xml-insight-testcases-v1*`) und siehst alle verfügbaren Felder.
   - **Rechts unter „Rows“ (Zeilen-Dimensionen)** legst du fest, wonach gruppiert wird (z. B. `test_bench.id`, `suite.name`, `error_mapping.category`).
     - Klicke auf eine Dimension → aktiviere **Custom label**, um einen sauberen Spaltennamen (z. B. `Bench` statt `Top 10 values of test_bench.id`) zu vergeben.
     - Unter **Advanced → Include missing values** (`missingBucket: true`) kannst du einstellen, dass auch Zeilen angezeigt werden, bei denen das Feld leer ist.
   - **Rechts unter „Metrics“ (Kennzahlen)** legst du die berechneten Zahlenspalten fest (z. B. `Count`, `Sum of regular_tc_failed`, `Unique count of run.id`).
5. Klicke oben rechts auf **Save and return** und danach im Dashboard auf **Save**.

> **Wichtig zur Persistenz:** Wenn du `./scripts/reset.sh` ausführst oder den Stack neu aufsetzt, wird `project/kibana/provisioning/xml-insight-dashboard.ndjson` importiert. Wenn du UI-Änderungen dauerhaft im Git-Repo sichern willst, exportiere sie unter **Stack Management → Saved Objects → Export** als `.ndjson` und speichere sie unter `project/kibana/provisioning/xml-insight-dashboard.ndjson`.

---

### Weg B: Direkt in `xml-insight-dashboard.ndjson` anpassen und provisionieren

In `project/kibana/provisioning/xml-insight-dashboard.ndjson` steht pro Zeile ein JSON-Objekt.

1. **Spaltenüberschrift oder Feld einer Lens-Tabelle (`lnsDatatable`) ändern:**
   Jede Spalte in `state.datasourceStates.formBased.layers.l1.columns` hat folgende Struktur:
   - **Gruppierungsspalte (`terms`):**
     ```json
     "c1": {
       "label": "Software Version",
       "customLabel": true,
       "dataType": "string",
       "operationType": "terms",
       "sourceField": "software.version",
       "isBucketed": true,
       "scale": "ordinal",
       "params": {
         "size": 15,
         "orderBy": { "type": "alphabetical", "fallback": true },
         "orderDirection": "asc",
         "missingBucket": true,
         "otherBucket": false
       }
     }
     ```
   - **Kennzahlenspalte (`count`, `sum`, `unique_count`):**
     ```json
     "m1": {
       "label": "Failed TestCases",
       "customLabel": true,
       "dataType": "number",
       "operationType": "sum",
       "sourceField": "regular_tc_failed",
       "isBucketed": false,
       "scale": "ratio"
     }
     ```
2. **Änderungen in Kibana einspielen (ohne Datenverlust in Elasticsearch):**
   ```bash
   cd project
   docker compose run --rm tools provision-kibana
   ```
   Dieser Befehl überschreibt die Saved Objects in Kibana sofort (`overwrite=true`). Danach einfach die Browserseite neu laden.

---

## 4. Welches Feld existiert in welcher Data View? (Spickzettel)

Ein häufiger Fehler in Kibana ist die Meldung `Field "..." was not found`, wenn man ein Feld in einer Data View abfragt, in der es gar nicht existiert. Hier sind die wichtigsten Felder pro Data View:

| Data View | Wichtige Dimensionen (`terms`) | Wichtige Kennzahlen (`sum` / `count`) |
| :--- | :--- | :--- |
| **`xml-insight-runs-v1*`** | `run.id`, `campaign.id`, `test_bench.id`, `software.version`, `normalized_result`, `init_normalized_result`, `deinit_normalized_result`, `data_quality_issues` | `suite_count`, `regular_tc_total`, `regular_tc_passed`, `regular_tc_failed`, `regular_tc_error`, `deinit_tc_total`, `deinit_tc_failed` |
| **`xml-insight-suites-v1*`** | `run.id`, `test_bench.id`, `software.version`, `suite.name`, `normalized_result` | `tc_total`, `tc_passed`, `tc_failed`, `tc_error`, `tc_skipped` |
| **`xml-insight-testcases-v1*`** | `run.id`, `test_bench.id`, `software.version`, `phase` (`suite`/`deinit`), `suite.name`, `test_case.name`, `normalized_result`, `error_mapping.category`, `error_mapping.rule_id`, `error_mapping.root_cause`, `error_mapping.disposition`, `error_mapping.owner`, `error_mapping.severity`, `extracted_error_codes` | `step_count`, `failed_step_count`, `fault_count`, `error_msg_count` |
| **`xml-insight-steps-v1*`** | `run.id`, `test_bench.id`, `suite.name`, `test_case.name`, `step.name`, `normalized_result`, `error_mapping.category`, `error_mapping.rule_id`, `extracted_error_codes` | `step.sequence` |
| **`xml-insight-messages-v1*`** | `run.id`, `phase`, `origin_context` (`group_msg`/`step_msg`/`errors_block`), `test_case.name`, `level` (`info`/`warning`/`error`), `original_text.keyword`, `error_mapping.category`, `error_mapping.rule_id` | `position` |
| **`xml-insight-plan-status-v1*`** | `campaign.id`, `test_bench.id`, `receipt_status`, `suite_completeness`, `missing_suites`, `run_result` | `is_late` |

---

## 5. Wie passe ich die Fehlerklassifizierung (`error_mapping.yaml`) an?

Wenn du neue Fehlercodes oder Fehlermeldungsmuster aufnehmen oder anders kategorisieren möchtest:

1. Öffne `project/config/error_mapping.yaml`.
2. Füge eine neue Regel unter `rules:` hinzu oder passe eine bestehende Regel an:
   ```yaml
   - id: ERR_CUSTOM_TIMEOUT
     enabled: true
     priority: 95
     description: Eigene Timeout-Regel
     match:
       type: regex          # möglich: error_code | exact | contains | regex
       field: message
       patterns:
         - "(?i).*mein_timeout_text.*"
     classification:
       category: TIMEOUT
       severity: HIGH
       disposition: RELEVANT
       root_cause: UI_COMMUNICATION
       owner: APPLICATION
   ```
3. Starte das Reprocessing, damit alle XML-Dateien mit der neuen Regel neu klassifiziert werden:
   ```bash
   cd project
   ./scripts/reprocess.sh
   ```
