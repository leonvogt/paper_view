require_relative "lib/paper_view/version"

Gem::Specification.new do |spec|
  spec.name        = "paper_view"
  spec.version     = PaperView::VERSION
  spec.authors     = [ "Leon" ]
  spec.email       = [ "lv@oxon.ch" ]
  spec.homepage    = "https://github.com/leonvogt/paper_view"
  spec.summary     = "Dashboard to interact with paper_trail versions table"
  spec.description = "Dashboard to interact with paper_trail versions table"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/leonvogt/paper_view"
  spec.metadata["changelog_uri"] = "https://github.com/leonvogt/paper_view"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.5.1"
end
