# frozen_string_literal: true

require_relative "lib/walmart_api/version"

Gem::Specification.new do |spec|
  spec.name = "walmart_api"
  spec.version = WalmartApi::VERSION
  spec.authors = ["sumitisrani032"]
  spec.email = ["sumitisrani032@gmail.com"]

  spec.summary = "Ruby SDK for Walmart Marketplace APIs"
  spec.description = "Production-grade Ruby client for Walmart Marketplace APIs including Orders, Inventory, and Items"
  spec.homepage = "https://github.com/sumitisrani032/walmart_api"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sumitisrani032/walmart_api"
  spec.metadata["changelog_uri"] = "https://github.com/sumitisrani032/walmart_api/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
end
