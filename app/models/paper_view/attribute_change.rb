require "json"

module PaperView
  class AttributeChange
    EMPTY = "—".freeze
    FILTERED = "[FILTERED]".freeze
    NESTING_SUFFIX = /_settings\z/

    attr_reader :name, :old_value, :new_value

    def self.format(value)
      case value
      when nil then ""
      when String then value
      when Hash, Array then pretty_json(value)
      when Time then value.strftime("%Y-%m-%d %H:%M:%S.%6N %Z")
      else value.to_s
      end
    end

    def self.inline(value)
      case value
      when nil then EMPTY
      when String then value.empty? ? '""' : value
      when Hash, Array then compact_json(value)
      when Time then value.strftime(PaperView.config.time_format)
      else value.to_s
      end
    end

    def self.pretty_json(value)
      JSON.pretty_generate(value)
    rescue
      value.inspect
    end

    def self.compact_json(value)
      JSON.generate(value)
    rescue
      value.inspect
    end

    def self.flatten(value, prefix = nil, target = {})
      if value.is_a?(Hash) && value.any?
        value.each { |key, nested| flatten(nested, [prefix, key].compact.join("."), target) }
      elsif prefix
        target[prefix] = value
      end
      target
    end

    def initialize(name, old_value, new_value)
      @name = name.to_s
      @old_value = old_value
      @new_value = new_value
    end

    def status
      if old_value.nil? && !new_value.nil?
        :added
      elsif !old_value.nil? && new_value.nil?
        :removed
      else
        :changed
      end
    end

    def filtered?
      PaperView.filtered_attribute?(name)
    end

    def nested?
      old_value.is_a?(Hash) || new_value.is_a?(Hash)
    end

    def old_text
      @old_text ||= self.class.format(old_value)
    end

    def new_text
      @new_text ||= self.class.format(new_value)
    end

    def key_changes
      changed_keys.map { |key| LeafChange.new(key, old_keys[key], new_keys[key]) }
    end

    def unchanged_key_count
      all_keys.size - changed_keys.size
    end

    def leaves
      return [LeafChange.new(name, FILTERED, FILTERED)] if filtered?
      return [LeafChange.new(name, old_value, new_value)] unless nested?

      key_changes.map { |change| LeafChange.new("#{base_path}.#{change.path}", change.old_value, change.new_value, nested: true) }
    end

    private

    def base_path
      name.sub(NESTING_SUFFIX, "")
    end

    def old_keys
      @old_keys ||= self.class.flatten(old_value)
    end

    def new_keys
      @new_keys ||= self.class.flatten(new_value)
    end

    def all_keys
      @all_keys ||= old_keys.keys | new_keys.keys
    end

    def changed_keys
      @changed_keys ||= all_keys.reject { |key| old_keys.key?(key) && new_keys.key?(key) && old_keys[key] == new_keys[key] }
    end
  end
end
