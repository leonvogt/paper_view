module PaperView
  # A line based diff for values that are too long to read as two blocks of text.
  class TextDiff
    CONTEXT = 3
    MIN_LINES = 4

    # Past a couple of hundred changed lines nobody reads a diff anymore, and the search
    # for the shortest one costs its square, so both sides become one replaced block.
    MAX_CHANGES = 200

    Line = Struct.new(:kind, :text, :old_number, :new_number) do
      def context?
        kind == :context
      end
    end

    Hunk = Struct.new(:lines) do
      def header
        "@@ -#{old_start},#{lines.count(&:old_number)} +#{new_start},#{lines.count(&:new_number)} @@"
      end

      private

      def old_start
        lines.detect(&:old_number)&.old_number || 0
      end

      def new_start
        lines.detect(&:new_number)&.new_number || 0
      end
    end

    def self.for(old_text, new_text)
      return unless old_text.is_a?(String) && new_text.is_a?(String)

      old_lines = old_text.lines.map(&:chomp)
      new_lines = new_text.lines.map(&:chomp)
      return if old_lines == new_lines || [old_lines.size, new_lines.size].max < MIN_LINES

      new(old_lines, new_lines)
    end

    def initialize(old_lines, new_lines)
      @old_lines = old_lines
      @new_lines = new_lines
    end

    def lines
      @lines ||= (trace = shortest_edit) ? retrace(trace) : replaced
    end

    def hunks
      @hunks ||= groups.map { |first, last| Hunk.new(lines[first..last]) }
    end

    def added_count
      lines.count { |line| line.kind == :added }
    end

    def removed_count
      lines.count { |line| line.kind == :deleted }
    end

    def unchanged_count
      lines.count(&:context?)
    end

    private

    attr_reader :old_lines, :new_lines

    # Myers' diff, one difference at a time. Every path is tracked by its diagonal
    # k = x - y, and ends[k] is how far into the old text the best path on that diagonal
    # reaches. Each step moves one line sideways and then rides the diagonal of matching
    # lines as far as it goes, so untouched stretches cost nothing.
    def shortest_edit
      ends = {1 => 0}
      trace = []

      (0..MAX_CHANGES).each do |differences|
        trace << ends.dup

        (-differences).step(differences, 2) do |k|
          x = added?(ends, k, differences) ? ends[k + 1] : ends[k - 1] + 1
          y = x - k

          while x < old_lines.size && y < new_lines.size && old_lines[x] == new_lines[y]
            x += 1
            y += 1
          end

          ends[k] = x
          return trace if x >= old_lines.size && y >= new_lines.size
        end
      end

      nil
    end

    # A path reaches diagonal k either by moving down from k + 1, which consumes a new
    # line, or by moving right from k - 1, which consumes an old one.
    def added?(ends, k, differences)
      k == -differences || (k != differences && ends[k - 1] < ends[k + 1])
    end

    # Retrace the winning path backwards: every diagonal stretch is context, every
    # sideways step is the one line that was added or deleted there.
    def retrace(trace)
      x = old_lines.size
      y = new_lines.size

      trace.each_with_index.reverse_each.flat_map { |ends, differences|
        k = x - y
        previous_k = added?(ends, k, differences) ? k + 1 : k - 1
        previous_x = ends[previous_k]
        previous_y = previous_x - previous_k
        steps = []

        while x > previous_x && y > previous_y
          x -= 1
          y -= 1
          steps << Line.new(:context, old_lines[x], x + 1, y + 1)
        end

        steps << step(previous_x, previous_y, added: x == previous_x) if differences > 0
        x = previous_x
        y = previous_y
        steps
      }.reverse
    end

    def step(old_index, new_index, added:)
      if added
        Line.new(:added, new_lines[new_index], nil, new_index + 1)
      else
        Line.new(:deleted, old_lines[old_index], old_index + 1, nil)
      end
    end

    def replaced
      old_lines.each_with_index.map { |text, index| Line.new(:deleted, text, index + 1, nil) } +
        new_lines.each_with_index.map { |text, index| Line.new(:added, text, nil, index + 1) }
    end

    # Changed lines closer than two context blocks share their surroundings and stay in one hunk.
    def groups
      lines.each_index.reject { |index| lines[index].context? }
        .slice_when { |before, after| after - before > CONTEXT * 2 }
        .map { |run| [[run.first - CONTEXT, 0].max, [run.last + CONTEXT, lines.size - 1].min] }
    end
  end
end
