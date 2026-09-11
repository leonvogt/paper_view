module PaperView
  class VersionQuery
    EVENTS = %w[create update destroy].freeze

    attr_reader :item_type, :item_id, :event

    def self.item_types
      PaperView.version_class.distinct.order(:item_type).pluck(:item_type)
    end

    def initialize(params = {})
      @item_type = params[:item_type].presence
      @item_id = params[:item_id].presence
      @event = params[:event].presence_in(EVENTS)
    end

    def scoped?
      item_type.present?
    end

    def relation
      scope = PaperView.version_class.where(item_type: item_type)
      scope = scope.where(item_id: item_id) if item_id
      scope = scope.where(event: event) if event
      scope.order(created_at: :desc, id: :desc)
    end

    def label
      return nil unless scoped?
      item_id ? "#{item_type} ##{item_id}" : item_type
    end
  end
end
