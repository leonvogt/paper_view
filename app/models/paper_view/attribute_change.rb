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

    # Walks both sides at once, collecting every leaf as a [path, old, new] triple.
    # Arrays line up by index while their length holds. Once it changes they compare by
    # membership instead, each gone or gained element labelled with its own position.
    def self.flatten_pair(old_value, new_value, path = nil, target = [])
      if both(Hash, old_value, new_value)
        (old_value.keys | new_value.keys).each do |key|
          flatten_pair(old_value[key], new_value[key], [path, key].compact.join("."), target)
        end
      elsif both(Array, old_value, new_value) && old_value.size == new_value.size
        old_value.each_index { |index| flatten_pair(old_value[index], new_value[index], "#{path}[#{index}]", target) }
      elsif both(Array, old_value, new_value)
        old_value.each_with_index { |item, index| target << ["#{path}[#{index}]", item, new_value.include?(item) ? item : nil] }
        new_value.each_with_index { |item, index| target << ["#{path}[#{index}]", nil, item] unless old_value.include?(item) }
      else
        target << [path, old_value, new_value]
      end
      target
    end

    def self.both(kind, old_value, new_value)
      old_value.is_a?(kind) && new_value.is_a?(kind) && (old_value.any? || new_value.any?)
    end

    def initialize(name, old_value, new_value)
      @name = name.to_s
      @old_value = old_value
      @new_value = new_value
    end

    def nested?
      !structures.nil?
    end

    def old_text
      @old_text ||= text(old_value)
    end

    def new_text
      @new_text ||= text(new_value)
    end

    def leaf_changes
      leaf_pairs.filter_map { |path, before, after| LeafChange.new(path, before, after) if before != after }
    end

    def unchanged_count
      leaf_pairs.count { |_, before, after| before == after }
    end

    def leaves
      return [LeafChange.new(name, old_value, new_value)] unless nested?

      leaf_changes.map { |change| change.under(name) }
    end

    private

    def text(value)
      self.class.display(self.class.structure(value) || value, pretty: true)
    end

    def structures
      return @structures if defined?(@structures)

      @structures = structure_pair
    end

    # Both sides have to be the same kind of structure. A blank side counts as an empty one,
    # so a structure that was just set or cleared still diffs.
    def structure_pair
      pair = [old_value, new_value].map { |value| self.class.structure(value) }
      kind = pair.compact.first&.class
      return unless kind && pair.any? { |structure| structure&.any? }

      pair = pair.zip([old_value, new_value]).map { |structure, value| structure || (kind.new if blank?(value)) }
      pair if pair.all? { |structure| structure.is_a?(kind) }
    end

    def blank?(value)
      value.nil? || value == ""
    end

    def leaf_pairs
      @leaf_pairs ||= nested? ? self.class.flatten_pair(*structures) : []
    end
  end
end
