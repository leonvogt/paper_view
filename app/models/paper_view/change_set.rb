module PaperView
  class ChangeSet
    include Enumerable

    def self.for(version)
      new(changes_for(version), payload?(version))
    end

    def self.payload?(version)
      %i[object_changes object].any? { |column| version.respond_to?(column) && version.public_send(column).present? }
    end

    def self.changes_for(version)
      changeset = safe_changeset(version)
      return changeset if changeset.present?
      return destroyed_attributes(version) if version.event == "destroy"
      {}
    end

    def self.safe_changeset(version)
      version.changeset
    rescue
      {}
    end

    def self.destroyed_attributes(version)
      attributes = version.reify&.attributes
      return {} if attributes.blank?
      attributes.compact.transform_values { |value| [value, nil] }
    rescue
      {}
    end

    attr_reader :entries

    def initialize(raw_changes, payload = false)
      @payload = payload
      @entries = raw_changes.filter_map do |name, pair|
        next unless pair.is_a?(Array) && pair.size == 2
        AttributeChange.new(name, pair.first, pair.last)
      end
    end

    def unreadable?
      empty? && @payload
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

    def names
      entries.map(&:name)
    end

    def to_filtered_hash
      PaperView.parameter_filter.filter(entries.to_h { |entry| [entry.name, [entry.old_value, entry.new_value]] })
    end
  end
end
