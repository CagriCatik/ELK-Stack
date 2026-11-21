# frozen_string_literal: true

require_relative "matcher"

module ErrorMapping
  # Pure domain classifier that builds the Elasticsearch error_mapping payload
  # without touching XML parsing or altering original test results.
  module Classifier
    module_function

    def classify(config, context)
      matched_rules = Matcher.match_all(config, context)
      build_result(config, matched_rules)
    end

    # Combines multiple pre-matched rules (e.g., across steps and <errors> within a TestCase)
    # deterministically by [-priority, index, id] without duplicate rule IDs.
    def aggregate_rules(config, rules)
      unique = rules.uniq(&:id).sort_by { |r| [-r.priority, r.index, r.id] }
      build_result(config, unique)
    end

    def build_result(config, matched_rules)
      if matched_rules.empty?
        d = config.defaults
        return {
          "matched" => false,
          "rule_id" => nil,
          "matched_rule_ids" => [],
          "category" => d["category"],
          "severity" => d["severity"],
          "disposition" => d["disposition"],
          "root_cause" => d["root_cause"],
          "owner" => d["owner"],
          "mapping_version" => config.version
        }
      end

      primary = matched_rules.first
      cls = primary.classification
      {
        "matched" => true,
        "rule_id" => primary.id,
        "matched_rule_ids" => matched_rules.map(&:id),
        "category" => cls["category"],
        "severity" => cls["severity"],
        "disposition" => cls["disposition"],
        "root_cause" => cls["root_cause"],
        "owner" => cls["owner"],
        "mapping_version" => config.version
      }
    end
  end
end
