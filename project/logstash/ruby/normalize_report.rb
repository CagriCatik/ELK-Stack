# frozen_string_literal: true

require "time"
require "digest"
require "tzinfo"

require_relative "error_mapping/config_loader"
require_relative "error_mapping/matcher"
require_relative "error_mapping/classifier"

MAX_XML_BYTES = 5_242_880
KNOWN_RESULTS = %w[PASSED FAILED ERROR SKIPPED].freeze
KNOWN_MSG_LEVELS = %w[info warning error debug].freeze
BASE_CODE_TOKEN_REGEX = /\b([A-Z][A-Z0-9_]{2,})\b/.freeze
UTC_EXPLICIT_REGEX = /(?:Z|[+-]\d{2}:\d{2})\z/.freeze
NAIVE_ISO_REGEX = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?\z/.freeze

def register(params)
  path = params["error_mapping_path"] || ENV["ERROR_MAPPING_PATH"] || File.expand_path("../../config/error_mapping.yaml", __dir__)
  @mapping_config = ErrorMapping::ConfigLoader.load_file(path)

  # Pre-compute known error_code tokens from config so new error_code rules work without Ruby edits
  codes = @mapping_config.rules
                         .select { |r| r.enabled && r.match_type == "error_code" }
                         .flat_map(&:values)
                         .map(&:upcase)
                         .uniq
  @configured_code_set = codes.each_with_object({}) { |c, h| h[c] = true }.freeze
end

def clean_string(val)
  return nil if val.nil?
  return val["content"].to_s.strip if val.is_a?(Hash) && val.key?("content")
  return nil if val.is_a?(Hash) || val.is_a?(Array)

  s = val.to_s.strip
  s.empty? ? nil : s
end

def normalize_array(val)
  return [] if val.nil?
  return val if val.is_a?(Array)
  return [val] if val.is_a?(Hash)

  []
end

def normalize_result(raw)
  return "UNKNOWN" if raw.nil?

  up = raw.upcase
  KNOWN_RESULTS.include?(up) ? up : "UNKNOWN"
end

def parse_positive_int(val)
  s = clean_string(val)
  return nil if s.nil? || !/\A\d+\z/.match?(s)

  n = s.to_i
  n.positive? ? n : nil
end

def parse_duration_seconds_to_ms(val)
  s = clean_string(val)
  return [nil, false] if s.nil?
  return [nil, true] unless /\A\d+(?:\.\d+)?\z/.match?(s)

  ms = (s.to_f * 1000.0).round
  [ms, false]
end

def parse_timestamp_with_tz(raw_str, tz_name)
  s = clean_string(raw_str)
  return [nil, "missing", nil] if s.nil?

  if UTC_EXPLICIT_REGEX.match?(s)
    begin
      t = Time.iso8601(s).utc
      return [t, "explicit_utc", "UTC"]
    rescue ArgumentError
      return [nil, "invalid", nil]
    end
  end

  return [nil, "invalid", nil] unless NAIVE_ISO_REGEX.match?(s)

  begin
    naive = Time.iso8601("#{s}Z")
    tz = TZInfo::Timezone.get(tz_name)
    begin
      utc_t = tz.local_to_utc(naive)
      [utc_t.utc, "assumed_local", tz_name]
    rescue TZInfo::AmbiguousTime
      utc_t = tz.local_to_utc(naive, true)
      [utc_t.utc, "ambiguous_dst", tz_name]
    rescue TZInfo::PeriodNotFound
      [nil, "nonexistent_local_time", tz_name]
    end
  rescue ArgumentError, TZInfo::InvalidTimezoneIdentifier
    [nil, "invalid", tz_name]
  end
end

def extract_error_codes(text, explicit_code = nil)
  codes = []
  codes << explicit_code if explicit_code && !explicit_code.empty?
  if text && !text.empty?
    text.scan(BASE_CODE_TOKEN_REGEX) do |m|
      tok = m[0]
      if @configured_code_set.key?(tok.upcase) || tok.start_with?("SYN_") || tok == "ASSERT_MISMATCH"
        codes << tok
      end
    end
  end
  codes.uniq
end

