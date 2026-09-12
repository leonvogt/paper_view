module PaperView
  class Timeline
    Group = Struct.new(:label, :rows)

    attr_reader :rows

    def initialize(versions, selected_id: nil)
      bursts = burst_sizes(versions)
      @rows = versions.map { |version| VersionRow.new(version, burst_size: bursts[version.id]) }
      @selected_id = selected_id
    end

    def empty?
      rows.empty?
    end

    def groups
      rows.chunk_while { |one, other| one.date == other.date }
        .map { |chunk| Group.new(day_label(chunk.first.date), chunk) }
    end

    def items
      @items ||= rows.map(&:item_key).uniq
    end

    def multi_item_view?
      items.size != 1
    end

    def title
      multi_item_view? ? "All changes" : rows.first.item_label
    end

    def selected
      @selected ||= rows.find { |row| row.id.to_s == @selected_id.to_s } || newest
    end

    private

    def newest
      rows.max_by { |row| [row.version.created_at || Time.at(0), row.id] }
    end

    def burst_sizes(versions)
      versions.group_by { |version| [version.whodunnit, version.created_at&.to_i] }
        .each_with_object({}) { |(_, group), sizes| group.each { |version| sizes[version.id] = group.size } }
    end

    def day_label(date)
      return "Unknown date" if date.nil?

      today = Date.current
      full = date.strftime("%-d %B %Y")

      case date
      when today then "Today · #{full}"
      when today - 1 then "Yesterday · #{full}"
      else full
      end
    end
  end
end
