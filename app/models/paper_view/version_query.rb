module PaperView
  class VersionQuery
    EVENTS = %w[create update destroy].freeze

    attr_reader :item_type, :item_id, :event, :whodunnit, :from, :to

    def self.item_types
      PaperView.version_class.distinct.order(:item_type).pluck(:item_type)
    end

    def initialize(params = {})
      @item_type = params[:item_type].presence
      @item_id = params[:item_id].presence
      @event = params[:event].presence_in(EVENTS)
      @whodunnit = params[:whodunnit].presence
      @from = parse_time(params[:from])
      @to = parse_time(params[:to])&.then { |time| time_given?(params[:to]) ? time : time.end_of_day }
    end

    def relation
      scope = PaperView.version_class.all
      scope = scope.where(item_type: item_type) if item_type
      scope = scope.where(item_id: item_id) if item_id
      scope = scope.where(event: event) if event
      scope = scope.where(whodunnit: whodunnit) if whodunnit
      scope = scope.where(created_at: from..) if from
      scope = scope.where(created_at: ..to) if to
      scope.order(created_at: :desc, id: :desc)
    end

    def filtered?
      [item_type, item_id, event, whodunnit, from, to].any?
    end

    private

    def time_given?(value)
      value.to_s.include?(":")
    end

    def parse_time(value)
      return nil if value.blank?
      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
