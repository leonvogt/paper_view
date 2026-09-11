module PaperView
  class Configuration
    attr_accessor :version_class_name, :parent_controller, :per_page, :reify_options, :revert_enabled, :undo_create_enabled, :whodunnit_label
    attr_writer :filter_attributes
    attr_reader :authentication_block, :authorization_block, :revert_authorization_block

    def initialize
      @version_class_name = "PaperTrail::Version"
      @parent_controller = "ActionController::Base"
      @per_page = 25
      @reify_options = {}
      @revert_enabled = true
      @undo_create_enabled = false
      @whodunnit_label = nil
    end

    def filter_attributes
      @filter_attributes ||= Rails.application.config.filter_parameters
    end

    def authenticate_with(&block)
      @authentication_block = block
    end

    def authorize_with(&block)
      @authorization_block = block
    end

    def authorize_revert_with(&block)
      @revert_authorization_block = block
    end
  end
end
