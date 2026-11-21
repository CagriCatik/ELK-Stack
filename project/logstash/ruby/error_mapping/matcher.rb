# frozen_string_literal: true

module ErrorMapping
  # Pure rule-matching engine with zero Logstash or Elasticsearch dependencies.
  module Matcher
    module_function

    # Evaluates all enabled rules against an error context hash:
    #   { "message" => String, "error_codes" => Array<String>, "phase" => String,
    #     "suite" => String, "test_case" => String, "component" => String }
    # Returns matching Rule objects ordered by highest priority first.
    def match_all(config, context)
      return [] unless config && config.rules

      config.rules.select do |rule|
        rule.enabled && scope_matches?(rule.scope, context) && condition_matches?(rule, context)
      end
    end

    def scope_matches?(scope, context)
      return true if scope.nil? || scope.empty?

      check_scope_key(scope["phases"], context["phase"]) &&
        check_scope_key(scope["suites"], context["suite"]) &&
        check_scope_key(scope["test_cases"], context["test_case"]) &&
        check_scope_key(scope["components"], context["component"])
    end

    def check_scope_key(allowed, actual)
      return true if allowed.nil? || allowed.empty?
      return false if actual.nil?

      allowed.include?(actual.to_s)
    end

    def condition_matches?(rule, context)
      case rule.match_type
      when "error_code"
        codes = Array(context["error_codes"]).map(&:to_s)
        return false if codes.empty?

        if rule.case_sensitive
          rule.values.any? { |v| codes.include?(v) }
        else
          down_codes = codes.map(&:downcase)
          rule.values.any? { |v| down_codes.include?(v.downcase) }
        end
      when "exact"
        text = context[rule.match_field].to_s
        return false if text.empty?

        if rule.case_sensitive
          rule.values.any? { |v| text == v }
        else
          down = text.downcase
          rule.values.any? { |v| down == v.downcase }
        end
      when "contains"
        text = context[rule.match_field].to_s
        return false if text.empty?

        if rule.case_sensitive
          rule.values.any? { |v| text.include?(v) }
        else
          down = text.downcase
          rule.values.any? { |v| down.include?(v.downcase) }
        end
      when "regex"
        text = context[rule.match_field].to_s
        return false if text.empty?

        rule.compiled_regexes.any? { |re| re.match?(text) }
      else
        false
      end
    end
  end
end
