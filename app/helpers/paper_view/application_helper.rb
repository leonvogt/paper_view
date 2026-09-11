module PaperView
  module ApplicationHelper
    EMPTY = "—".freeze

    def paper_view_item_label(version)
      "#{version.item_type} ##{version.item_id}"
    end

    def paper_view_whodunnit(version)
      label = PaperView.config.whodunnit_label
      value = label ? label.call(version.whodunnit) : version.whodunnit
      value.presence || EMPTY
    end

    def paper_view_time(time)
      return EMPTY if time.nil?

      tag.time(time.strftime("%Y-%m-%d %H:%M:%S"), datetime: time.iso8601, title: time.iso8601)
    end

    def paper_view_relative_time(time)
      return EMPTY if time.nil?

      "#{time_ago_in_words(time)} ago"
    end

    def paper_view_revert_label(version)
      (version.event == "create") ? "Undo creation (destroys record)" : "Roll back to this state"
    end

    def paper_view_revert_confirm(version)
      if version.event == "create"
        "This destroys #{paper_view_item_label(version)} in your database. Continue?"
      else
        "This restores #{paper_view_item_label(version)} to the state before version ##{version.id}. Continue?"
      end
    end

    def paper_view_filter_params(overrides = {})
      request.query_parameters.except("page").merge(overrides)
    end

    def paper_view_diff_cell(row, sign: false)
      type = row ? row.type : :empty
      content =
        if row.nil?
          nil
        elsif sign
          safe_join([tag.span(paper_view_diff_sign(type), class: "pv-diff__sign pv-diff__sign--#{type}"), row.text])
        else
          row.text
        end

      tag.td(content, class: "pv-diff__code pv-diff__code--#{type}")
    end

    def paper_view_diff_sign(type)
      case type
      when :added then "+"
      when :removed then "-"
      else " "
      end
    end

    def paper_view_pretty_json(value)
      JSON.pretty_generate(value)
    rescue
      value.inspect
    end

    def paper_view_nonce_attributes
      {nonce: content_security_policy_nonce}
    end
  end
end
