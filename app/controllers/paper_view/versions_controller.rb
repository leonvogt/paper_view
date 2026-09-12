module PaperView
  class VersionsController < ApplicationController
    def index
      @query = VersionQuery.new(params)
      @item_types = @query.item_types
      @whodunnits = @query.whodunnits
      return unless @query.submitted?

      @paginator = Paginator.new(@query.relation, page: params[:page], per_page: params[:per_page].presence || PaperView.config.per_page)
      @timeline = Timeline.new(@paginator.records, selected_id: params[:version])
    end
  end
end
