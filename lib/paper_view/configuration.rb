module PaperView
  class Configuration
    DEFAULT_TIME_FORMAT = "%Y-%m-%d %H:%M:%S".freeze

    attr_accessor :version_class_name, :parent_controller, :per_page, :whodunnit_label, :time_format, :turbo, :metadata_columns

    attr_reader :authentication_block, :authorization_block

    def initialize
      @version_class_name = "PaperTrail::Version"
      @parent_controller = "ActionController::Base"
      @per_page = 25
      @whodunnit_label = nil
      @time_format = DEFAULT_TIME_FORMAT
      @turbo = true
      @metadata_columns = nil
    end

    def authenticate_with(&block)
      @authentication_block = block
    end

    def authorize_with(&block)
      @authorization_block = block
    end
  end
end
