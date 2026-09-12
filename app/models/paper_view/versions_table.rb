module PaperView
  class VersionsTable
    RECENT_LIMIT = 5_000

    def item_types
      distinct_values("item_type")
    end

    def whodunnits
      return recent_whodunnits unless skip_scannable?("whodunnit")

      connection.select_values(skip_scan_sql("whodunnit"))
    end

    def item_type_indexed?
      indexed?("item_type")
    end

    private

    def version_class
      PaperView.version_class
    end

    def connection
      version_class.connection
    end

    def postgresql?
      connection.adapter_name.match?(/postgres/i)
    end

    def skip_scannable?(column)
      postgresql? && indexed?(column)
    end

    def indexed?(column)
      leading_index_columns.include?(column)
    end

    def leading_index_columns
      @leading_index_columns ||= connection.indexes(version_class.table_name).map { |index| Array(index.columns).first }
    end

    def distinct_values(column)
      return version_class.distinct.order(column).pluck(column) unless skip_scannable?(column)

      connection.select_values(skip_scan_sql(column))
    end

    # PaperTrail leaves `whodunnit` unindexed, so a plain DISTINCT reads every
    # row. The actors of the latest versions are suggestion enough.
    def recent_whodunnits
      column = connection.quote_column_name("whodunnit")

      connection.select_values(<<~SQL)
        SELECT DISTINCT #{column} FROM (
          SELECT #{column}
          FROM #{version_class.quoted_table_name}
          ORDER BY #{connection.quote_column_name(version_class.primary_key)} DESC
          LIMIT #{RECENT_LIMIT}
        ) paper_view_recent
        WHERE #{column} IS NOT NULL
        ORDER BY #{column}
      SQL
    end

    # A plain DISTINCT reads every row. This walks the column's index
    # and jumps straight from one value to the next one.
    def skip_scan_sql(column)
      table = version_class.quoted_table_name
      quoted = connection.quote_column_name(column)

      <<~SQL
        WITH RECURSIVE paper_view_values AS (
          (SELECT #{quoted} FROM #{table} ORDER BY #{quoted} LIMIT 1)
          UNION ALL
          SELECT (
            SELECT successor.#{quoted}
            FROM #{table} successor
            WHERE successor.#{quoted} > paper_view_values.#{quoted}
            ORDER BY successor.#{quoted}
            LIMIT 1
          )
          FROM paper_view_values
          WHERE paper_view_values.#{quoted} IS NOT NULL
        )
        SELECT #{quoted} FROM paper_view_values WHERE #{quoted} IS NOT NULL
      SQL
    end
  end
end
