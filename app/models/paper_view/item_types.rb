module PaperView
  class ItemTypes
    def self.all
      new.all
    end

    def all
      return distinct_scan unless postgresql?

      connection.select_values(skip_scan_sql)
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

    def distinct_scan
      version_class.distinct.order(:item_type).pluck(:item_type)
    end

    # A plain DISTINCT reads every row. This walks the (item_type, item_id) index
    # and jumps straight from one item_type to the next one.
    def skip_scan_sql
      table = version_class.quoted_table_name
      column = connection.quote_column_name("item_type")

      <<~SQL
        WITH RECURSIVE paper_view_item_types AS (
          (SELECT #{column} FROM #{table} ORDER BY #{column} LIMIT 1)
          UNION ALL
          SELECT (
            SELECT successor.#{column}
            FROM #{table} successor
            WHERE successor.#{column} > paper_view_item_types.#{column}
            ORDER BY successor.#{column}
            LIMIT 1
          )
          FROM paper_view_item_types
          WHERE paper_view_item_types.#{column} IS NOT NULL
        )
        SELECT #{column} FROM paper_view_item_types WHERE #{column} IS NOT NULL
      SQL
    end
  end
end