def build_error_event(stage:, code:, message:, source_file:, file_sha256:, ingested_at:, synthetic:, run_id: "unknown", campaign_id: "unknown", execution_slot_id: nil)
  err_id = "#{file_sha256}::#{code}"
  payload = {
    "@timestamp" => ingested_at,
    "doc_type" => "error",
    "error_stage" => stage,
    "error_code" => code,
    "error_message" => message,
    "campaign" => { "id" => campaign_id },
    "run" => { "id" => run_id },
    "source_file" => source_file,
    "file_sha256" => file_sha256,
    "synthetic" => synthetic,
    "ingested_at" => ingested_at
  }
  payload["execution_slot_id"] = execution_slot_id unless execution_slot_id.nil?

  ev = LogStash::Event.new(payload)
  ev.set("[@metadata][target_index]", "xml-insight-errors-v1")
  ev.set("[@metadata][doc_id]", err_id)
  ev
end

def collect_messages(raw_msgs, origin_context:, base_ctx:, phase:, group_name:, suite_ctx:, tc_ctx:, step_ctx:, msg_counter_start:, ts_iso:, parent_failed: false)
  events = []
  codes_collected = []
  rules_collected = []
  pos = msg_counter_start

  normalize_array(raw_msgs).each do |m|
    text = m.is_a?(Hash) ? clean_string(m["content"]) : clean_string(m)
    next if text.nil?

    pos += 1
    level = m.is_a?(Hash) ? clean_string(m["level"]) : nil
    level = level.downcase if level && KNOWN_MSG_LEVELS.include?(level.downcase)
    explicit_code = m.is_a?(Hash) ? clean_string(m["errorCode"]) : nil
    codes = extract_error_codes(text, explicit_code)
    codes_collected.concat(codes)

    match_ctx = {
      "message" => text,
      "error_codes" => codes,
      "phase" => phase,
      "suite" => suite_ctx ? suite_ctx["name"] : nil,
      "test_case" => tc_ctx ? tc_ctx["name"] : nil
    }
    matched_rules = ErrorMapping::Matcher.match_all(@mapping_config, match_ctx)
    rules_collected.concat(matched_rules)

    is_error_like = parent_failed ||
                    origin_context == "errors_block" ||
                    %w[error warning].include?(level) ||
                    !codes.empty? ||
                    !matched_rules.empty?

    payload = {
      "@timestamp" => ts_iso,
      "doc_type" => "message",
      "synthetic" => base_ctx[:synthetic],
      "campaign" => { "id" => base_ctx[:campaign_id] },
      "run" => { "id" => base_ctx[:run_id] },
      "test_bench" => { "id" => base_ctx[:bench_id] },
      "project" => base_ctx[:project],
      "phase" => phase,
      "origin_context" => origin_context,
      "position" => pos,
      "original_text" => text,
      "source_file" => base_ctx[:source_file],
      "file_sha256" => base_ctx[:file_sha256],
      "ingested_at" => base_ctx[:ingested_at]
    }
    payload["software"] = { "version" => base_ctx[:software_version] } unless base_ctx[:software_version].nil?
    payload["group_name"] = group_name unless group_name.nil?
    payload["suite"] = suite_ctx unless suite_ctx.nil?
    payload["test_case"] = tc_ctx unless tc_ctx.nil?
    payload["step"] = step_ctx unless step_ctx.nil?
    payload["level"] = level unless level.nil?
    payload["extracted_error_codes"] = codes unless codes.empty?
    if is_error_like
      payload["error_mapping"] = ErrorMapping::Classifier.build_result(@mapping_config, matched_rules)
    end

    doc_id = "#{base_ctx[:run_id]}::#{phase}::#{origin_context}::#{suite_ctx ? suite_ctx['name'] : 'run'}::#{tc_ctx ? "#{tc_ctx['execution_id']}_#{tc_ctx['attempt']}" : 'none'}::#{step_ctx ? step_ctx['sequence'] : '0'}::#{pos}"
    ev = LogStash::Event.new(payload)
    ev.set("[@metadata][target_index]", "xml-insight-messages-v1")
    ev.set("[@metadata][doc_id]", Digest::SHA256.hexdigest(doc_id)[0, 32])
    events << ev
  end

  [events, codes_collected.uniq, rules_collected, pos]
end

