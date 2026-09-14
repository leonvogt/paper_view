module PaperView
  class Metadata
    include Enumerable

    # Everything paper_trail itself writes. Whatever else the table carries was put
    # there by `has_paper_trail meta:` or `controller_info`, which is the metadata.
    PAPER_TRAIL_COLUMNS = %w[
      id item_type item_subtype item_id event whodunnit
      object object_changes created_at updated_at transaction_id
    ].freeze

    VISIBLE = 2

    Entry = Struct.new(:name, :value) do
      def text
        AttributeChange.display(value)
      end
    end

    def self.for(version)
      new(version, columns(version))
    end

    def self.columns(version)
      configured = PaperView.config.metadata_columns
      return Array(configured).map(&:to_s) if configured

      table_columns(version) - PAPER_TRAIL_COLUMNS
    end

    def self.table_columns(version)
      version.class.respond_to?(:column_names) ? version.class.column_names.map(&:to_s) : []
    end

    attr_reader :entries

    def initialize(version, columns)
      @entries = columns.filter_map do |name|
        value = read(version, name)
        Entry.new(name, value) unless blank?(value)
      end
    end

    def each(&block)
      entries.each(&block)
    end

    def empty?
      entries.empty?
    end

    def visible
      entries.first(VISIBLE)
    end

    def hidden
      entries.drop(VISIBLE)
    end

    private

    def read(version, name)
      version.public_send(name) if version.respond_to?(name)
    rescue
      nil
    end

    def blank?(value)
      return true if value.nil?
      value.respond_to?(:empty?) ? value.empty? : false
    end
  end
end
