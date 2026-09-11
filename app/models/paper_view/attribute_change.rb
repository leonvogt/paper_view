require "json"

module PaperView
  class AttributeChange
    JSON_START = /\A\s*[\[{]/

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

    def self.structure(value)
      case value
      when Hash, Array then value
      when String then parse(value)
      end
    end

    def self.parse(text)
      return unless text.match?(JSON_START)

      structure = JSON.parse(text)
      structure if structure.is_a?(Hash) || structure.is_a?(Array)
    rescue JSON::ParserError
      nil
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
      !hashes.nil?
    end

    def old_text
      @old_text ||= text(old_value)
    end

    def new_text
      @new_text ||= text(new_value)
    end

    def leaf_changes
      return [] unless nested?

      changed_keys.map { |key| LeafChange.new(key, old_keys[key], new_keys[key]) }
    end

    def unchanged_count
      nested? ? all_keys.size - changed_keys.size : 0
    end

    def leaves
      return [LeafChange.new(name, old_value, new_value)] unless nested?

      leaf_changes.map { |change| LeafChange.new("#{name}.#{change.path}", change.old_value, change.new_value) }
    end

    private

    def text(value)
      self.class.display(self.class.structure(value) || value, pretty: true)
    end

    def hashes
      return @hashes if defined?(@hashes)

      @hashes = hash_pair
    end

    def hash_pair
      pair = [old_value, new_value].map { |value| hash_for(value) }
      pair if pair.all? && pair.any?(&:any?)
    end

    # A blank side counts as an empty hash, so a structure that was just set still diffs.
    def hash_for(value)
      return {} if value.nil? || value == ""

      structure = self.class.structure(value)
      structure if structure.is_a?(Hash)
    end

    def old_keys
      @old_keys ||= self.class.flatten(hashes.first)
    end

    def new_keys
      @new_keys ||= self.class.flatten(hashes.last)
    end

    def all_keys
      @all_keys ||= old_keys.keys | new_keys.keys
    end

    def changed_keys
      @changed_keys ||= all_keys.reject { |key| old_keys.key?(key) && new_keys.key?(key) && old_keys[key] == new_keys[key] }
    end
  end
end