def filter(event)
  tags = event.get("tags") || []
  raw_xml = event.get("raw_xml")
  source_file = File.basename(clean_string(event.get("source_file")) || "unknown.xml")

  file_sha256 = clean_string(event.get("file_sha256"))
  file_sha256 = Digest::SHA256.hexdigest(raw_xml) if file_sha256.nil? && raw_xml.is_a?(String)
  file_sha256 ||= "missing-sha256"

  synthetic_env = event.get("synthetic_origin")
  synthetic = synthetic_env.nil? ? true : (synthetic_env == true || synthetic_env.to_s == "true")
  source_tz = clean_string(event.get("source_timezone")) || ENV.fetch("SOURCE_TIMEZONE", "Europe/Berlin")

  ingested_t = Time.now.utc
  ingested_at = ingested_t.iso8601(3)

  if tags.include?("_missing_raw_xml") || !raw_xml.is_a?(String)
    return [build_error_event(stage: "envelope", code: "MISSING_RAW_XML", message: "Envelope missing raw_xml.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic)]
  end
  if raw_xml.bytesize > MAX_XML_BYTES
    return [build_error_event(stage: "size_limit", code: "XML_TOO_LARGE", message: "XML exceeds #{MAX_XML_BYTES} bytes.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic)]
  end
  if tags.include?("_dtd_rejected")
    return [build_error_event(stage: "dtd_rejected", code: "DTD_OR_ENTITY_FORBIDDEN", message: "DTD/ENTITY declarations forbidden.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic)]
  end
  if tags.include?("_xmlparsefailure")
    return [build_error_event(stage: "xml_parse", code: "MALFORMED_XML", message: "XML parse failed.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic)]
  end

  doc = event.get("parsed_xml")
  unless doc.is_a?(Hash)
    return [build_error_event(stage: "xml_parse", code: "INVALID_ROOT", message: "Expected <report> root element.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic)]
  end

  bench_id = clean_string(doc["bench"])
  project = clean_string(doc["project"])
  raw_start = clean_string(doc["startTime"])
  raw_end = clean_string(doc["endTime"])

  explicit_run_id = clean_string(doc["id"])
  has_stable_run_id = !explicit_run_id.nil?
  run_id = explicit_run_id || "imp-#{file_sha256[0, 16]}"
  campaign_id = clean_string(doc["campaignId"]) || clean_string(event.get("campaign_id")) || "unassigned"
  slot_id = clean_string(doc["executionSlotId"]) || clean_string(event.get("execution_slot_id"))
  schema_version = clean_string(doc["schemaVersion"]) || "1.0"

  if bench_id.nil? || project.nil? || raw_start.nil? || raw_end.nil?
    return [build_error_event(stage: "validation", code: "MISSING_REPORT_METADATA", message: "Report requires bench, project, startTime, and endTime.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic, run_id: run_id, campaign_id: campaign_id, execution_slot_id: slot_id)]
  end

  started_t, tz_status_start, tz_assumed = parse_timestamp_with_tz(raw_start, source_tz)
  ended_t, tz_status_end, = parse_timestamp_with_tz(raw_end, source_tz)

  if started_t.nil? || ended_t.nil?
    return [build_error_event(stage: "validation", code: "INVALID_REPORT_TIMESTAMP", message: "Invalid or non-existent local timestamp (startTime=#{raw_start}, endTime=#{raw_end}, tz=#{source_tz}, status=#{tz_status_start}/#{tz_status_end}).", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic, run_id: run_id, campaign_id: campaign_id, execution_slot_id: slot_id)]
  end

  run_duration_ms = ((ended_t - started_t) * 1000.0).round
  if run_duration_ms.negative?
    return [build_error_event(stage: "validation", code: "NEGATIVE_REPORT_DURATION", message: "Report endTime precedes startTime.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic, run_id: run_id, campaign_id: campaign_id, execution_slot_id: slot_id)]
  end

  run_source_result = clean_string(doc["result"])
  run_norm_result = normalize_result(run_source_result)
  run_ts_iso = started_t.iso8601(3)

  raw_groups = normalize_array(doc["groups"])
  if raw_groups.empty?
    return [build_error_event(stage: "validation", code: "MISSING_GROUPS", message: "Report must contain at least one <groups> element.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic, run_id: run_id, campaign_id: campaign_id, execution_slot_id: slot_id)]
  end

  init_params = []
  software_version = nil
  init_source_result = nil
  init_norm_result = "UNKNOWN"
  deinit_source_result = nil
  deinit_norm_result = "UNKNOWN"

  raw_groups.each do |g|
    next unless g.is_a?(Hash)

    g_name = clean_string(g["name"])
    if g_name == "initialization"
      init_source_result = clean_string(g["result"])
      init_norm_result = normalize_result(init_source_result)
      normalize_array(g["param"]).each do |p|
        next unless p.is_a?(Hash)
        pn = clean_string(p["name"])
        pv = clean_string(p["value"]) || ""
        next if pn.nil?
        init_params << { "name" => pn, "value" => pv }
        software_version = pv if pn == "SoftwareVersion" && !pv.empty?
      end
      normalize_array(g["group"]).each do |sub|
        next unless sub.is_a?(Hash)
        normalize_array(sub["param"]).each do |p|
          next unless p.is_a?(Hash)
          pn = clean_string(p["name"])
          pv = clean_string(p["value"]) || ""
          next if pn.nil?
          init_params << { "name" => pn, "value" => pv }
          software_version = pv if pn == "SoftwareVersion" && !pv.empty?
        end
      end
    elsif g_name == "deInitialization"
      deinit_source_result = clean_string(g["result"])
      deinit_norm_result = normalize_result(deinit_source_result)
    end
  end

  run_dq_issues = []
  run_dq_issues << "missing_stable_run_id" unless has_stable_run_id
  run_dq_issues << "assumed_source_timezone" if tz_status_start == "assumed_local"
  run_dq_issues << "ambiguous_dst_timestamp" if tz_status_start == "ambiguous_dst" || tz_status_end == "ambiguous_dst"
  run_dq_issues << "missing_init_result" if init_source_result.nil?

  base_ctx = {
    synthetic: synthetic,
    campaign_id: campaign_id,
    run_id: run_id,
    bench_id: bench_id,
    project: project,
    software_version: software_version,
    source_file: source_file,
    file_sha256: file_sha256,
    ingested_at: ingested_at
  }

  suite_events = []
  tc_events = []
  step_events = []
  msg_events = []
  extra_group_names = []
  suite_names = []
  reg_counts = { "PASSED" => 0, "FAILED" => 0, "ERROR" => 0, "SKIPPED" => 0, "UNKNOWN" => 0 }
  deinit_counts = { "total" => 0, "PASSED" => 0, "FAILED" => 0 }
  msg_seq = 0
  suite_seq = 0

  raw_groups.each do |g|
    unless g.is_a?(Hash)
      return [build_error_event(stage: "validation", code: "INVALID_GROUP", message: "Invalid <groups> element.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic, run_id: run_id, campaign_id: campaign_id, execution_slot_id: slot_id)]
    end

    g_name = clean_string(g["name"])
    if g_name.nil?
      return [build_error_event(stage: "validation", code: "MISSING_GROUP_NAME", message: "<groups> missing name attribute.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic, run_id: run_id, campaign_id: campaign_id, execution_slot_id: slot_id)]
    end

    tcs = normalize_array(g["testCase"])
    if g_name == "initialization"
      phase = "init"
    elsif g_name == "deInitialization"
      phase = "deinit"
    elsif !tcs.empty?
      phase = "suite"
    else
      phase = "extra_group"
      extra_group_names << g_name
    end

    m_evs, _, _, msg_seq = collect_messages(
      g["msg"], origin_context: "group_msg", base_ctx: base_ctx, phase: phase,
      group_name: g_name, suite_ctx: nil, tc_ctx: nil, step_ctx: nil,
      msg_counter_start: msg_seq, ts_iso: run_ts_iso
    )
    msg_events.concat(m_evs)

    normalize_array(g["group"]).each do |sub|
      next unless sub.is_a?(Hash)
      sub_name = clean_string(sub["name"]) || g_name
      m_evs, _, _, msg_seq = collect_messages(
        sub["msg"], origin_context: "group_msg", base_ctx: base_ctx, phase: phase,
        group_name: sub_name, suite_ctx: nil, tc_ctx: nil, step_ctx: nil,
        msg_counter_start: msg_seq, ts_iso: run_ts_iso
      )
      msg_events.concat(m_evs)
    end

    next if tcs.empty?

    is_deinit_phase = (phase == "deinit")
    if is_deinit_phase
      suite_id = "deInitialization"
      suite_ctx = { "id" => suite_id, "name" => g_name }
    else
      suite_seq += 1
      suite_names << g_name
      explicit_suite_id = clean_string(g["id"])
      suite_id = explicit_suite_id || g_name
      suite_ver = clean_string(g["version"])
      suite_ctx = { "id" => suite_id, "name" => g_name }
      suite_ctx["version"] = suite_ver unless suite_ver.nil?
    end

    max_attempt_by_tc = {}
    parsed_tcs = []
    tcs.each_with_index do |tc, idx|
      unless tc.is_a?(Hash)
        return [build_error_event(stage: "validation", code: "INVALID_TESTCASE", message: "Invalid <testCase> in #{g_name}.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic, run_id: run_id, campaign_id: campaign_id, execution_slot_id: slot_id)]
      end
      tc_name = clean_string(tc["name"])
      if tc_name.nil?
        return [build_error_event(stage: "validation", code: "MISSING_TESTCASE_NAME", message: "<testCase> missing name in #{g_name}.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic, run_id: run_id, campaign_id: campaign_id, execution_slot_id: slot_id)]
      end
      explicit_tc_id = clean_string(tc["id"])
      tc_id = explicit_tc_id || "imp-#{file_sha256[0, 8]}-#{phase}-#{suite_seq}-#{idx + 1}"
      attempt = parse_positive_int(tc["attempt"]) || 1
      exec_id = clean_string(tc["executionId"]) || "exec-#{phase}-#{suite_seq}-#{idx + 1}"
      prev = max_attempt_by_tc[tc_id] || 0
      max_attempt_by_tc[tc_id] = attempt if attempt > prev
      parsed_tcs << { node: tc, tc_id: tc_id, has_stable_id: !explicit_tc_id.nil?, name: tc_name, attempt: attempt, exec_id: exec_id, seq: idx + 1 }
    end

    s_counts = { "PASSED" => 0, "FAILED" => 0, "ERROR" => 0, "SKIPPED" => 0, "UNKNOWN" => 0 }
    suite_codes = []

    parsed_tcs.each do |ptc|
      tc = ptc[:node]
      tc_src_res = clean_string(tc["result"])
      tc_norm_res = normalize_result(tc_src_res)
      tc_failed = %w[FAILED ERROR].include?(tc_norm_res)
      tc_dur_ms, dur_err = parse_duration_seconds_to_ms(tc["duration"])
      if dur_err
        return [build_error_event(stage: "validation", code: "INVALID_DURATION", message: "Invalid duration '#{tc['duration']}' on testCase '#{ptc[:name]}'.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic, run_id: run_id, campaign_id: campaign_id, execution_slot_id: slot_id)]
      end

      tc_dq = []
      tc_dq << "missing_stable_testcase_id" unless ptc[:has_stable_id]
      tc_dq << "missing_duration" if tc_dur_ms.nil?
      tc_dq << "missing_result" if tc_src_res.nil?

      tc_ctx = {
        "id" => ptc[:tc_id],
        "execution_id" => ptc[:exec_id],
        "attempt" => ptc[:attempt],
        "name" => ptc[:name]
      }

      raw_steps = normalize_array(tc["step"])
      tc_codes = []
      tc_matched_rules = []
      tc_artifacts = []
      failed_steps = 0

      raw_steps.each_with_index do |st, s_idx|
        next unless st.is_a?(Hash)
        st_name = clean_string(st["name"])
        if st_name.nil?
          return [build_error_event(stage: "validation", code: "MISSING_STEP_NAME", message: "<step> missing name in #{ptc[:name]}.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic, run_id: run_id, campaign_id: campaign_id, execution_slot_id: slot_id)]
        end
        st_seq = s_idx + 1
        st_id = clean_string(st["id"]) || "step-#{st_seq}"
        st_src_res = clean_string(st["result"])
        st_norm_res = normalize_result(st_src_res)
        st_failed = %w[FAILED ERROR].include?(st_norm_res)
        failed_steps += 1 if st_failed
        st_dur_ms, st_dur_err = parse_duration_seconds_to_ms(st["duration"])
        return [build_error_event(stage: "validation", code: "INVALID_STEP_DURATION", message: "Invalid step duration on '#{st_name}'.", source_file: source_file, file_sha256: file_sha256, ingested_at: ingested_at, synthetic: synthetic, run_id: run_id, campaign_id: campaign_id, execution_slot_id: slot_id)] if st_dur_err

        step_ctx = { "id" => st_id, "name" => st_name, "sequence" => st_seq }
        st_m_evs, st_codes, st_rules, msg_seq = collect_messages(
          st["msg"], origin_context: "step_msg", base_ctx: base_ctx, phase: phase,
          group_name: g_name, suite_ctx: suite_ctx, tc_ctx: tc_ctx, step_ctx: step_ctx,
          msg_counter_start: msg_seq, ts_iso: run_ts_iso, parent_failed: st_failed
        )
        msg_events.concat(st_m_evs)
        tc_codes.concat(st_codes)
        tc_matched_rules.concat(st_rules)

        st_arts = normalize_array(st["artifact"]).filter_map { |a| a.is_a?(Hash) ? clean_string(a["path"]) : nil }
        tc_artifacts.concat(st_arts)

        st_assertions = normalize_array(st["assertion"]).filter_map do |asrt|
          next unless asrt.is_a?(Hash)
          {
            "name" => clean_string(asrt["name"]) || st_name,
            "expected" => clean_string(asrt["expected"]) || "",
            "actual" => clean_string(asrt["actual"]) || "",
            "operator" => clean_string(asrt["operator"]) || "eq",
            "data_type" => clean_string(asrt["dataType"]) || "string",
            "unit" => clean_string(asrt["unit"]) || "",
            "result" => normalize_result(clean_string(asrt["result"]))
          }
        end

        st_payload = {
          "@timestamp" => run_ts_iso,
          "doc_type" => "step",
          "synthetic" => synthetic,
          "campaign" => { "id" => campaign_id },
          "run" => { "id" => run_id, "normalized_result" => run_norm_result },
          "test_bench" => { "id" => bench_id },
          "project" => project,
          "suite" => suite_ctx,
          "phase" => phase,
          "test_case" => tc_ctx,
          "step" => step_ctx,
          "normalized_result" => st_norm_res,
          "source_file" => source_file,
          "file_sha256" => file_sha256,
          "ingested_at" => ingested_at
        }
        st_payload["software"] = { "version" => software_version } unless software_version.nil?
        st_payload["source_result"] = st_src_res unless st_src_res.nil?
        st_payload["duration_ms"] = st_dur_ms unless st_dur_ms.nil?
        st_payload["extracted_error_codes"] = st_codes unless st_codes.empty?
        st_payload["assertions"] = st_assertions unless st_assertions.empty?
        st_payload["artifact_paths"] = st_arts unless st_arts.empty?
        if st_failed || !st_rules.empty?
          st_payload["error_mapping"] = ErrorMapping::Classifier.aggregate_rules(@mapping_config, st_rules)
        end

        st_ev = LogStash::Event.new(st_payload)
        st_ev.set("[@metadata][target_index]", "xml-insight-steps-v1")
        st_ev.set("[@metadata][doc_id]", "#{run_id}::#{phase}::#{suite_seq}::#{ptc[:exec_id]}::#{ptc[:attempt]}::#{st_seq}")
        step_events << st_ev
      end

      tc_m_evs, tc_direct_codes, tc_direct_rules, msg_seq = collect_messages(
        tc["msg"], origin_context: "testcase_msg", base_ctx: base_ctx, phase: phase,
        group_name: g_name, suite_ctx: suite_ctx, tc_ctx: tc_ctx, step_ctx: nil,
        msg_counter_start: msg_seq, ts_iso: run_ts_iso, parent_failed: tc_failed
      )
      msg_events.concat(tc_m_evs)
      tc_codes.concat(tc_direct_codes)
      tc_matched_rules.concat(tc_direct_rules)

      err_msg_count = 0
      normalize_array(tc["errors"]).each do |eb|
        next unless eb.is_a?(Hash)
        eb_evs, eb_codes, eb_rules, msg_seq = collect_messages(
          eb["msg"], origin_context: "errors_block", base_ctx: base_ctx, phase: phase,
          group_name: g_name, suite_ctx: suite_ctx, tc_ctx: tc_ctx, step_ctx: nil,
          msg_counter_start: msg_seq, ts_iso: run_ts_iso, parent_failed: true
        )
        err_msg_count += eb_evs.length
        msg_events.concat(eb_evs)
        tc_codes.concat(eb_codes)
        tc_matched_rules.concat(eb_rules)
      end

      tc_codes.uniq!
      suite_codes.concat(tc_codes)

      # Deduplicate by winning primary fault per message/step event so one UI_TIMEOUT
      # matching both ERR_UI_TIMEOUT and ERR_UI_TIMEOUT_TEXT across <step> and <errors>
      # counts as 1 unique fault, while matched_rule_ids keeps all diagnostic rule hits.
      unique_rules = tc_matched_rules.uniq(&:id)
      primary_fault_keys = []
      (raw_steps.each_with_index.map { |_, i| step_events[-raw_steps.length + i]&.get("error_mapping") } +
        tc_m_evs.map { |ev| ev.get("error_mapping") } +
        msg_events.last(err_msg_count).map { |ev| ev.get("error_mapping") }).compact.each do |em|
        next unless em.is_a?(Hash)
        primary_fault_keys << (em["rule_id"] || "UNCLASSIFIED::#{em['category']}")
      end
      unique_faults = primary_fault_keys.uniq

      if tc_failed || !unique_rules.empty?
        tc_error_mapping = ErrorMapping::Classifier.aggregate_rules(@mapping_config, unique_rules)
        err_cat = tc_error_mapping["category"]
        analysis_cls = tc_error_mapping["disposition"]
        fault_count = unique_faults.empty? ? (tc_failed ? 1 : 0) : unique_faults.length
      else
        tc_error_mapping = nil
        err_cat = "NONE"
        analysis_cls = "NONE"
        fault_count = 0
      end

      tc_payload = {
        "@timestamp" => run_ts_iso,
        "doc_type" => "test_case",
        "synthetic" => synthetic,
        "campaign" => { "id" => campaign_id },
        "run" => { "id" => run_id, "normalized_result" => run_norm_result },
        "test_bench" => { "id" => bench_id },
        "project" => project,
        "suite" => suite_ctx,
        "phase" => phase,
        "test_case" => tc_ctx.merge(
          "sequence" => ptc[:seq],
          "has_stable_id" => ptc[:has_stable_id],
          "is_first_attempt" => ptc[:attempt] == 1,
          "is_final_attempt" => ptc[:attempt] == max_attempt_by_tc[ptc[:tc_id]],
          "is_retry" => ptc[:attempt] > 1
        ),
        "normalized_result" => tc_norm_res,
        "error_category" => err_cat,
        "analysis_classification" => analysis_cls,
        "fault_count" => fault_count,
        "step_count" => raw_steps.length,
        "failed_step_count" => failed_steps,
        "msg_count" => tc_m_evs.length + err_msg_count,
        "error_msg_count" => err_msg_count,
        "comparability_limited" => !ptc[:has_stable_id],
        "source_file" => source_file,
        "file_sha256" => file_sha256,
        "ingested_at" => ingested_at
      }
      tc_payload["error_mapping"] = tc_error_mapping unless tc_error_mapping.nil?
      tc_payload["execution_slot_id"] = slot_id unless slot_id.nil?
      tc_payload["software"] = { "version" => software_version } unless software_version.nil?
      tc_payload["source_result"] = tc_src_res unless tc_src_res.nil?
      tc_payload["duration_ms"] = tc_dur_ms unless tc_dur_ms.nil?
      tc_payload["extracted_error_codes"] = tc_codes unless tc_codes.empty?
      tc_payload["artifact_paths"] = tc_artifacts.uniq unless tc_artifacts.empty?
      tc_payload["data_quality_issues"] = tc_dq unless tc_dq.empty?

      tc_ev = LogStash::Event.new(tc_payload)
      tc_ev.set("[@metadata][target_index]", "xml-insight-testcases-v1")
      tc_ev.set("[@metadata][doc_id]", "#{run_id}::#{phase}::#{suite_seq}::#{ptc[:exec_id]}::#{ptc[:attempt]}")
      tc_events << tc_ev

      if is_deinit_phase
        deinit_counts["total"] += 1
        deinit_counts[tc_norm_res] = (deinit_counts[tc_norm_res] || 0) + 1
      else
        s_counts[tc_norm_res] += 1
        reg_counts[tc_norm_res] += 1
      end
    end

    next if is_deinit_phase

    suite_src_res = clean_string(g["result"])
    suite_norm_res = if suite_src_res
                       normalize_result(suite_src_res)
                     elsif s_counts["ERROR"].positive?
                       "ERROR"
                     elsif s_counts["FAILED"].positive?
                       "FAILED"
                     elsif s_counts["PASSED"] == parsed_tcs.length
                       "PASSED"
                     else
                       "UNKNOWN"
                     end
    suite_dur_ms, = parse_duration_seconds_to_ms(g["duration"])

    s_payload = {
      "@timestamp" => run_ts_iso,
      "doc_type" => "suite",
      "synthetic" => synthetic,
      "campaign" => { "id" => campaign_id },
      "run" => { "id" => run_id, "normalized_result" => run_norm_result },
      "test_bench" => { "id" => bench_id },
      "project" => project,
      "suite" => suite_ctx.merge("sequence" => suite_seq, "has_stable_id" => !clean_string(g["id"]).nil?),
      "normalized_result" => suite_norm_res,
      "tc_total" => parsed_tcs.length,
      "tc_passed" => s_counts["PASSED"],
      "tc_failed" => s_counts["FAILED"],
      "tc_error" => s_counts["ERROR"],
      "tc_skipped" => s_counts["SKIPPED"],
      "tc_unknown" => s_counts["UNKNOWN"],
      "comparability_limited" => clean_string(g["id"]).nil?,
      "source_file" => source_file,
      "file_sha256" => file_sha256,
      "ingested_at" => ingested_at
    }
    s_payload["execution_slot_id"] = slot_id unless slot_id.nil?
    s_payload["software"] = { "version" => software_version } unless software_version.nil?
    s_payload["source_result"] = suite_src_res unless suite_src_res.nil?
    s_payload["duration_ms"] = suite_dur_ms unless suite_dur_ms.nil?
    s_payload["extracted_error_codes"] = suite_codes.uniq unless suite_codes.empty?

    s_ev = LogStash::Event.new(s_payload)
    s_ev.set("[@metadata][target_index]", "xml-insight-suites-v1")
    s_ev.set("[@metadata][doc_id]", "#{run_id}::suite::#{suite_seq}::#{suite_id}")
    suite_events << s_ev
  end

  run_payload = {
    "@timestamp" => run_ts_iso,
    "doc_type" => "run",
    "schema_version" => schema_version,
    "synthetic" => synthetic,
    "campaign" => { "id" => campaign_id },
    "run" => { "id" => run_id, "has_stable_id" => has_stable_run_id },
    "test_bench" => { "id" => bench_id },
    "project" => project,
    "source_start_time" => raw_start,
    "source_end_time" => raw_end,
    "started_at" => started_t.iso8601(3),
    "ended_at" => ended_t.iso8601(3),
    "duration_ms" => run_duration_ms,
    "timezone_assumed" => tz_assumed,
    "timezone_status" => tz_status_start,
    "normalized_result" => run_norm_result,
    "init_normalized_result" => init_norm_result,
    "deinit_normalized_result" => deinit_norm_result,
    "suite_count" => suite_events.length,
    "suite_names" => suite_names,
    "regular_tc_total" => reg_counts.values.sum,
    "regular_tc_passed" => reg_counts["PASSED"],
    "regular_tc_failed" => reg_counts["FAILED"],
    "regular_tc_error" => reg_counts["ERROR"],
    "regular_tc_skipped" => reg_counts["SKIPPED"],
    "regular_tc_unknown" => reg_counts["UNKNOWN"],
    "deinit_tc_total" => deinit_counts["total"],
    "deinit_tc_passed" => deinit_counts["PASSED"],
    "deinit_tc_failed" => deinit_counts["FAILED"],
    "comparability_limited" => !has_stable_run_id,
    "source_file" => source_file,
    "file_sha256" => file_sha256,
    "ingested_at" => ingested_at
  }
  run_payload["execution_slot_id"] = slot_id unless slot_id.nil?
  run_payload["software"] = { "version" => software_version } unless software_version.nil?
  run_payload["source_result"] = run_source_result unless run_source_result.nil?
  run_payload["init_source_result"] = init_source_result unless init_source_result.nil?
  run_payload["deinit_source_result"] = deinit_source_result unless deinit_source_result.nil?
  run_payload["init_params"] = init_params unless init_params.empty?
  run_payload["extra_group_names"] = extra_group_names unless extra_group_names.empty?
  run_payload["data_quality_issues"] = run_dq_issues unless run_dq_issues.empty?

  run_ev = LogStash::Event.new(run_payload)
  run_ev.set("[@metadata][target_index]", "xml-insight-runs-v1")
  run_ev.set("[@metadata][doc_id]", run_id)

  [run_ev] + suite_events + tc_events + step_events + msg_events
end
