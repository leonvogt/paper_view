module PaperView
  class VersionsController < ApplicationController
    before_action :set_version, only: %i[show revert]
    before_action :authorize_revert!, only: :revert

    def index
      @query = VersionQuery.new(params)
      @paginator = Paginator.new(@query.relation, page: params[:page], per_page: PaperView.config.per_page)
      @versions = @paginator.records
      @change_sets = @versions.index_with { |version| ChangeSet.for(version) }
      @item_types = VersionQuery.item_types
    end

    def show
      @change_set = ChangeSet.for(@version)
      @diff_mode = (params[:diff] == "inline") ? :inline : :split
      @previous_version = sibling_versions.where(id: ...@version.id).order(id: :desc).first
      @next_version = sibling_versions.where(id: (@version.id + 1)..).order(:id).first
    end

    def revert
      result = VersionReverter.new(@version).call

      if result.success?
        redirect_to version_path(@version), notice: result.message
      else
        redirect_to version_path(@version), alert: result.message
      end
    end

    private

    def set_version
      @version = PaperView.version_class.find(params[:id])
    end

    def sibling_versions
      PaperView.version_class.where(item_type: @version.item_type, item_id: @version.item_id)
    end

    def authorize_revert!
      block = PaperView.config.revert_authorization_block
      return if block.nil?

      head :forbidden unless instance_exec(&block)
    end
  end
end
