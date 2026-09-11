require "paper_view/version"
require "paper_view/configuration"
require "paper_view/engine"

module PaperView
  EMPTY = "—".freeze

  class << self
    def config
      @config ||= Configuration.new
    end

    def setup
      yield config
      config
    end

    def version_class
      config.version_class_name.constantize
    end
  end
end
