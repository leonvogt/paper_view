module PaperView
  class StatsController < ApplicationController
    def show
      # First request shows skeletons.
      # Second request comes with load_content param
      return unless params[:load_content]

      @stats = TableStats.new
      render partial: "stats", locals: {stats: @stats}, layout: false if request.xhr?
    end
  end
end
