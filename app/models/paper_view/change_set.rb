module PaperView
  class ChangeSet
    include Enumerable

    def self.for(version)
      changes = version.changeset
      new(changes || {}, unreadable: changes.blank? && payload?(version))
    rescue
      new({}, unreadable: true)
    end

    def self.payload?(version)
      version.respond_to?(:object_changes) && version.object_changes.present?
    end

    attr_reader :entries

    def initialize(raw_changes, unreadable: false)
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

    def to_filtered_hash
      PaperView.parameter_filter.filter(entries.to_h { |entry| [entry.name, [entry.old_value, entry.new_value]] })
    end
  end
end
