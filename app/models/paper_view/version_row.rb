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

    def created?
      event == "create"
    end

    def destroyed?
      event == "destroy"
    end

    def snapshot?
      created? || destroyed?
    end

    def change_label
      noun = case event
      when "create" then "initial value"
      when "destroy" then "final value"
      else "changed field"
      end

      "#{change_set.size} #{noun.pluralize(change_set.size)}"
    end

    def lines
      snapshot? ? [] : leaves.first(MAX_LINES)
    end

    def footnotes
      notes = []
      notes << "payload not deserializable" if change_set.unreadable?
      return notes if snapshot?

      notes << "..." if overflow_count.positive?
      notes << "no attribute changes recorded" if leaves.empty? && !change_set.unreadable?
      notes
    end

    def console_snippet
      destroyed? ? restore_snippet : rollback_snippet
    end

    private

    def rollback_snippet
      <<~RUBY
        version = #{PaperView.config.version_class_name}.find(#{id})
        current = version.item           # current record

        version.changeset                # { attr => [old, new] }
        previous = version.changeset.transform_values(&:first)

        # current.update!(previous)      # roll back only these attributes
      RUBY
    end

    def restore_snippet
      <<~RUBY
        version = #{PaperView.config.version_class_name}.find(#{id})
        item    = version.reify          # the deleted record

        # item.save!                     # re-create the record; columns added since are nil
      RUBY
    end

    def leaves
      @leaves ||= change_set.flat_map(&:leaves)
    end

    def overflow_count
      leaves.size - MAX_LINES
    end
  end
end
