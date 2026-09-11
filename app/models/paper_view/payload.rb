require "json"
require "psych"

module PaperView
  class Payload
    SYMBOL_TAGS = ["!ruby/symbol", "!ruby/sym", "tag:yaml.org,2002:symbol"].freeze
    BIG_DECIMAL_TAG = "!ruby/object:BigDecimal".freeze
    TIME_WITH_ZONE_TAG = "!ruby/object:ActiveSupport::TimeWithZone".freeze

    def self.parse(raw)
      return raw if raw.is_a?(Hash)
      return nil if raw.blank?

      text = raw.to_s
      json(text) || new(text).to_h
    end

    def self.json(text)
      parsed = JSON.parse(text)
      parsed if parsed.is_a?(Hash)
    rescue JSON::ParserError, TypeError
      nil
    end

    def initialize(text)
      @text = text
      @anchors = {}
      @scanner = Psych::ScalarScanner.new(Psych::ClassLoader.new)
    end

    def to_h
      document = Psych.parse(@text)
      value = document && visit(document.root)
      value if value.is_a?(Hash)
    rescue Psych::Exception
      nil
    end

    private

    def visit(node)
      case node
      when Psych::Nodes::Mapping then mapping(node)
      when Psych::Nodes::Sequence then sequence(node)
      when Psych::Nodes::Scalar then register(node, scalar(node))
      when Psych::Nodes::Alias then @anchors[node.anchor]
      end
    end

    def mapping(node)
      pairs = {}
      register(node, pairs)
      node.children.each_slice(2) { |key, value| pairs[visit(key).to_s] = visit(value) }
      (node.tag == TIME_WITH_ZONE_TAG) ? time_with_zone(pairs) : pairs
    end

    def time_with_zone(pairs)
      utc = pairs["utc"]
      return pairs unless utc.is_a?(Time)

      zone = pairs.dig("zone", "name")
      (zone && Time.find_zone(zone)&.at(utc)) || utc
    end

    def sequence(node)
      items = []
      register(node, items)
      node.children.each { |child| items << visit(child) }
      items
    end

    def scalar(node)
      return node.value if node.quoted
      return @scanner.tokenize(node.value) if node.tag.nil?

      case node.tag
      when *SYMBOL_TAGS then node.value.to_sym
      when BIG_DECIMAL_TAG then big_decimal(node.value)
      else node.value
      end
    end

    def big_decimal(value)
      number = value.split(":", 2).last
      defined?(BigDecimal) ? BigDecimal(number) : number
    rescue ArgumentError, TypeError
      number
    end

    def register(node, value)
      @anchors[node.anchor] = value if node.anchor
      value
    end
  end
end
