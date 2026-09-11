require "paper_view/version"
require "paper_view/configuration"
require "paper_view/engine"

module PaperView
  EMPTY = "—".freeze

  class Error < StandardError; end

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
    rescue NameError => error
      raise unless config.version_class_name.split("::").include?(error.name.to_s)
      raise Error, missing_version_class_message
    end

    private

    def missing_version_class_message
      <<~MESSAGE.squish
        PaperView could not find #{config.version_class_name}.
        Add `gem "paper_trail"` to your Gemfile, or point PaperView at your own
        versions model: `PaperView.setup { |config| config.version_class_name = "YourVersion" }`.
      MESSAGE
    end
  end
end
