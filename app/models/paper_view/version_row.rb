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
      visible_leaves.first(MAX_LINES)
    end

    def footnotes
      notes = []
      notes << "unreadable payload (serialized) hidden" if change_set.unreadable?
      notes << derived_note if derived_leaves.any?
      notes << overflow_note if overflow_count.positive?
      notes << "no attribute changes recorded" if visible_leaves.empty? && !change_set.unreadable?
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
      @leaves ||= change_set.flat_map(&:leaves)
    end

    def visible_leaves
      @visible_leaves ||= destroyed? ? destroyed_leaves : leaves - derived_leaves
    end

    def destroyed_leaves
      [LeafChange.new("record", item_label, nil)]
    end

    def nested_leaves
      @nested_leaves ||= leaves.select(&:nested?)
    end

    def derived_leaves
      @derived_leaves ||= leaves.reject(&:nested?).select do |leaf|
        nested_leaves.any? { |nested| nested.flat_path == leaf.path && nested.same_values?(leaf) }
      end
    end

    def derived_note
      "+ derived #{"field".pluralize(derived_leaves.size)} #{derived_leaves.map(&:path).join(", ")}"
    end

    def overflow_count
      visible_leaves.size - MAX_LINES
    end

    def overflow_note
      remaining = visible_leaves.drop(MAX_LINES)
      roots = remaining.select(&:nested?).map(&:root).uniq
      suffix = (roots.size == 1 && remaining.all?(&:nested?)) ? " in #{roots.first}" : ""
      "+#{overflow_count} more #{"field".pluralize(overflow_count)}#{suffix}"
    end
  end
end
