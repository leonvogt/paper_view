module PaperView
  # Estimates how many bytes of payload each item type keeps in the versions table.
  #
  # Both paths read a bounded slice instead of the whole table: PostgreSQL samples pages
  # from across the table, every other adapter reads the newest rows.
  class PayloadSizes
    COLUMNS = %w[object object_changes].freeze
    SAMPLE_PAGES = 4_000
    SAMPLE_ROWS = 5_000
    # Fixed so that the same pages come back every time: an estimate that changes
    # on every refresh reads like a bug, and a new sample is no more true than the last.
    SAMPLE_SEED = 1

    def initialize(versions_table)
      @versions_table = versions_table
    end

    def measurable?
      average_bytes.any?
    end

    def average_bytes
      return @average_bytes if defined?(@average_bytes)
      return @average_bytes = {} if columns.empty?

      @average_bytes = averages(versions_table.postgresql? ? page_sample : head_sample)
    rescue ActiveRecord::StatementInvalid
      @average_bytes = {}
    end

    private

    attr_reader :versions_table

    def columns
      @columns ||= COLUMNS & version_class.column_names
    end

    # Item types too rare to land in the sample fall back to the overall average, so that
    # their bytes still count towards the total instead of quietly going missing.
    def averages(sample)
      rows = sample.sum { |_, count, _| count }
      return {} if rows.zero?

      overall = sample.sum { |_, _, bytes| bytes } / rows
      sample.each_with_object(Hash.new(overall)) { |(item_type, count, bytes), averages| averages[item_type] = bytes / count }
    end

    def page_sample
      select_sample(<<~SQL)
        SELECT #{item_type_column}, COUNT(*), COALESCE(SUM(#{payload_size}), 0)
        FROM #{version_class.quoted_table_name} TABLESAMPLE SYSTEM (#{sample_percent}) REPEATABLE (#{SAMPLE_SEED})
        GROUP BY #{item_type_column}
      SQL
    end

    # Payloads grow as models gain columns, so the newest rows are the ones that
    # say what the table weighs now.
    def head_sample
      newest = version_class.select(item_type_column, Arel.sql("#{payload_size} AS pv_bytes")).limit(SAMPLE_ROWS)
      newest = newest.order(version_class.primary_key => :desc) if version_class.primary_key

      select_sample(<<~SQL)
        SELECT #{item_type_column}, COUNT(*), COALESCE(SUM(pv_bytes), 0)
        FROM (#{newest.to_sql}) pv_sample
        GROUP BY #{item_type_column}
      SQL
    end

    def select_sample(sql)
      connection.select_rows(sql, "PaperView Payload Sample").map { |item_type, count, bytes| [item_type, count.to_i, bytes.to_f] }
    end

    # A fixed percentage reads more the bigger the table gets, which is backwards for a
    # page nobody wants to wait on. Aim at a page count and let the percentage follow.
    def sample_percent
      pages = versions_table.heap_pages
      return 100 if pages <= SAMPLE_PAGES

      (SAMPLE_PAGES * 100.0 / pages).ceil(4)
    end

    def payload_size
      @payload_size ||= columns.map { |column| "COALESCE(#{byte_length(connection.quote_column_name(column))}, 0)" }.join(" + ")
    end

    # Reports the stored size, so a compressed or out-of-line payload is counted as it sits on disk.
    def byte_length(column)
      return "pg_column_size(#{column})" if versions_table.postgresql?
      return "LENGTH(CAST(#{column} AS BLOB))" if versions_table.sqlite?

      "LENGTH(#{column})"
    end

    def item_type_column
      connection.quote_column_name("item_type")
    end

    def version_class
      PaperView.version_class
    end

    def connection
      version_class.connection
    end
  end
end
