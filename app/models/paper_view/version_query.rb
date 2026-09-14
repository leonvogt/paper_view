module PaperView
  class VersionQuery
    EVENTS = %w[create update destroy].freeze
    FILTER_KEYS = %i[item_type item_id event].freeze
    SORTS = %w[desc asc].freeze

    attr_reader :item_type, :item_id, :event, :sort

    def initialize(params = {})
      @submitted = FILTER_KEYS.any? { |key| params.key?(key) }
      @item_type = params[:item_type].presence
      @item_id = params[:item_id].presence
      @event = params[:event].presence_in(EVENTS)
      @sort = params[:sort].presence_in(SORTS) || SORTS.first
    end

    def submitted?
      @submitted
    end

    def item_types
      @item_types ||= versions_table.item_types
    end

    def relation
      filtered.order(created_at: sort.to_sym, id: sort.to_sym)
    end

    def matched_item_types
      return [item_type] if item_type
      return [] unless item_id

      @matched_item_types ||= filtered.unscope(:order).distinct.pluck(:item_type)
    end

    def single_item?
      item_id.present? && matched_item_types.size == 1
    end

    def title
      return "All changes" unless item_type || item_id
      return item_type unless item_id

      single_item? ? "#{matched_item_types.first} ##{item_id}" : "Item ##{item_id}"
    end

    private

    def versions_table
      @versions_table ||= VersionsTable.new
    end

    def filtered
      scope = PaperView.version_class.all
      scope = scope.where(item_type: searched_item_types) if searched_item_types
      scope = scope.where(item_id: item_id) if item_id
      scope = scope.where(event: event) if event
      scope
    end

    def searched_item_types
      return @searched_item_types if defined?(@searched_item_types)

      @searched_item_types = item_type || (item_types if item_id && versions_table.item_type_indexed?)
    end
  end
end
