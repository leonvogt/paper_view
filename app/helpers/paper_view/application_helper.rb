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

    def paper_view_bytes(bytes)
      return EMPTY if bytes.nil?

      number_to_human_size(bytes, precision: 3, significant: true, strip_insignificant_zeros: true)
    end

    def paper_view_percentage(share)
      number_to_percentage(share * 100, precision: 1, significant: false, strip_insignificant_zeros: false)
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

    def paper_view_nav_class(active)
      active ? "pv-header__link pv-header__link--active" : "pv-header__link"
    end

    def paper_view_turbo_script_tag
      return unless PaperView.config.turbo

      javascript_include_tag(turbo_asset_path(digest: PaperView::TurboAsset::DIGEST), type: "module", nonce: true)
    end

    # A Turbo visit from the host app would swap our markup and styles into its document.
    # Our own Turbo announces itself, so every other visit is sent through a full reload.
    def paper_view_full_reload_required?
      request.headers["X-PaperView-Turbo"].blank?
    end

    def paper_view_nonce_attribute
      nonce = content_security_policy_nonce
      return unless nonce

      raw(%( nonce="#{h(nonce)}"))
    end
  end
end
