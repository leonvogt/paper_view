module PaperView
  class VersionsTable
    DiskSize = Struct.new(:table, :indexes)

    def item_types
      return distinct_scan unless postgresql? && item_type_indexed?

      connection.select_values(skip_scan_sql)
    end

    def item_type_indexed?
      return @item_type_indexed if defined?(@item_type_indexed)

      @item_type_indexed = connection.indexes(version_class.table_name).any? { |index| Array(index.columns).first == "item_type" }
    end

    def disk_size
      return @disk_size if defined?(@disk_size)

      sql = disk_size_sql
      row = sql && connection.select_rows(sql).first
      @disk_size = row && DiskSize.new(*row.map(&:to_i))
    rescue ActiveRecord::StatementInvalid
      @disk_size = nil
    end

    def heap_pages
      connection.select_value(<<~SQL).to_i
        #{partition_tree_cte}
        SELECT COALESCE(SUM(pg_relation_size(oid)), 0) / current_setting('block_size')::bigint FROM pv_tree
      SQL
    end

    def postgresql?
      connection.adapter_name.match?(/postgres/i)
    end

    def mysql?
      connection.adapter_name.match?(/mysql|trilogy|maria/i)
    end

    def sqlite?
      connection.adapter_name.match?(/sqlite/i)
    end

    private

    def version_class
      PaperView.version_class
    end

    def connection
      version_class.connection
    end

    def distinct_scan
      version_class.distinct.order(:item_type).pluck(:item_type)
    end

    def disk_size_sql
      if postgresql?
        <<~SQL
          #{partition_tree_cte}
          SELECT COALESCE(SUM(pg_table_size(oid)), 0), COALESCE(SUM(pg_indexes_size(oid)), 0) FROM pv_tree
        SQL
      elsif mysql?
        <<~SQL
          SELECT data_length, index_length
          FROM information_schema.tables
          WHERE table_schema = DATABASE() AND table_name = #{connection.quote(version_class.table_name)}
        SQL
      end
    end

    # A partitioned table keeps no rows of its own, so every size it reports is zero
    # until the partitions underneath it are counted too.
    def partition_tree_cte
      relation = "#{connection.quote(version_class.quoted_table_name)}::regclass"

      <<~SQL
        WITH RECURSIVE pv_tree AS (
          SELECT #{relation} AS oid
          UNION ALL
          SELECT partition.inhrelid FROM pg_inherits partition JOIN pv_tree ON partition.inhparent = pv_tree.oid
        )
      SQL
    end

    # A plain DISTINCT reads every row. This walks the item_type index
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
