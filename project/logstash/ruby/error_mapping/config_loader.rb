# frozen_string_literal: true

require "yaml"

module ErrorMapping
  class ConfigurationError < StandardError; end

  SUPPORTED_MATCH_TYPES = %w[exact contains regex error_code].freeze
  VALID_DISPOSITIONS = %w[RELEVANT KNOWN_ISSUE IGNORED UNCLASSIFIED].freeze
  VALID_SEVERITIES = %w[CRITICAL HIGH MEDIUM LOW INFO].freeze

  Config = Struct.new(:version, :defaults, :rules, keyword_init: true)
  Rule = Struct.new(
    :id,
    :index,
    :enabled,
    :priority,
    :description,
    :match_type,
    :match_field,
    :case_sensitive,
    :values,
    :compiled_regexes,
    :scope,
    :classification,
    keyword_init: true
  )

  module ConfigLoader
    module_function

    def load_file(path)
      raise ConfigurationError, "Error mapping file not found: #{path}" unless path && File.exist?(path)

      raw = YAML.safe_load(File.read(path, encoding: "utf-8"))
      raise ConfigurationError, "Error mapping YAML must be a mapping object" unless raw.is_a?(Hash)

      parse(raw)
    rescue Psych::SyntaxError => e
      raise ConfigurationError, "Invalid YAML in error mapping file '#{path}': #{e.message}"
    end

    def parse(raw)
      version = raw["version"]&.to_s&.strip
      raise ConfigurationError, "Error mapping requires non-empty 'version'" if version.nil? || version.empty?

      defaults = validate_classification(raw["defaults"], context: "defaults")
      raw_rules = raw["rules"]
      raise ConfigurationError, "Error mapping requires 'rules' array" unless raw_rules.is_a?(Array)

      seen_ids = {}
      rules = raw_rules.each_with_index.map do |r, idx|
        build_rule(r, idx, seen_ids)
      end

      # Deterministic priority order: higher priority wins; tie-breaker = config order, then lexical id
      sorted = rules.sort_by { |rule| [-rule.priority, rule.index, rule.id] }.freeze
      Config.new(version: version.freeze, defaults: defaults.freeze, rules: sorted).freeze
    end

    def build_rule(raw_rule, idx, seen_ids)
      raise ConfigurationError, "Rule at index #{idx} must be a mapping" unless raw_rule.is_a?(Hash)

      id = raw_rule["id"]&.to_s&.strip
      raise ConfigurationError, "Rule at index #{idx} is missing 'id'" if id.nil? || id.empty?
      raise ConfigurationError, "Duplicate rule id '#{id}'" if seen_ids.key?(id)

      seen_ids[id] = true

      enabled = raw_rule.key?("enabled") ? (raw_rule["enabled"] == true) : true
      priority = raw_rule["priority"]
      unless priority.is_a?(Integer)
        raise ConfigurationError, "Rule '#{id}' requires integer 'priority'"
      end

      match = raw_rule["match"]
      raise ConfigurationError, "Rule '#{id}' is missing 'match' section" unless match.is_a?(Hash)

      match_type = match["type"]&.to_s&.strip
      unless SUPPORTED_MATCH_TYPES.include?(match_type)
        raise ConfigurationError, "Rule '#{id}' has unsupported match.type '#{match_type}'. Allowed: #{SUPPORTED_MATCH_TYPES.join(', ')}"
      end

      match_field = (match["field"] || (match_type == "error_code" ? "error_codes" : "message")).to_s.strip
      case_sensitive = match["case_sensitive"] == true

      raw_items = match_type == "regex" ? match["patterns"] : (match["values"] || match["patterns"])
      unless raw_items.is_a?(Array) && !raw_items.empty?
        raise ConfigurationError, "Rule '#{id}' requires a non-empty list of patterns/values"
      end

      values = raw_items.map { |v| v.to_s }.freeze
      compiled_regexes = if match_type == "regex"
                           values.map do |pat|
                             begin
                               Regexp.new(pat, case_sensitive ? 0 : Regexp::IGNORECASE)
                             rescue RegexpError => e
                               raise ConfigurationError, "Rule '#{id}' has invalid regex '#{pat}': #{e.message}"
                             end
                           end.freeze
                         else
                           [].freeze
                         end

      scope = parse_scope(raw_rule["scope"], id)
      classification = validate_classification(raw_rule["classification"], context: "rule '#{id}'")

      Rule.new(
        id: id.freeze,
        index: idx,
        enabled: enabled,
        priority: priority,
        description: raw_rule["description"]&.to_s&.freeze,
        match_type: match_type.freeze,
        match_field: match_field.freeze,
        case_sensitive: case_sensitive,
        values: values,
        compiled_regexes: compiled_regexes,
        scope: scope,
        classification: classification
      ).freeze
    end

    def parse_scope(raw_scope, rule_id)
      return {}.freeze if raw_scope.nil?
      raise ConfigurationError, "Rule '#{rule_id}' scope must be a mapping" unless raw_scope.is_a?(Hash)

      parsed = {}
      %w[phases suites test_cases components].each do |key|
        next unless raw_scope.key?(key)

        arr = raw_scope[key]
        raise ConfigurationError, "Rule '#{rule_id}' scope.#{key} must be an array" unless arr.is_a?(Array)

        parsed[key] = arr.map { |v| v.to_s.strip }.reject(&:empty?).freeze
      end
      parsed.freeze
    end

    def validate_classification(raw_cls, context:)
      raise ConfigurationError, "Missing classification in #{context}" unless raw_cls.is_a?(Hash)

      category = raw_cls["category"]&.to_s&.strip
      severity = raw_cls["severity"]&.to_s&.strip&.upcase
      disposition = raw_cls["disposition"]&.to_s&.strip&.upcase
      root_cause = (raw_cls["root_cause"] || "UNCLASSIFIED").to_s.strip
      owner = (raw_cls["owner"] || "UNASSIGNED").to_s.strip

      raise ConfigurationError, "Missing 'category' in #{context}" if category.nil? || category.empty?
      unless VALID_SEVERITIES.include?(severity)
        raise ConfigurationError, "Invalid severity '#{severity}' in #{context}. Allowed: #{VALID_SEVERITIES.join(', ')}"
      end
      unless VALID_DISPOSITIONS.include?(disposition)
        raise ConfigurationError, "Invalid disposition '#{disposition}' in #{context}. Allowed: #{VALID_DISPOSITIONS.join(', ')}"
      end

      {
        "category" => category.freeze,
        "severity" => severity.freeze,
        "disposition" => disposition.freeze,
        "root_cause" => root_cause.freeze,
        "owner" => owner.freeze
      }.freeze
    end
  end
end
