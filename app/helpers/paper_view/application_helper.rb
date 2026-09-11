module PaperView
  module ApplicationHelper
    EMPTY = "—".freeze

    def paper_view_whodunnit(version)
      label = PaperView.config.whodunnit_label
      value = label ? label.call(version.whodunnit) : version.whodunnit
      value.presence || EMPTY
    end

    def paper_view_time(time)
      return EMPTY if time.nil?

      tag.time(time.strftime(PaperView.config.time_format), datetime: time.iso8601, title: time.iso8601)
    end

    def paper_view_item_path(version)
      versions_path(item_type: version.item_type, item_id: version.item_id)
    end

    def paper_view_filter_params(overrides = {})
      request.query_parameters.except("page", "version").merge(overrides)
    end

    def paper_view_hidden_filters(except: [])
      excluded = Array(except).map(&:to_s)
      safe_join(paper_view_filter_params.except(*excluded).map { |name, value| hidden_field_tag(name, value, id: nil) })
    end

    def paper_view_nonce_attributes
      {nonce: content_security_policy_nonce}
    end
  end
end
