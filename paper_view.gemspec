require_relative "lib/paper_view/version"

Gem::Specification.new do |spec|
  spec.name = "paper_view"
  spec.version = PaperView::VERSION
  spec.authors = ["Leon Vogt"]
  spec.email = ["leon.vogt@hey.com"]
  spec.homepage = "https://github.com/leonvogt/paper_view"
  spec.summary = "Lightweight dashboard to browse, diff and revert PaperTrail versions"
  spec.description = "PaperView is a mountable Rails engine that turns the paper_trail versions table into a searchable dashboard"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,lib}/**/*", "MIT-LICENSE", "README.md"]
  end

  spec.add_dependency "railties", ">= 7.0"
  spec.add_dependency "activerecord", ">= 7.0"
end
