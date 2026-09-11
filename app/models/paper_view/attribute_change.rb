require "json"

module PaperView
  class AttributeChange
    attr_reader :name, :old_value, :new_value

    def self.display(value, pretty: false)
      case value
      when nil then EMPTY
      when String then value.empty? ? '""' : value
      when Hash, Array then json(value, pretty: pretty)
      when Time then value.in_time_zone.strftime(PaperView.config.time_format)
      else value.to_s
      end
    end

    def self.json(value, pretty: false)
      pretty ? JSON.pretty_generate(value) : JSON.generate(value)
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

    def nested?
      old_value.is_a?(Hash) || new_value.is_a?(Hash)
    end

    def old_text
      @old_text ||= self.class.display(old_value, pretty: true)
    end

    def new_text
      @new_text ||= self.class.display(new_value, pretty: true)
    end

    def key_changes
      changed_keys.map { |key| LeafChange.new(key, old_keys[key], new_keys[key]) }
    end

    def unchanged_key_count
      all_keys.size - changed_keys.size
    end

    def leaves
      return [LeafChange.new(name, old_value, new_value)] unless nested?

      key_changes.map { |change| LeafChange.new("#{name}.#{change.path}", change.old_value, change.new_value) }
    end

    private

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
