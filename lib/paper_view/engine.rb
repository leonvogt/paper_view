module PaperView
  class Engine < ::Rails::Engine
    isolate_namespace PaperView

    config.generators do |generator|
      generator.test_framework :minitest, fixture: false
    end
  end
end
