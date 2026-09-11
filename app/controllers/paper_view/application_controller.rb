module PaperView
  class ApplicationController < PaperView.config.parent_controller.constantize
    layout "paper_view/application"

    before_action :authenticate_paper_view!
    before_action :authorize_paper_view!

    private

    def authenticate_paper_view!
      block = PaperView.config.authentication_block
      instance_exec(&block) if block
    end

    def authorize_paper_view!
      block = PaperView.config.authorization_block
      return if block.nil?

      head :forbidden unless instance_exec(&block)
    end
  end
end
