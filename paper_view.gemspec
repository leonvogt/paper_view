require_relative "lib/paper_view/version"

Gem::Specification.new do |spec|
  spec.name = "paper_view"
  spec.version = PaperView::VERSION
  spec.authors = ["Leon Vogt"]
  spec.email = ["leon.vogt@hey.com"]
  spec.homepage = "https://github.com/leonvogt/paper_view"
  spec.summary = "A lightweight, mountable dashboard for paper_trail"
  spec.description = "PaperView is a mountable Rails engine that turns the paper_trail versions table into a searchable dashboard"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,lib}/**/*", "MIT-LICENSE", "README.md"]
  end

  spec.add_dependency "railties", ">= 6.0"
end
