module PaperView
  class ChangeSet
    include Enumerable

    def self.for(version)
      payload = raw_payload(version)
      changes = Payload.parse(payload)
      new(changes || {}, raw: payload, unreadable: changes.nil? && payload.present?)
    end

    def self.raw_payload(version)
      version.object_changes if version.respond_to?(:object_changes)
    rescue
      nil
    end

    attr_reader :entries, :raw

    def initialize(raw_changes, raw: nil, unreadable: false)
      @raw = raw
      @unreadable = unreadable
      @entries = raw_changes.filter_map do |name, pair|
        next unless pair.is_a?(Array) && pair.size == 2
        AttributeChange.new(name, pair.first, pair.last)
      end
    end

    def unreadable?
      @unreadable
    end

    def each(&block)
      entries.each(&block)
    end

    def empty?
      entries.empty?
    end

    def size
      entries.size
    end

    def raw_text
      @raw_text ||= raw.is_a?(Hash) ? AttributeChange.json(raw, pretty: true) : raw.to_s
    end
  end
end
