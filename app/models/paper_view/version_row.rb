module PaperView
  class VersionRow
    MAX_LINES = 3

    attr_reader :version, :change_set, :burst_size

    def initialize(version, change_set: nil, burst_size: 1)
      @version = version
      @change_set = change_set || ChangeSet.for(version)
      @burst_size = burst_size
    end

    def id
      version.id
    end

    def event
      version.event
    end

    def date
      version.created_at&.to_date
    end

    def time
      version.created_at&.strftime("%H:%M")
    end

    def item_label
      "#{version.item_type} ##{version.item_id}"
    end

    def item_key
      [version.item_type, version.item_id]
    end

    def burst?
      burst_size > 1
    end

    def burst_label
      "#{burst_size} versions within 1s"
    end

    def destroyed?
      event == "destroy"
    end

    def lines
      leaves.first(MAX_LINES)
    end

    def footnotes
      notes = []
      notes << "payload not deserializable" if change_set.unreadable?
      notes << "+#{overflow_count} more #{"field".pluralize(overflow_count)}" if overflow_count.positive?
      notes << "no attribute changes recorded" if leaves.empty? && !change_set.unreadable?
      notes
    end

    def console_snippet
      <<~RUBY
        version = #{PaperView.config.version_class_name}.find(#{id})
        item    = version.reify          # state before this version
        current = version.item           # current record

        version.changeset                # { attr => [old, new] }
        item.attributes.slice(*version.changeset.keys)

        # item.save!                     # roll back to this state
      RUBY
    end

    private

    def leaves
      @leaves ||= destroyed? ? [LeafChange.new("record", item_label, nil)] : change_set.flat_map(&:leaves)
    end

    def overflow_count
      leaves.size - MAX_LINES
    end
  end
end
