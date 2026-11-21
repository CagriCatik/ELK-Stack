# frozen_string_literal: true

require "tempfile"
require_relative "error_mapping/config_loader"
require_relative "error_mapping/matcher"
require_relative "error_mapping/classifier"

def assert(cond, msg)
  raise "Assertion failed: #{msg}" unless cond
end

def assert_raises(exc_class, msg)
  yield
  raise "Expected #{exc_class} (#{msg}) but nothing was raised"
rescue exc_class
  true
end

# 1. Production config loads and validates cleanly
prod_path = ENV["ERROR_MAPPING_PATH"] || File.expand_path("../../config/error_mapping.yaml", __dir__)
prod_cfg = ErrorMapping::ConfigLoader.load_file(prod_path)
assert(prod_cfg.version == "1.0", "Expected version 1.0")
assert(prod_cfg.rules.length >= 10, "Expected >= 10 rules")

# 2. Exact, contains, regex, error_code, case-insensitive matching
c_exact = ErrorMapping::Classifier.classify(prod_cfg, { "message" => "interactionservice rejected synthetic profile.", "error_codes" => [] })
assert(c_exact["matched"] && c_exact["rule_id"] == "ERR_PROFILE_REJECTED", "Exact case-insensitive match failed")

c_contains = ErrorMapping::Classifier.classify(prod_cfg, { "message" => "Notice: Cache warm-up exceeded limit", "error_codes" => [] })
assert(c_contains["rule_id"] == "ERR_EXPECTED_WARNING" && c_contains["disposition"] == "IGNORED", "Contains IGNORED match failed")

c_regex = ErrorMapping::Classifier.classify(prod_cfg, { "message" => "InteractionService did not respond before deadline.", "error_codes" => [] })
assert(c_regex["rule_id"] == "ERR_UI_TIMEOUT_TEXT" && c_regex["category"] == "TIMEOUT", "Regex match without errorCode failed")

c_code = ErrorMapping::Classifier.classify(prod_cfg, { "message" => "Frame error", "error_codes" => ["IMG_CAPTURE_FAILED"] })
assert(c_code["rule_id"] == "ERR_CAPTURE_FAILURE" && c_code["category"] == "CAPTURE_ERROR", "Error code match failed")

# 3. Unknown fallback
c_unk = ErrorMapping::Classifier.classify(prod_cfg, { "message" => "Completely unknown glitch 999", "error_codes" => [] })
assert(!c_unk["matched"] && c_unk["rule_id"].nil? && c_unk["category"] == "UNKNOWN" && c_unk["disposition"] == "UNCLASSIFIED", "Unknown fallback failed")

# 4. Priority, tie-break, disabled rule, scope constraints, multiple matches
custom_cfg = ErrorMapping::ConfigLoader.parse(
  "version" => "2.0",
  "defaults" => { "category" => "UNKNOWN", "severity" => "MEDIUM", "disposition" => "UNCLASSIFIED" },
  "rules" => [
    {
      "id" => "RULE_DISABLED",
      "enabled" => false,
      "priority" => 999,
      "match" => { "type" => "contains", "field" => "message", "values" => ["boom"] },
      "classification" => { "category" => "DISABLED_CAT", "severity" => "CRITICAL", "disposition" => "RELEVANT" }
    },
    {
      "id" => "RULE_TIE_FIRST",
      "enabled" => true,
      "priority" => 50,
      "match" => { "type" => "contains", "field" => "message", "values" => ["boom"] },
      "classification" => { "category" => "FIRST_CAT", "severity" => "HIGH", "disposition" => "RELEVANT" }
    },
    {
      "id" => "RULE_TIE_SECOND",
      "enabled" => true,
      "priority" => 50,
      "match" => { "type" => "contains", "field" => "message", "values" => ["boom"] },
      "classification" => { "category" => "SECOND_CAT", "severity" => "LOW", "disposition" => "IGNORED" }
    },
    {
      "id" => "RULE_SCOPED",
      "enabled" => true,
      "priority" => 80,
      "scope" => { "suites" => ["Content"] },
      "match" => { "type" => "contains", "field" => "message", "values" => ["boom"] },
      "classification" => { "category" => "SCOPED_CAT", "severity" => "HIGH", "disposition" => "KNOWN_ISSUE" }
    }
  ]
)

res_ws = ErrorMapping::Classifier.classify(custom_cfg, { "message" => "boom", "suite" => "Workspace" })
assert(res_ws["rule_id"] == "RULE_TIE_FIRST", "Expected tie-break to pick RULE_TIE_FIRST, got #{res_ws['rule_id']}")
assert(res_ws["matched_rule_ids"] == %w[RULE_TIE_FIRST RULE_TIE_SECOND], "Expected both matched rules in diagnostics")

res_ct = ErrorMapping::Classifier.classify(custom_cfg, { "message" => "boom", "suite" => "Content" })
assert(res_ct["rule_id"] == "RULE_SCOPED", "Expected scoped higher-priority rule to win for Content")

# 5. Invalid configurations must raise ConfigurationError (never fall back silently)
assert_raises(ErrorMapping::ConfigurationError, "missing file") do
  ErrorMapping::ConfigLoader.load_file("/nonexistent/error_mapping.yaml")
end

assert_raises(ErrorMapping::ConfigurationError, "duplicate rule id") do
  ErrorMapping::ConfigLoader.parse(
    "version" => "1.0",
    "defaults" => { "category" => "UNKNOWN", "severity" => "MEDIUM", "disposition" => "UNCLASSIFIED" },
    "rules" => [
      { "id" => "DUP", "priority" => 10, "match" => { "type" => "exact", "values" => ["a"] }, "classification" => { "category" => "X", "severity" => "LOW", "disposition" => "IGNORED" } },
      { "id" => "DUP", "priority" => 20, "match" => { "type" => "exact", "values" => ["b"] }, "classification" => { "category" => "Y", "severity" => "LOW", "disposition" => "IGNORED" } }
    ]
  )
end

assert_raises(ErrorMapping::ConfigurationError, "invalid regex") do
  ErrorMapping::ConfigLoader.parse(
    "version" => "1.0",
    "defaults" => { "category" => "UNKNOWN", "severity" => "MEDIUM", "disposition" => "UNCLASSIFIED" },
    "rules" => [
      { "id" => "BAD_RE", "priority" => 10, "match" => { "type" => "regex", "patterns" => ["[unclosed"] }, "classification" => { "category" => "X", "severity" => "LOW", "disposition" => "IGNORED" } }
    ]
  )
end

assert_raises(ErrorMapping::ConfigurationError, "unsupported match type") do
  ErrorMapping::ConfigLoader.parse(
    "version" => "1.0",
    "defaults" => { "category" => "UNKNOWN", "severity" => "MEDIUM", "disposition" => "UNCLASSIFIED" },
    "rules" => [
      { "id" => "BAD_TYPE", "priority" => 10, "match" => { "type" => "fuzzy", "values" => ["a"] }, "classification" => { "category" => "X", "severity" => "LOW", "disposition" => "IGNORED" } }
    ]
  )
end

puts "All Ruby ErrorMapping unit tests passed!"
