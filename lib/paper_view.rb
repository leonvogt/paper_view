require "active_support/parameter_filter"

require "paper_view/version"
require "paper_view/configuration"
require "paper_view/engine"

module PaperView
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

    def parameter_filter
      @parameter_filter ||= ActiveSupport::ParameterFilter.new(config.filter_attributes)
    end

    def filtered_attribute?(name)
      probe = "__paper_view_probe__"
      parameter_filter.filter(name.to_s => probe)[name.to_s] != probe
    end
  end
end
