module PaperView
  class TableStats
    Row = Struct.new(:item_type, :count, :average_bytes) do
      def estimated_bytes
        return nil if average_bytes.nil?

        (average_bytes * count).round
      end

      def share(total)
        return 0.0 if total.nil? || total.zero?

        estimated_bytes.to_i / total.to_f
      end
    end

    def rows
      @rows ||= counts.map { |item_type, count| Row.new(item_type, count, payload_sizes.average_bytes[item_type]) }
        .sort_by { |row| [-row.estimated_bytes.to_i, -row.count] }
    end

    def empty?
      rows.empty?
    end

    def total_count
      @total_count ||= rows.sum(&:count)
    end

    def estimated_total_bytes
      return nil unless measurable?

      @estimated_total_bytes ||= rows.sum { |row| row.estimated_bytes.to_i }
    end

    def disk_size
      versions_table.disk_size
    end

    private

    def measurable?
      payload_sizes.measurable?
    end

    def counts
      @counts ||= version_class.group(:item_type).count
    end

    def payload_sizes
      @payload_sizes ||= PayloadSizes.new(versions_table)
    end

    def versions_table
      @versions_table ||= VersionsTable.new
    end

    def version_class
      PaperView.version_class
    end
  end
end
