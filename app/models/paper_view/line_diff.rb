module PaperView
  class LineDiff
    MAX_LINES = 400
    CONTEXT_LINES = 3

    Row = Struct.new(:type, :old_number, :new_number, :text) do
      def unchanged?
        type == :unchanged
      end

      def gap?
        type == :gap
      end
    end

    def self.pair(rows)
      pairs = []
      index = 0

      while index < rows.size
        row = rows[index]

        if row.unchanged? || row.gap?
          pairs << [row, row]
          index += 1
          next
        end

        removed = []
        added = []
        while rows[index]&.type == :removed
          removed << rows[index]
          index += 1
        end
        while rows[index]&.type == :added
          added << rows[index]
          index += 1
        end

        [removed.size, added.size].max.times { |offset| pairs << [removed[offset], added[offset]] }
      end

      pairs
    end

    def initialize(old_text, new_text)
      @old_lines = split(old_text)
      @new_lines = split(new_text)
    end

    def rows
      @rows ||= collapse(oversized? ? replaced_rows : aligned_rows)
    end

    private

    attr_reader :old_lines, :new_lines

    def split(text)
      return [] if text.nil? || text.empty?
      text.to_s.split("\n", -1)
    end

    def oversized?
      old_lines.size > MAX_LINES || new_lines.size > MAX_LINES
    end

    def replaced_rows
      old_lines.each_with_index.map { |line, index| Row.new(:removed, index + 1, nil, line) } +
        new_lines.each_with_index.map { |line, index| Row.new(:added, nil, index + 1, line) }
    end

    def aligned_rows
      table = lcs_table
      rows = []
      old_index = old_lines.size
      new_index = new_lines.size

      while old_index.positive? || new_index.positive?
        if old_index.positive? && new_index.positive? && old_lines[old_index - 1] == new_lines[new_index - 1]
          rows.unshift(Row.new(:unchanged, old_index, new_index, old_lines[old_index - 1]))
          old_index -= 1
          new_index -= 1
        elsif new_index.positive? && (old_index.zero? || table[old_index][new_index - 1] >= table[old_index - 1][new_index])
          rows.unshift(Row.new(:added, nil, new_index, new_lines[new_index - 1]))
          new_index -= 1
        else
          rows.unshift(Row.new(:removed, old_index, nil, old_lines[old_index - 1]))
          old_index -= 1
        end
      end

      rows
    end

    def lcs_table
      table = Array.new(old_lines.size + 1) { Array.new(new_lines.size + 1, 0) }

      old_lines.each_with_index do |old_line, old_index|
        new_lines.each_with_index do |new_line, new_index|
          table[old_index + 1][new_index + 1] =
            if old_line == new_line
              table[old_index][new_index] + 1
            else
              [table[old_index][new_index + 1], table[old_index + 1][new_index]].max
            end
        end
      end

      table
    end

    def collapse(rows)
      visible = visible_indexes(rows)
      return rows if visible.nil? || rows.size - visible.size <= 2

      collapsed = []
      skipped = 0

      rows.each_index do |index|
        if visible[index]
          collapsed << gap_row(skipped) if skipped.positive?
          skipped = 0
          collapsed << rows[index]
        else
          skipped += 1
        end
      end
      collapsed << gap_row(skipped) if skipped.positive?

      collapsed
    end

    def visible_indexes(rows)
      changed = rows.each_index.reject { |index| rows[index].unchanged? }
      return nil if changed.empty?

      visible = {}
      changed.each do |index|
        ((index - CONTEXT_LINES)..(index + CONTEXT_LINES)).each do |neighbour|
          visible[neighbour] = true if neighbour >= 0 && neighbour < rows.size
        end
      end
      visible
    end

    def gap_row(count)
      Row.new(:gap, nil, nil, "#{count} unchanged #{"line".pluralize(count)}")
    end
  end
end
